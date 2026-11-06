using AlingBalance.Api.Data;
using AlingBalance.Api.Domain;
using AlingBalance.Api.Dtos;
using AlingBalance.Api.Security;
using AlingBalance.Api.Validation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AlingBalance.Api.Controllers;

/// <summary>Pagos de comisiones a los empleados (solo administradores).</summary>
[ApiController]
[Route("api/commissions/payments")]
[Authorize(Roles = Roles.Admin)]
public class CommissionsController(AppDbContext db) : ApiControllerBase
{
    /// <summary>Todos los pagos, del más reciente al más antiguo.</summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var payments = await db.CommissionPayments
            .AsNoTracking()
            .OrderByDescending(p => p.PaidAt)
            .ThenByDescending(p => p.Id)
            .ToListAsync();

        return Ok(payments.Select(CommissionPaymentDto.From));
    }

    /// <summary>
    /// Marca como pagada la comisión de los servicios indicados. Todos deben
    /// ser del empleado, estar terminados y no haberse pagado antes; el valor
    /// lo calcula el servidor.
    /// </summary>
    [HttpPost]
    public async Task<IActionResult> Pay(PayCommissionsRequest request)
    {
        var errors = new ErrorBag();
        var operations = (request.Operations ?? Array.Empty<int>()).Distinct().ToList();

        if (request.EmployeeId is null) errors.Add("employeeId", "Indica el empleado.");
        if (request.Year is null or < 2000 or > 2100) errors.Add("year", "El año no es válido.");
        if (request.Month is null or < 1 or > 12) errors.Add("month", "El mes no es válido.");
        if (operations.Count == 0) errors.Add("operations", "No hay servicios para pagar.");
        if (operations.Count > 1000) errors.Add("operations", "Demasiados servicios en un solo pago.");

        if (errors.HasErrors) return Invalid(errors);

        var employee = await db.Employees.FindAsync(request.EmployeeId!.Value);
        if (employee is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el empleado.");
        }

        var services = await db.Services
            .Where(s => operations.Contains(s.Operation))
            .ToListAsync();

        var valid = services.Count == operations.Count
            && services.All(s =>
                s.EmployeeId == employee.Id
                && s.Status == ServiceStatuses.Finished
                && s.CommissionPaymentId is null);

        if (!valid)
        {
            return Fail(
                StatusCodes.Status409Conflict,
                "Algunos servicios cambiaron (ya se pagaron, se reabrieron o cambiaron de " +
                "empleado). Actualiza la información e inténtalo de nuevo.");
        }

        var payment = new CommissionPayment
        {
            EmployeeId = employee.Id,
            EmployeeName = employee.Name,
            Year = request.Year!.Value,
            Month = request.Month!.Value,
            Amount = services.Sum(s => Commission.For(s.Price)),
            ServiceCount = services.Count,
            PaidAt = DateTime.UtcNow,
            PaidBy = User.GetUserName(),
        };

        db.CommissionPayments.Add(payment);
        foreach (var service in services)
        {
            service.CommissionPayment = payment;
        }

        try
        {
            await db.SaveChangesAsync();
        }
        catch (DbUpdateConcurrencyException)
        {
            return Fail(
                StatusCodes.Status409Conflict,
                "Algunos servicios cambiaron. Actualiza la información e inténtalo de nuevo.");
        }

        return Created(
            $"/api/commissions/payments/{payment.Id}",
            CommissionPaymentDto.From(payment));
    }

    /// <summary>Deshace un pago: sus servicios vuelven a quedar pendientes.</summary>
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Undo(int id)
    {
        var payment = await db.CommissionPayments.FindAsync(id);
        if (payment is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el pago.");
        }

        await db.Services
            .Where(s => s.CommissionPaymentId == id)
            .ExecuteUpdateAsync(set => set.SetProperty(s => s.CommissionPaymentId, (int?)null));

        db.CommissionPayments.Remove(payment);
        await db.SaveChangesAsync();

        return NoContent();
    }
}
