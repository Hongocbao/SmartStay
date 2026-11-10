using System.Text;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SmartStay.Web.Data;
using SmartStay.Web.Hubs;
using SmartStay.Web.Services;

AppContext.SetSwitch("Npgsql.EnableLegacyTimestampBehavior", true);

var builder = WebApplication.CreateBuilder(args);

// 1. Hỗ trợ đọc chuỗi kết nối từ biến môi trường Render (ConnectionStrings__DefaultConnection hoặc DATABASE_URL)
// và có Fallback an toàn cho môi trường Local để không bao giờ bị crash khi chạy thử.
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection");
if (string.IsNullOrWhiteSpace(connectionString))
{
    connectionString = Environment.GetEnvironmentVariable("DATABASE_URL")
        ?? Environment.GetEnvironmentVariable("SUPABASE_DB_URL")
        ?? "Server=(localdb)\\mssqllocaldb;Database=SmartStayDB;Trusted_Connection=True;MultipleActiveResultSets=true;TrustServerCertificate=True;";
}

builder.Services.AddDbContext<SmartStayDbContext>(options =>
{
    if (connectionString.Contains("supabase.com", StringComparison.OrdinalIgnoreCase)
        || connectionString.Contains("supabase.co", StringComparison.OrdinalIgnoreCase)
        || connectionString.Contains("Port=5432", StringComparison.OrdinalIgnoreCase)
        || connectionString.Contains("Port=6543", StringComparison.OrdinalIgnoreCase)
        || connectionString.Contains("Host=", StringComparison.OrdinalIgnoreCase)
        || connectionString.StartsWith("postgres://", StringComparison.OrdinalIgnoreCase)
        || connectionString.StartsWith("postgresql://", StringComparison.OrdinalIgnoreCase))
    {
        options.UseNpgsql(connectionString, npgsqlOptions =>
        {
            npgsqlOptions.EnableRetryOnFailure(3, TimeSpan.FromSeconds(5), null);
        });
    }
    else
    {
        options.UseSqlServer(connectionString);
    }
});

// 2. DI Services
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IInvoiceCalculationService, InvoiceCalculationService>();

// 3. Controllers, Views & SignalR
builder.Services.AddControllersWithViews();
builder.Services.AddSignalR();
builder.Services.AddEndpointsApiExplorer();

// 4. Cấu hình Swagger API Documentation (Thầy cô có thể test API trực tiếp tại /swagger)
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "SmartStay Unified Web & Mobile API",
        Version = "v1",
        Description = "Cổng dịch vụ API toàn diện cho Hệ sinh thái Lưu trú Thông minh SmartStay (Tích hợp Web Admin & Mobile App)"
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Nhập JWT Bearer token: Bearer {token}",
        Name = "Authorization",
        In = ParameterLocation.Header,
        Type = SecuritySchemeType.ApiKey,
        Scheme = "Bearer"
    });

    c.AddSecurityRequirement(new OpenApiSecurityRequirement
    {
        {
            new OpenApiSecurityScheme
            {
                Reference = new OpenApiReference
                {
                    Type = ReferenceType.SecurityScheme,
                    Id = "Bearer"
                }
            },
            Array.Empty<string>()
        }
    });
});

// 5. Cấu hình Đa Xác Thực: Cookie (cho Web Portal) và JWT (cho Mobile App)
var jwtKey = builder.Configuration["Jwt:Key"];
if (string.IsNullOrWhiteSpace(jwtKey) || Encoding.UTF8.GetByteCount(jwtKey) < 32)
{
    jwtKey = Environment.GetEnvironmentVariable("JWT_KEY")
        ?? "SmartStay_Enterprise_Default_Jwt_Signing_Key_2026_Secure!";
}
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "SmartStay";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "SmartStayClients";

builder.Services.AddAuthentication(options =>
    {
        options.DefaultScheme = "SmartStayAuth";
        options.DefaultChallengeScheme = "SmartStayAuth";
    })
    .AddPolicyScheme("SmartStayAuth", "Cookie or Bearer", options =>
    {
        options.ForwardDefaultSelector = context =>
            context.Request.Headers.Authorization.ToString().StartsWith("Bearer ", StringComparison.OrdinalIgnoreCase)
                ? JwtBearerDefaults.AuthenticationScheme
                : CookieAuthenticationDefaults.AuthenticationScheme;
    })
    .AddCookie(CookieAuthenticationDefaults.AuthenticationScheme, options =>
    {
        options.LoginPath = "/Account/Login";
        options.LogoutPath = "/Account/Logout";
        options.AccessDeniedPath = "/Account/AccessDenied";
        options.ExpireTimeSpan = TimeSpan.FromHours(8);
        options.SlidingExpiration = true;
    })
    .AddJwtBearer(JwtBearerDefaults.AuthenticationScheme, options =>
    {
        options.RequireHttpsMetadata = false;
        options.SaveToken = true;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
            ValidateIssuer = true,
            ValidIssuer = jwtIssuer,
            ValidateAudience = true,
            ValidAudience = jwtAudience,
            ClockSkew = TimeSpan.Zero
        };
    });

