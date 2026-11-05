using AlingBalance.Api.Catalog;
using AlingBalance.Api.Data;
using AlingBalance.Api.Domain;
using AlingBalance.Api.Dtos;
using AlingBalance.Api.Security;
using AlingBalance.Api.Validation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AlingBalance.Api.Controllers;

[ApiController]
[Route("api/services")]
[Authorize]
public class ServicesController(AppDbContext db) : ApiControllerBase
{
    /// <summary>Todos los servicios, del más reciente al más antiguo.</summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var services = await db.Services
            .AsNoTracking()
            .OrderByDescending(s => s.Operation)
            .ToListAsync();

        var photoCounts = await db.ServicePhotos
            .GroupBy(p => p.ServiceOperation)
            .Select(g => new { Operation = g.Key, Count = g.Count() })
            .ToDictionaryAsync(x => x.Operation, x => x.Count);

        return Ok(services.Select(s =>
            ServiceDto.From(s, photoCounts.GetValueOrDefault(s.Operation))));
    }

    /// <summary>
    /// Registra un servicio. Los empleados siempre usan el precio fijo del
    /// catálogo; solo el administrador puede indicar otro precio.
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Create(CreateServiceRequest request)
    {
        var errors = new ErrorBag();
        var isAdmin = User.IsInRole(Roles.Admin);

        var plate = Rules.NormalizePlate(request.Plate);
        var brand = Rules.NormalizeText(request.Brand);
        var model = Rules.NormalizeText(request.Model);
        var vehicleType = Rules.NormalizeText(request.VehicleType);
        var serviceType = Rules.NormalizeText(request.ServiceType);
        var status = string.IsNullOrWhiteSpace(request.Status)
            ? ServiceStatuses.InProgress
            : request.Status.Trim();

        errors.Add("plate", Rules.CheckPlate(plate));
        errors.Add("brand", Rules.CheckVehicleText(brand, "La marca"));
        errors.Add("model", Rules.CheckVehicleText(model, "El modelo"));

        if (!ServiceCatalog.IsValidVehicleType(vehicleType))
        {
            errors.Add("vehicleType", "Selecciona un tipo de vehículo válido.");
        }

        if (!ServiceCatalog.IsValidServiceType(serviceType))
        {
            errors.Add("serviceType", "Selecciona un servicio válido.");
        }

        if (!ServiceStatuses.All.Contains(status))
        {
            errors.Add("status", "El estado debe ser «En proceso» o «Terminado».");
        }

        var price = 0;
        if (!errors.Has("vehicleType")
            && !errors.Has("serviceType")
            && ServiceCatalog.TryGetPrice(serviceType, vehicleType, out var catalogPrice))
        {
            // Precio fijo para empleados; el administrador puede cambiarlo.
            price = isAdmin ? request.Price ?? catalogPrice : catalogPrice;
            errors.Add("price", Rules.CheckPrice(price));
        }

        Employee? employee = null;
        if (request.EmployeeId is int employeeId)
        {
            employee = await db.Employees.FindAsync(employeeId);

            if (employee is null)
            {
                errors.Add("employeeId", "El empleado seleccionado no existe.");
            }
            else if (!employee.Active)
            {
                errors.Add("employeeId", "El empleado seleccionado está inactivo.");
            }
        }
        else if (await db.Employees.AnyAsync(e => e.Active))
        {
            errors.Add("employeeId", "Selecciona el empleado que realiza el servicio.");
        }

        if (errors.HasErrors) return Invalid(errors);

        if (status == ServiceStatuses.InProgress
            && await HasInProgressDuplicate(plate, serviceType, exceptOperation: null))
        {
            return Fail(
                StatusCodes.Status409Conflict,
                $"Ya hay un servicio «{serviceType}» en proceso para la placa {plate}.");
        }

        var service = new ServiceRecord
        {
            Plate = plate,
            Vehicle = $"{brand} {model}",
            VehicleType = vehicleType,
            ServiceType = serviceType,
            Status = status,
            Price = price,
            Date = DateTime.UtcNow,
            FinishedAt = status == ServiceStatuses.Finished ? DateTime.UtcNow : null,
            RegisteredBy = User.GetUserName(),
            EmployeeId = employee?.Id,
            EmployeeName = employee?.Name ?? string.Empty,
        };

        db.Services.Add(service);
        await db.SaveChangesAsync();

        return Created($"/api/services/{service.Operation}", ServiceDto.From(service));
    }

    /// <summary>Cambia el estado (finalizar o reabrir un servicio).</summary>
    [HttpPatch("{operation:int}/status")]
    public async Task<IActionResult> UpdateStatus(int operation, UpdateStatusRequest request)
    {
        var status = (request.Status ?? string.Empty).Trim();

        if (!ServiceStatuses.All.Contains(status))
        {
            var errors = new ErrorBag();
            errors.Add("status", "El estado debe ser «En proceso» o «Terminado».");
            return Invalid(errors);
        }

        var service = await db.Services.FindAsync(operation);
        if (service is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el servicio.");
        }

        if (service.Status == status)
        {
            return Ok(ServiceDto.From(service));
        }

        if (status == ServiceStatuses.InProgress
            && await HasInProgressDuplicate(service.Plate, service.ServiceType, operation))
        {
            return Fail(
                StatusCodes.Status409Conflict,
                $"No se puede reabrir: ya hay un servicio «{service.ServiceType}» en proceso " +
                $"para la placa {service.Plate}.");
        }

        service.Status = status;
        service.FinishedAt = status == ServiceStatuses.Finished ? DateTime.UtcNow : null;
        await db.SaveChangesAsync();

        var photos = await db.ServicePhotos.CountAsync(p => p.ServiceOperation == operation);
        return Ok(ServiceDto.From(service, photos));
    }

    private Task<bool> HasInProgressDuplicate(string plate, string serviceType, int? exceptOperation)
    {
        return db.Services.AnyAsync(s =>
            s.Plate == plate
            && s.ServiceType == serviceType
            && s.Status == ServiceStatuses.InProgress
            && (exceptOperation == null || s.Operation != exceptOperation));
    }
}
