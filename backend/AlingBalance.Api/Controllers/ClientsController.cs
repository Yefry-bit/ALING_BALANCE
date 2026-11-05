using AlingBalance.Api.Catalog;
using AlingBalance.Api.Data;
using AlingBalance.Api.Domain;
using AlingBalance.Api.Dtos;
using AlingBalance.Api.Validation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AlingBalance.Api.Controllers;

/// <summary>
/// Clientes y sus vehículos. Cualquier usuario puede registrarlos (quien
/// recibe el carro en el taller); solo el administrador puede eliminarlos.
/// </summary>
[ApiController]
[Route("api/clients")]
[Authorize]
public class ClientsController(AppDbContext db) : ApiControllerBase
{
    private const string DuplicateDocument = "Ya existe un cliente con esa identificación.";

    /// <summary>Todos los clientes con sus vehículos, por nombre.</summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var clients = await db.Clients
            .AsNoTracking()
            .Include(c => c.Vehicles)
            .OrderBy(c => c.Name)
            .ToListAsync();

        return Ok(clients.Select(ClientDto.From));
    }

    [HttpPost]
    public async Task<IActionResult> Create(ClientRequest request)
    {
        var (name, document, phone, errors) = Validate(request);
        if (errors.HasErrors) return Invalid(errors);

        if (await db.Clients.AnyAsync(c => c.Document == document))
        {
            return Fail(StatusCodes.Status409Conflict, DuplicateDocument);
        }

        var client = new Client
        {
            Name = name,
            Document = document,
            Phone = phone,
            CreatedAt = DateTime.UtcNow,
        };

        db.Clients.Add(client);

        try
        {
            await db.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return Fail(StatusCodes.Status409Conflict, DuplicateDocument);
        }

        return Created($"/api/clients/{client.Id}", ClientDto.From(client));
    }

    /// <summary>Edita nombre, identificación y teléfono.</summary>
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, ClientRequest request)
    {
        var (name, document, phone, errors) = Validate(request);
        if (errors.HasErrors) return Invalid(errors);

        var client = await db.Clients.Include(c => c.Vehicles).FirstOrDefaultAsync(c => c.Id == id);
        if (client is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el cliente.");
        }

        if (await db.Clients.AnyAsync(c => c.Document == document && c.Id != id))
        {
            return Fail(StatusCodes.Status409Conflict, DuplicateDocument);
        }

        client.Name = name;
        client.Document = document;
        client.Phone = phone;

        try
        {
            await db.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return Fail(StatusCodes.Status409Conflict, DuplicateDocument);
        }

        return Ok(ClientDto.From(client));
    }

    /// <summary>
    /// Elimina el cliente y sus vehículos. Los servicios ya realizados se
    /// conservan en el historial y en la contabilidad.
    /// </summary>
    [HttpDelete("{id:int}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> Delete(int id)
    {
        var client = await db.Clients.FindAsync(id);
        if (client is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el cliente.");
        }

        db.Clients.Remove(client);
        await db.SaveChangesAsync();

        return NoContent();
    }

    // ---------------------------------------------------------- Vehículos

    [HttpPost("{id:int}/vehicles")]
    public async Task<IActionResult> AddVehicle(int id, CreateVehicleRequest request)
    {
        var errors = new ErrorBag();

        var plate = Rules.NormalizePlate(request.Plate);
        var brand = Rules.NormalizeText(request.Brand);
        var model = Rules.NormalizeText(request.Model);
        var vehicleType = Rules.NormalizeText(request.VehicleType);

        errors.Add("plate", Rules.CheckPlate(plate));
        errors.Add("brand", Rules.CheckVehicleText(brand, "La marca"));
        errors.Add("model", Rules.CheckVehicleText(model, "El modelo"));

        if (!ServiceCatalog.IsValidVehicleType(vehicleType))
        {
            errors.Add("vehicleType", "Selecciona un tipo de vehículo válido.");
        }

        if (errors.HasErrors) return Invalid(errors);

        var client = await db.Clients.Include(c => c.Vehicles).FirstOrDefaultAsync(c => c.Id == id);
        if (client is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el cliente.");
        }

        var owner = await db.Vehicles
            .AsNoTracking()
            .Where(v => v.Plate == plate)
            .Select(v => v.Client!.Name)
            .FirstOrDefaultAsync();

        if (owner is not null)
        {
            return Fail(
                StatusCodes.Status409Conflict,
                $"La placa {plate} ya está registrada a nombre de {owner}.");
        }

        var vehicle = new Vehicle
        {
            ClientId = client.Id,
            Plate = plate,
            Brand = brand,
            Model = model,
            VehicleType = vehicleType,
            CreatedAt = DateTime.UtcNow,
        };

        client.Vehicles.Add(vehicle);

        try
        {
            await db.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return Fail(StatusCodes.Status409Conflict, $"La placa {plate} ya está registrada.");
        }

        return Created($"/api/clients/{client.Id}", ClientDto.From(client));
    }

    /// <summary>Quita un vehículo del cliente (sus servicios se conservan).</summary>
    [HttpDelete("{id:int}/vehicles/{vehicleId:int}")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> RemoveVehicle(int id, int vehicleId)
    {
        var client = await db.Clients.Include(c => c.Vehicles).FirstOrDefaultAsync(c => c.Id == id);
        var vehicle = client?.Vehicles.FirstOrDefault(v => v.Id == vehicleId);

        if (client is null || vehicle is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el vehículo.");
        }

        client.Vehicles.Remove(vehicle);
        db.Vehicles.Remove(vehicle);
        await db.SaveChangesAsync();

        return Ok(ClientDto.From(client));
    }

    // ------------------------------------------------------------- Interno

    private static (string Name, string Document, string Phone, ErrorBag Errors) Validate(
        ClientRequest request)
    {
        var errors = new ErrorBag();

        var name = Rules.NormalizeText(request.Name);
        var document = (request.Document ?? string.Empty).Trim();
        var phone = Rules.NormalizePhone(request.Phone);

        errors.Add("name", Rules.CheckName(name));
        errors.Add("document", Rules.CheckDocument(document));
        errors.Add("phone", Rules.CheckPhone(phone));

        return (name, document, phone, errors);
    }
}
