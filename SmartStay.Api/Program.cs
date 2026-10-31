using System.Text;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using SmartStay.Api.Data;
using SmartStay.Api.Hubs;
using SmartStay.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// 1. Cấu hình DbContext (Hỗ trợ MySQL hoặc SQL Server từ connection string)
var connectionString = builder.Configuration.GetConnectionString("DefaultConnection") 
    ?? "Server=localhost;Port=3306;Database=SmartStayDB;User=root;Password=;";

var dbProvider = builder.Configuration["DatabaseProvider"] ?? "MySQL"; // "MySQL" hoặc "SqlServer"

builder.Services.AddDbContext<SmartStayDbContext>(options =>
{
    if (dbProvider.Equals("SqlServer", StringComparison.OrdinalIgnoreCase))
    {
        options.UseSqlServer(connectionString);
    }
    else
    {
        // Mặc định dùng MySQL (Pomelo)
        var serverVersion = new MySqlServerVersion(new Version(8, 0, 36));
        options.UseMySql(connectionString, serverVersion, mySqlOptions =>
        {
            mySqlOptions.EnableRetryOnFailure(3, TimeSpan.FromSeconds(5), null);
        });
    }
});

// 2. Cấu hình DI Services
builder.Services.AddScoped<ITokenService, TokenService>();
builder.Services.AddScoped<IInvoiceCalculationService, InvoiceCalculationService>();

// 3. Cấu hình Controllers & JSON
builder.Services.AddControllers();
builder.Services.AddSignalR();
builder.Services.AddEndpointsApiExplorer();

// 4. Cấu hình Swagger với JWT Bearer
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo
    {
        Title = "SmartStay API - Core Backend",
        Version = "v1",
        Description = "Hệ thống quản trị hệ sinh thái lưu trú thông minh đa nền tảng (.NET 8)"
    });

    c.AddSecurityDefinition("Bearer", new OpenApiSecurityScheme
    {
        Description = "Nhập JWT Token theo định dạng: Bearer {token}",
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

// 5. Cấu hình CORS cho Mobile App và Web Admin
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

// Configure the HTTP request pipeline.
if (app.Environment.IsDevelopment() || true)
{
    app.UseSwagger();
    app.UseSwaggerUI(c =>
    {
        c.SwaggerEndpoint("/swagger/v1/swagger.json", "SmartStay API v1");
        c.RoutePrefix = string.Empty; // Mở Swagger trực tiếp tại root URL http://localhost:5000/
    });
}

app.UseCors("AllowAll");

app.UseRouting();

app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapHub<SmartStayHub>("/hubs/smartstay");

app.Run();