builder.Services.AddAuthorization(options =>
{
    options.AddPolicy("AdminOnly", policy => policy.RequireRole("Admin"));
    options.AddPolicy("TechOrAdmin", policy => policy.RequireRole("Admin", "KyThuat"));
});

// 6. CORS Policy: Cho phép link smartstay-client trên Render, localhost và Mobile App gọi API thông suốt
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        var allowedOrigins = builder.Configuration
            .GetSection("Cors:AllowedOrigins")
            .Get<string[]>() ?? Array.Empty<string>();

        policy.SetIsOriginAllowed(origin =>
              {
                  if (string.IsNullOrWhiteSpace(origin)) return true;
                  if (allowedOrigins.Contains(origin, StringComparer.OrdinalIgnoreCase)) return true;
                  if (Uri.TryCreate(origin, UriKind.Absolute, out var uri))
                  {
                      return uri.Host.Equals("localhost", StringComparison.OrdinalIgnoreCase)
                          || uri.Host.Equals("127.0.0.1", StringComparison.OrdinalIgnoreCase)
                          || uri.Host.EndsWith(".onrender.com", StringComparison.OrdinalIgnoreCase);
                  }
                  return false;
              })
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Tự động đồng bộ Schema PostgreSQL (Supabase) & bật RLS/Realtime cho Phương án A
using (var scope = app.Services.CreateScope())
{
    try
    {
        var db = scope.ServiceProvider.GetRequiredService<SmartStayDbContext>();
        if (db.Database.IsNpgsql())
        {
            bool needsSchemaSync = args.Contains("--init-db");
            if (!needsSchemaSync)
            {
                try
                {
                    _ = await db.NguoiDungs.AsNoTracking().Select(u => u.ThoiDiemTao).FirstOrDefaultAsync();
                }
                catch
                {
                    needsSchemaSync = true;
                }
            }

            if (needsSchemaSync)
            {
                var sqlPath = Path.GetFullPath(Path.Combine(app.Environment.ContentRootPath, "..", "database", "schema_postgresql_supabase.sql"));
                if (File.Exists(sqlPath))
                {
                    var sqlScript = await File.ReadAllTextAsync(sqlPath);
                    await db.Database.ExecuteSqlRawAsync(sqlScript);
                    Console.WriteLine("[SmartStay] Đã đồng bộ thành công Schema & Seed Data lên Supabase PostgreSQL!");
                }
            }

            // Áp dụng cấu hình Phương án A (Supabase Realtime + RLS) không phá hủy dữ liệu
            var optionAPath = Path.GetFullPath(Path.Combine(app.Environment.ContentRootPath, "..", "database", "supabase_rls_and_realtime_option_a.sql"));
            if (File.Exists(optionAPath))
            {
                var rlsScript = await File.ReadAllTextAsync(optionAPath);
                await db.Database.ExecuteSqlRawAsync(rlsScript);
            }
        }
    }
    catch (Exception ex)
    {
        Console.WriteLine($"[SmartStay] Khởi động ở chế độ Resilient (Bỏ qua đồng bộ DB tự động: {ex.Message})");
    }
}

if (args.Contains("--init-db"))
{
    return;
}

app.MapGet("/api/health", () => Results.Ok(new
{
    status = "ok",
    service = "smartstay-admin",
    supabaseUrl = builder.Configuration["Supabase:Url"] ?? Environment.GetEnvironmentVariable("SUPABASE_URL") ?? "https://odasdzyuriucofavonjl.supabase.co",
    timestamp = DateTime.UtcNow
}));

// Configure the HTTP request pipeline
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

// Kích hoạt Swagger UI tại /swagger
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "SmartStay Unified API v1");
    c.RoutePrefix = "swagger";
});

app.UseStaticFiles();

app.UseRouting();

// CORS phải chạy sau routing để xử lý đúng preflight OPTIONS từ Flutter Web (smartstay-client).
app.UseCors("AllowAll");

app.UseAuthentication();
app.UseAuthorization();

// SignalR Real-time Hub
app.MapHub<SmartStayHub>("/hub/smartstay");

// Map API Controllers (/api/auth, /api/phong, /api/tro-ly, /api/hoadon, /api/sync, ...)
app.MapControllers();

// Map MVC Routes (/Account/Login, /Home/Index, /Phong/SoDo, ...)
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Account}/{action=Login}/{id?}");

app.Run();
