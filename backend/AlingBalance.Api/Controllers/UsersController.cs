using AlingBalance.Api.Data;
using AlingBalance.Api.Domain;
using AlingBalance.Api.Dtos;
using AlingBalance.Api.Security;
using AlingBalance.Api.Validation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AlingBalance.Api.Controllers;

/// <summary>Gestión de cuentas de usuario (solo administradores).</summary>
[ApiController]
[Route("api/users")]
[Authorize(Roles = Roles.Admin)]
public class UsersController(AppDbContext db, PasswordService passwords) : ApiControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var users = await db.Users.AsNoTracking().OrderBy(u => u.Name).ToListAsync();
        return Ok(users.Select(UserDto.From));
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateUserRequest request)
    {
        var errors = new ErrorBag();

        var name = Rules.NormalizeText(request.Name);
        var username = Rules.NormalizeUsername(request.Username);
        var role = (request.Role ?? string.Empty).Trim().ToLowerInvariant();

        errors.Add("name", Rules.CheckName(name));
        errors.Add("username", Rules.CheckUsername(username));
        errors.Add("password", Rules.CheckPassword(request.Password));

        if (!Roles.All.Contains(role))
        {
            errors.Add("role", "El rol debe ser administrador o empleado.");
        }

        if (errors.HasErrors) return Invalid(errors);

        if (await db.Users.AnyAsync(u => u.Username == username))
        {
            return Fail(StatusCodes.Status409Conflict, "Ese nombre de usuario ya está en uso.");
        }

        var user = new AppUser
        {
            Name = name,
            Username = username,
            PasswordHash = passwords.Hash(request.Password!),
            Role = role,
            Active = true,
            CreatedAt = DateTime.UtcNow,
        };

        db.Users.Add(user);

        try
        {
            await db.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            // Dos peticiones simultáneas con el mismo usuario: gana la primera.
            return Fail(StatusCodes.Status409Conflict, "Ese nombre de usuario ya está en uso.");
        }

        return Created($"/api/users/{user.Id}", UserDto.From(user));
    }

    /// <summary>Edita el nombre y el rol de una cuenta.</summary>
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, UpdateUserRequest request)
    {
        var errors = new ErrorBag();
        var name = Rules.NormalizeText(request.Name);
        var role = (request.Role ?? string.Empty).Trim().ToLowerInvariant();

        errors.Add("name", Rules.CheckName(name));
        if (!Roles.All.Contains(role))
        {
            errors.Add("role", "El rol debe ser administrador o empleado.");
        }

        if (errors.HasErrors) return Invalid(errors);

        var user = await db.Users.FindAsync(id);
        if (user is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el usuario.");
        }

        if (user.Role != role)
        {
            if (user.Id == User.GetUserId())
            {
                return Fail(
                    StatusCodes.Status400BadRequest,
                    "No puedes cambiar tu propio rol. Pídeselo a otro administrador.");
            }

            if (user.Role == Roles.Admin && user.Active
                && await db.Users.CountAsync(u => u.Active && u.Role == Roles.Admin) <= 1)
            {
                return Fail(
                    StatusCodes.Status409Conflict,
                    "Debe quedar al menos un administrador activo.");
            }

            user.Role = role;

            // Sus sesiones abiertas se cierran para que tome los permisos nuevos.
            user.SecurityStamp = TokenService.NewStamp();
        }

        user.Name = name;
        await db.SaveChangesAsync();

        return Ok(UserDto.From(user));
    }

    /// <summary>
    /// Asigna una contraseña nueva a otra cuenta (por ejemplo, si el empleado
    /// la olvidó). Sus sesiones abiertas se cierran.
    /// </summary>
    [HttpPatch("{id:int}/password")]
    public async Task<IActionResult> ResetPassword(int id, ResetPasswordRequest request)
    {
        var errors = new ErrorBag();
        errors.Add("password", Rules.CheckPassword(request.Password));
        if (errors.HasErrors) return Invalid(errors);

        if (id == User.GetUserId())
        {
            return Fail(
                StatusCodes.Status400BadRequest,
                "Para tu propia cuenta usa «Cambiar contraseña».");
        }

        var user = await db.Users.FindAsync(id);
        if (user is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el usuario.");
        }

        user.PasswordHash = passwords.Hash(request.Password!);
        user.SecurityStamp = TokenService.NewStamp();
        await db.SaveChangesAsync();

        return NoContent();
    }

    [HttpPatch("{id:int}/active")]
    public async Task<IActionResult> SetActive(int id, SetActiveRequest request)
    {
        if (request.Active is null)
        {
            var errors = new ErrorBag();
            errors.Add("active", "Indica si la cuenta debe quedar activa o inactiva.");
            return Invalid(errors);
        }

        var active = request.Active.Value;
        var user = await db.Users.FindAsync(id);

        if (user is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el usuario.");
        }

        if (!active && user.Id == User.GetUserId())
        {
            return Fail(StatusCodes.Status400BadRequest, "No puedes desactivar tu propia cuenta.");
        }

        if (!active && user.Active && user.Role == Roles.Admin)
        {
            var activeAdmins = await db.Users.CountAsync(u => u.Active && u.Role == Roles.Admin);
            if (activeAdmins <= 1)
            {
                return Fail(
                    StatusCodes.Status409Conflict,
                    "Debe quedar al menos un administrador activo.");
            }
        }

        user.Active = active;
        await db.SaveChangesAsync();

        return Ok(UserDto.From(user));
    }
}
