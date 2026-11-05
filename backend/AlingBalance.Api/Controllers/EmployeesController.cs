using AlingBalance.Api.Data;
using AlingBalance.Api.Domain;
using AlingBalance.Api.Dtos;
using AlingBalance.Api.Validation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AlingBalance.Api.Controllers;

[ApiController]
[Route("api/employees")]
[Authorize]
public class EmployeesController(AppDbContext db) : ApiControllerBase
{
    /// <summary>
    /// Administrador: todos los empleados con sus datos.
    /// Empleado: solo los activos y sin documento ni teléfono.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var isAdmin = User.IsInRole(Roles.Admin);

        var query = db.Employees.AsNoTracking();
        if (!isAdmin)
        {
            query = query.Where(e => e.Active);
        }

        var employees = await query.OrderBy(e => e.Name).ToListAsync();
        return Ok(employees.Select(e => isAdmin ? EmployeeDto.From(e) : EmployeeDto.Public(e)));
    }

    [HttpPost]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> Create(CreateEmployeeRequest request)
    {
        var errors = new ErrorBag();

        var name = Rules.NormalizeText(request.Name);
        var document = (request.Document ?? string.Empty).Trim();
        var phone = Rules.NormalizePhone(request.Phone);

        errors.Add("name", Rules.CheckName(name));
        errors.Add("document", Rules.CheckDocument(document));
        errors.Add("phone", Rules.CheckPhone(phone));

        if (errors.HasErrors) return Invalid(errors);

        if (await db.Employees.AnyAsync(e => e.Document == document))
        {
            return Fail(
                StatusCodes.Status409Conflict,
                "Ya existe un empleado con esa identificación.");
        }

        var employee = new Employee
        {
            Name = name,
            Document = document,
            Phone = phone,
            Active = true,
            CreatedAt = DateTime.UtcNow,
        };

        db.Employees.Add(employee);

        try
        {
            await db.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return Fail(
                StatusCodes.Status409Conflict,
                "Ya existe un empleado con esa identificación.");
        }

        return Created($"/api/employees/{employee.Id}", EmployeeDto.From(employee));
    }

    [HttpPatch("{id:int}/active")]
    [Authorize(Roles = Roles.Admin)]
    public async Task<IActionResult> SetActive(int id, SetActiveRequest request)
    {
        if (request.Active is null)
        {
            var errors = new ErrorBag();
            errors.Add("active", "Indica si el empleado debe quedar activo o inactivo.");
            return Invalid(errors);
        }

        var active = request.Active.Value;
        var employee = await db.Employees.FindAsync(id);

        if (employee is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el empleado.");
        }

        if (!active && employee.Active)
        {
            var pending = await db.Services.CountAsync(s =>
                s.EmployeeId == id && s.Status == ServiceStatuses.InProgress);

            if (pending > 0)
            {
                return Fail(
                    StatusCodes.Status409Conflict,
                    $"No puedes desactivar a {employee.Name}: tiene {pending} servicio(s) en proceso.");
            }
        }

        employee.Active = active;
        await db.SaveChangesAsync();

        return Ok(EmployeeDto.From(employee));
    }
}
