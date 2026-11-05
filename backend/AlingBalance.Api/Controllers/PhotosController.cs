using AlingBalance.Api.Data;
using AlingBalance.Api.Domain;
using AlingBalance.Api.Dtos;
using AlingBalance.Api.Security;
using AlingBalance.Api.Validation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AlingBalance.Api.Controllers;

/// <summary>
/// Fotos de evidencia de los servicios (carro, máquinas, fallas o piezas
/// faltantes). Cualquier usuario puede subirlas y verlas; solo quien la tomó
/// o un administrador puede eliminarlas.
/// </summary>
[ApiController]
[Authorize]
public class PhotosController(AppDbContext db) : ApiControllerBase
{
    /// <summary>Datos de las fotos de un servicio (sin la imagen).</summary>
    [HttpGet("api/services/{operation:int}/photos")]
    public async Task<IActionResult> GetForService(int operation)
    {
        if (!await db.Services.AnyAsync(s => s.Operation == operation))
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el servicio.");
        }

        var photos = await db.ServicePhotos
            .AsNoTracking()
            .Where(p => p.ServiceOperation == operation)
            .OrderBy(p => p.Id)
            .Select(p => new PhotoDto(
                p.Id, p.ServiceOperation, p.Kind, p.Note, p.TakenById, p.TakenBy,
                DateTime.SpecifyKind(p.CreatedAt, DateTimeKind.Utc)))
            .ToListAsync();

        return Ok(photos);
    }

    /// <summary>Sube una foto (multipart/form-data: file, kind, note).</summary>
    [HttpPost("api/services/{operation:int}/photos")]
    [Consumes("multipart/form-data")]
    [RequestSizeLimit(Rules.MaxPhotoBytes + 64 * 1024)]
    public async Task<IActionResult> Upload(int operation, [FromForm] UploadPhotoRequest request)
    {
        var errors = new ErrorBag();
        // NFC: "ñ" o "í" pueden llegar como letra + tilde separada.
        var kind = Rules.NormalizeText(request.Kind).Normalize();
        var note = Rules.NormalizeText(request.Note).Normalize();

        if (!PhotoKinds.All.Contains(kind))
        {
            errors.Add("kind", "Selecciona qué muestra la foto.");
        }

        errors.Add("note", Rules.CheckPhotoNote(note));

        var file = request.File;
        if (file is null || file.Length == 0)
        {
            errors.Add("file", "Adjunta una foto.");
        }
        else if (file.Length > Rules.MaxPhotoBytes)
        {
            errors.Add("file", "La foto no puede superar los 5 MB.");
        }

        if (errors.HasErrors) return Invalid(errors);

        if (!await db.Services.AnyAsync(s => s.Operation == operation))
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el servicio.");
        }

        var count = await db.ServicePhotos.CountAsync(p => p.ServiceOperation == operation);
        if (count >= Rules.MaxPhotosPerService)
        {
            return Fail(
                StatusCodes.Status409Conflict,
                $"Un servicio puede tener máximo {Rules.MaxPhotosPerService} fotos.");
        }

        using var buffer = new MemoryStream();
        await file!.CopyToAsync(buffer);
        var data = buffer.ToArray();

        var contentType = Rules.DetectImageType(data);
        if (contentType is null)
        {
            errors.Add("file", "El archivo no es una imagen válida (JPG, PNG o WebP).");
            return Invalid(errors);
        }

        var photo = new ServicePhoto
        {
            ServiceOperation = operation,
            Kind = kind,
            Note = note,
            ContentType = contentType,
            Data = data,
            TakenById = User.GetUserId(),
            TakenBy = User.GetUserName(),
            CreatedAt = DateTime.UtcNow,
        };

        db.ServicePhotos.Add(photo);
        await db.SaveChangesAsync();

        return Created($"/api/photos/{photo.Id}", PhotoDto.From(photo));
    }

    /// <summary>La imagen en sí.</summary>
    [HttpGet("api/photos/{id:int}")]
    public async Task<IActionResult> GetImage(int id)
    {
        var photo = await db.ServicePhotos
            .AsNoTracking()
            .Where(p => p.Id == id)
            .Select(p => new { p.Data, p.ContentType })
            .FirstOrDefaultAsync();

        if (photo is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró la foto.");
        }

        // Las fotos no cambian: el dispositivo puede guardarlas en caché.
        Response.Headers.CacheControl = "private, max-age=86400";
        return File(photo.Data, photo.ContentType);
    }

    [HttpDelete("api/photos/{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var photo = await db.ServicePhotos.FindAsync(id);
        if (photo is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró la foto.");
        }

        if (!User.IsInRole(Roles.Admin) && photo.TakenById != User.GetUserId())
        {
            return Fail(
                StatusCodes.Status403Forbidden,
                "Solo quien tomó la foto o un administrador puede eliminarla.");
        }

        db.ServicePhotos.Remove(photo);
        await db.SaveChangesAsync();

        return NoContent();
    }
}
