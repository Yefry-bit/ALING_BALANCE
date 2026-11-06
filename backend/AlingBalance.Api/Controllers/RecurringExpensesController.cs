using AlingBalance.Api.Data;
using AlingBalance.Api.Domain;
using AlingBalance.Api.Dtos;
using AlingBalance.Api.Security;
using AlingBalance.Api.Services;
using AlingBalance.Api.Validation;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace AlingBalance.Api.Controllers;

/// <summary>Gastos fijos mensuales: arriendo, nómina… (solo administradores).</summary>
[ApiController]
[Route("api/recurring-expenses")]
[Authorize(Roles = Roles.Admin)]
public class RecurringExpensesController(AppDbContext db) : ApiControllerBase
{
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        var items = await db.RecurringExpenses
            .AsNoTracking()
            .OrderBy(r => r.DayOfMonth)
            .ThenBy(r => r.Description)
            .ToListAsync();

        return Ok(items.Select(RecurringExpenseDto.From));
    }

    [HttpPost]
    public async Task<IActionResult> Create(RecurringExpenseRequest request)
    {
        var errors = Validate(request, out var description, out var category);
        if (errors.HasErrors) return Invalid(errors);

        var today = RecurringExpenseScheduler.Today();
        var item = new RecurringExpense
        {
            Description = description,
            Category = category,
            Amount = request.Amount!.Value,
            DayOfMonth = request.DayOfMonth!.Value,
            Active = request.Active ?? true,
            LastGeneratedMonth = RecurringExpenseScheduler.StartingPoint(
                today, request.IncludeCurrentMonth ?? true),
            RegisteredBy = User.GetUserName(),
            CreatedAt = DateTime.UtcNow,
        };

        db.RecurringExpenses.Add(item);
        await db.SaveChangesAsync();
        await RecurringExpenseScheduler.GenerateAsync(db, today);

        return Created($"/api/recurring-expenses/{item.Id}", RecurringExpenseDto.From(item));
    }

    /// <summary>
    /// Edita un gasto fijo. Los cambios aplican a los próximos meses; los
    /// gastos ya registrados no se modifican (se editan uno por uno).
    /// </summary>
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, RecurringExpenseRequest request)
    {
        var errors = Validate(request, out var description, out var category);
        if (errors.HasErrors) return Invalid(errors);

        var item = await db.RecurringExpenses.FindAsync(id);
        if (item is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el gasto fijo.");
        }

        var today = RecurringExpenseScheduler.Today();
        var active = request.Active ?? item.Active;

        // Al reanudarlo no se cobran los meses que estuvo en pausa.
        if (active && !item.Active)
        {
            item.LastGeneratedMonth = Math.Max(
                item.LastGeneratedMonth,
                RecurringExpenseScheduler.StartingPoint(today, includeCurrentMonth: true));
        }

        item.Description = description;
        item.Category = category;
        item.Amount = request.Amount!.Value;
        item.DayOfMonth = request.DayOfMonth!.Value;
        item.Active = active;

        await db.SaveChangesAsync();
        await RecurringExpenseScheduler.GenerateAsync(db, today);

        return Ok(RecurringExpenseDto.From(item));
    }

    /// <summary>Elimina el gasto fijo; los gastos ya registrados se conservan.</summary>
    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var item = await db.RecurringExpenses.FindAsync(id);
        if (item is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el gasto fijo.");
        }

        await db.Expenses
            .Where(e => e.RecurringExpenseId == id)
            .ExecuteUpdateAsync(set => set.SetProperty(e => e.RecurringExpenseId, (int?)null));

        db.RecurringExpenses.Remove(item);
        await db.SaveChangesAsync();

        return NoContent();
    }

    private static ErrorBag Validate(
        RecurringExpenseRequest request, out string description, out string category)
    {
        var errors = new ErrorBag();

        description = Rules.NormalizeText(request.Description);
        category = Rules.NormalizeText(request.Category);

        errors.Add("description", Rules.CheckExpenseDescription(description));
        errors.Add("amount", Rules.CheckExpenseAmount(request.Amount));
        errors.Add("dayOfMonth", Rules.CheckRecurringDay(request.DayOfMonth));

        if (!ExpenseCategories.All.Contains(category))
        {
            errors.Add("category", "Selecciona una categoría válida.");
        }

        return errors;
    }
}
