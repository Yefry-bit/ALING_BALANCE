using AlingBalance.Api.Domain;
using AlingBalance.Api.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;

namespace AlingBalance.Api.Controllers;

/// <summary>Copias de seguridad de la base de datos (solo administradores).</summary>
[ApiController]
[Route("api/backups")]
[Authorize(Roles = Roles.Admin)]
public class BackupsController(DatabaseBackupService backups) : ApiControllerBase
{
    /// <summary>Estado de las copias y la lista de las guardadas.</summary>
    [HttpGet]
    public IActionResult GetAll()
    {
        return Ok(new
        {
            available = backups.Available,
            folder = backups.FolderPath,
            keep = backups.Keep,
            files = backups.Available
                ? backups.List().Select(ToDto)
                : Enumerable.Empty<object>(),
        });
    }

    /// <summary>Hace una copia ahora (por ejemplo, antes de actualizar el servidor).</summary>
    [HttpPost]
    public async Task<IActionResult> Create(CancellationToken cancellationToken)
    {
        if (!backups.Available)
        {
            return Fail(
                StatusCodes.Status409Conflict,
                "Las copias automáticas solo funcionan con SQLite (o están desactivadas en Backup:Enabled).");
        }

        try
        {
            var file = await backups.CreateAsync(cancellationToken);
            return Created($"/api/backups/{file.Name}", ToDto(file));
        }
        catch (IOException)
        {
            return Fail(
                StatusCodes.Status500InternalServerError,
                "No se pudo guardar la copia. Revisa que la carpeta exista y tenga espacio.");
        }
        catch (UnauthorizedAccessException)
        {
            return Fail(
                StatusCodes.Status500InternalServerError,
                "El servidor no tiene permiso para escribir en la carpeta de copias.");
        }
    }

    private static object ToDto(BackupFile file) => new
    {
        name = file.Name,
        sizeBytes = file.SizeBytes,
        createdAt = DateTime.SpecifyKind(file.CreatedAt.ToUniversalTime(), DateTimeKind.Utc),
    };
}
