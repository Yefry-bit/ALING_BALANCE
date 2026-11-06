using System.Security.Claims;
using System.Text;
using AlingBalance.Api.Domain;
using Microsoft.Extensions.Options;
using Microsoft.IdentityModel.JsonWebTokens;
using Microsoft.IdentityModel.Tokens;

namespace AlingBalance.Api.Security;

/// <summary>Crea los tokens JWT que la app usa después de iniciar sesión.</summary>
public sealed class TokenService(IOptions<JwtOptions> options)
{
    private readonly JwtOptions _options = options.Value;

    /// <summary>Claim que indica una sesión recordada (dura días).</summary>
    public const string RememberClaim = "remember";

    /// <summary>Claim con el <see cref="AppUser.SecurityStamp"/> vigente.</summary>
    public const string StampClaim = "stamp";

    /// <summary>Código nuevo para invalidar las sesiones anteriores.</summary>
    public static string NewStamp() => Guid.NewGuid().ToString("N");

    public (string Token, DateTime ExpiresAt) Create(AppUser user, bool remember = false)
    {
        var now = DateTime.UtcNow;
        var expiresAt = remember
            ? now.AddDays(_options.RememberDays)
            : now.AddMinutes(_options.ExpiryMinutes);
        var key = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(_options.Key));

        var descriptor = new SecurityTokenDescriptor
        {
            Subject = new ClaimsIdentity(new[]
            {
                new Claim("sub", user.Id.ToString()),
                new Claim("name", user.Name),
                new Claim("username", user.Username),
                new Claim("role", user.Role),
                new Claim(RememberClaim, remember ? "true" : "false"),
                new Claim(StampClaim, user.SecurityStamp ?? string.Empty),
            }),
            Issuer = _options.Issuer,
            Audience = _options.Audience,
            Expires = expiresAt,
            SigningCredentials = new SigningCredentials(key, SecurityAlgorithms.HmacSha256),
        };

        var token = new JsonWebTokenHandler().CreateToken(descriptor);
        return (token, expiresAt);
    }
}
