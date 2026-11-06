using System.Security.Claims;

namespace AlingBalance.Api.Security;

/// <summary>Atajos para leer los datos del usuario autenticado.</summary>
public static class ClaimsExtensions
{
    public static int GetUserId(this ClaimsPrincipal user)
    {
        return int.TryParse(user.FindFirstValue("sub"), out var id) ? id : 0;
    }

    /// <summary>La sesión se inició con "Mantener la sesión iniciada".</summary>
    public static bool IsRememberedSession(this ClaimsPrincipal user)
    {
        return user.FindFirstValue(TokenService.RememberClaim) == "true";
    }

    public static string GetUserName(this ClaimsPrincipal user)
    {
        return user.FindFirstValue("name") ?? string.Empty;
    }
}
