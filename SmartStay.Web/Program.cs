using System.Text;
using Microsoft.AspNetCore.Authentication.Cookies;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SmartStay.Web.Data;
using SmartStay.Web.Hubs;
using SmartStay.Web.Services;

var builder = WebApplication.CreateBuilder(args);

// 1. Database Connection (Ưu tiên kết nối Supabase Cloud PostgreSQL, hỗ trợ fallback SQL Server)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") 
    ?? "Host=aws-1-eu-west-3.pooler.supabase.com;Port=5432;Database=postgres;Username=postgres.odasdzyuriucofavonjl;Password=ngocbao11a77;SSL Mode=Require;Trust Server Certificate=true";

builder.Services.AddDbContext<SmartStayDbContext>(options =>
{
    if (connectionString.Contains("supabase.com", StringComparison.OrdinalIgnoreCase)
        || connectionString.Contains("Port=5432", StringComparison.OrdinalIgnoreCase)
        || connectionString.Contains("Host=", StringComparison.OrdinalIgnoreCase))
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
var jwtKey = builder.Configuration["Jwt:Key"] ?? "SmartStay_Secret_Key_For_Jwt_Authentication_2026_Secure_Token!";
var jwtIssuer = builder.Configuration["Jwt:Issuer"] ?? "SmartStay";
var jwtAudience = builder.Configuration["Jwt:Audience"] ?? "SmartStayClients";

builder.Services.AddAuthentication(options =>
    {
        options.DefaultScheme = CookieAuthenticationDefaults.AuthenticationScheme;
        options.DefaultChallengeScheme = CookieAuthenticationDefaults.AuthenticationScheme;
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

// 6. CORS Policy: Cho phép Flutter Mobile App và Web Browser gọi API thông suốt
builder.Services.AddCors(options =>
{
    options.AddPolicy("AllowAll", policy =>
    {
        policy.AllowAnyOrigin()
              .AllowAnyMethod()
              .AllowAnyHeader();
    });
});

var app = builder.Build();

// Configure the HTTP request pipeline
if (!app.Environment.IsDevelopment())
{
    app.UseExceptionHandler("/Home/Error");
    app.UseHsts();
}

app.UseCors("AllowAll");

// Kích hoạt Swagger UI tại /swagger
app.UseSwagger();
app.UseSwaggerUI(c =>
{
    c.SwaggerEndpoint("/swagger/v1/swagger.json", "SmartStay Unified API v1");
    c.RoutePrefix = "swagger";
});

app.UseHttpsRedirection();
app.UseStaticFiles();

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

// SignalR Real-time Hub
app.MapHub<SmartStayHub>("/hub/smartstay");

// Map API Controllers (/api/auth, /api/phong, /api/tro-ly, /api/hoadon, ...)
app.MapControllers();

// Map MVC Routes (/Account/Login, /Home/Index, /Phong/SoDo, ...)
app.MapControllerRoute(
    name: "default",
    pattern: "{controller=Account}/{action=Login}/{id?}");

app.Run();
