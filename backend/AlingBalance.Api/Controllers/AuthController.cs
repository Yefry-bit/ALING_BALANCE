using AlingBalance.Api.Data;
using AlingBalance.Api.Dtos;
using AlingBalance.Api.Security;
using AlingBalance.Api.Validation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;

namespace AlingBalance.Api.Controllers;

[ApiController]
[Route("api/auth")]
public class AuthController(AppDbContext db, PasswordService passwords, TokenService tokens)
    : ApiControllerBase
{
    /// <summary>Inicia sesión y devuelve un token JWT. Limitado por intentos.</summary>
    [HttpPost("login")]
    [AllowAnonymous]
    [EnableRateLimiting("login")]
    public async Task<IActionResult> Login(LoginRequest request)
    {
        var errors = new ErrorBag();
        var username = Rules.NormalizeUsername(request.Username);

        if (username.Length == 0) errors.Add("username", "Ingresa tu usuario.");
        if (string.IsNullOrEmpty(request.Password)) errors.Add("password", "Ingresa tu contraseña.");
        if (errors.HasErrors) return Invalid(errors);

        var user = await db.Users.FirstOrDefaultAsync(u => u.Username == username);

        // Mismo mensaje para usuario inexistente y contraseña errónea.
        if (user is null || !passwords.Verify(request.Password!, user.PasswordHash))
        {
            return Fail(StatusCodes.Status401Unauthorized, "Usuario o contraseña incorrectos.");
        }

        if (!user.Active)
        {
            return Fail(
                StatusCodes.Status403Forbidden,
                "Esta cuenta está desactivada. Consulta al administrador.");
        }

        var (token, expiresAt) = tokens.Create(user);
        return Ok(new LoginResponse(
            token,
            DateTime.SpecifyKind(expiresAt, DateTimeKind.Utc),
            UserDto.From(user)));
    }

    /// <summary>Datos del usuario con la sesión actual.</summary>
    [HttpGet("me")]
    [Authorize]
    public async Task<IActionResult> Me()
    {
        var user = await db.Users.AsNoTracking().FirstOrDefaultAsync(u => u.Id == User.GetUserId());
        return user is null
            ? Fail(StatusCodes.Status404NotFound, "No se encontró el usuario.")
            : Ok(UserDto.From(user));
    }
}
