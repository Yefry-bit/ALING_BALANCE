using System.Security.Claims;

namespace AlingBalance.Api.Security;

/// <summary>Atajos para leer los datos del usuario autenticado.</summary>
public static class ClaimsExtensions
{
    public static int GetUserId(this ClaimsPrincipal user)
    {
        return int.TryParse(user.FindFirstValue("sub"), out var id) ? id : 0;
    }

    public static string GetUserName(this ClaimsPrincipal user)
    {
        return user.FindFirstValue("name") ?? string.Empty;
    }
}
