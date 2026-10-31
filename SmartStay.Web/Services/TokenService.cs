using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using SmartStay.Web.Models;

namespace SmartStay.Web.Services;

public interface ITokenService
{
    string GenerateJwtToken(NguoiDung nguoiDung, string roleName);
}

public class TokenService : ITokenService
{
    private readonly IConfiguration _config;

    public TokenService(IConfiguration config)
    {
        _config = config;
    }

    public string GenerateJwtToken(NguoiDung nguoiDung, string roleName)
    {
        var secretKey = _config["Jwt:Key"] ?? "SmartStay_Secret_Key_For_Jwt_Authentication_2026_Secure_Token!";
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(secretKey));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var claims = new List<Claim>
        {
            new(ClaimTypes.NameIdentifier, nguoiDung.MaNguoiDung.ToString()),
            new(ClaimTypes.Name, nguoiDung.TenDangNhap),
            new(ClaimTypes.GivenName, nguoiDung.HoTen),
            new(ClaimTypes.Role, roleName)
        };

        var token = new JwtSecurityToken(
            issuer: _config["Jwt:Issuer"] ?? "SmartStay",
            audience: _config["Jwt:Audience"] ?? "SmartStayClients",
            claims: claims,
            expires: DateTime.UtcNow.AddDays(7),
            signingCredentials: creds
        );

        return new JwtSecurityTokenHandler().WriteToken(token);
    }
}
