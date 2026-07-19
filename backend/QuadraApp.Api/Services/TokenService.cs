using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.IdentityModel.Tokens;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.Services;

public class JwtOptions
{
    public string Key { get; set; } = string.Empty;
    public string Issuer { get; set; } = string.Empty;
    public string Audience { get; set; } = string.Empty;
    public int ExpiraMinutos { get; set; } = 480;
}

public class TokenService
{
    private readonly JwtOptions _options;

    public TokenService(Microsoft.Extensions.Options.IOptions<JwtOptions> options)
        => _options = options.Value;

    public (string token, DateTime expiraEm) GerarToken(ApplicationUser usuario, IEnumerable<string> papeis)
    {
        var expiraEm = DateTime.UtcNow.AddMinutes(_options.ExpiraMinutos);

        var claims = new List<Claim>
        {
            new(JwtRegisteredClaimNames.Sub, usuario.Id.ToString()),
            new(JwtRegisteredClaimNames.Email, usuario.Email ?? string.Empty),
            new(ClaimTypes.NameIdentifier, usuario.Id.ToString()),
            new("nome", usuario.NomeCompleto),
            // Usado na validação server-side (revogação por troca de senha/reset).
            new("sstamp", usuario.SecurityStamp ?? string.Empty),
        };
        claims.AddRange(papeis.Select(p => new Claim(ClaimTypes.Role, p)));

        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.Key));
        var creds = new SigningCredentials(key, SecurityAlgorithms.HmacSha256);

        var token = new JwtSecurityToken(
            issuer: _options.Issuer,
            audience: _options.Audience,
            claims: claims,
            expires: expiraEm,
            signingCredentials: creds);

        return (new JwtSecurityTokenHandler().WriteToken(token), expiraEm);
    }
}
