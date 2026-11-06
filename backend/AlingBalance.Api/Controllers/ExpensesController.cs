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

/// <summary>Gastos del taller (solo administradores).</summary>
[ApiController]
[Route("api/expenses")]
[Authorize(Roles = Roles.Admin)]
public class ExpensesController(AppDbContext db) : ApiControllerBase
{
    /// <summary>
    /// Todos los gastos, del más reciente al más antiguo. Antes registra los
    /// gastos fijos (arriendo, nómina…) que ya correspondan.
    /// </summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
        await RecurringExpenseScheduler.GenerateAsync(db, RecurringExpenseScheduler.Today());

        var expenses = await db.Expenses
            .AsNoTracking()
            .OrderByDescending(e => e.Date)
            .ThenByDescending(e => e.Id)
            .ToListAsync();

        return Ok(expenses.Select(ExpenseDto.From));
    }

    [HttpPost]
    public async Task<IActionResult> Create(CreateExpenseRequest request)
    {
        var errors = Validate(request, out var description, out var category);
        if (errors.HasErrors) return Invalid(errors);

        var expense = new Expense
        {
            Description = description,
            Category = category,
            Amount = request.Amount!.Value,
            Date = request.Date!.Value,
            RegisteredBy = User.GetUserName(),
            CreatedAt = DateTime.UtcNow,
        };

        db.Expenses.Add(expense);
        await db.SaveChangesAsync();

        return Created($"/api/expenses/{expense.Id}", ExpenseDto.From(expense));
    }

    /// <summary>Corrige un gasto ya registrado.</summary>
    [HttpPut("{id:int}")]
    public async Task<IActionResult> Update(int id, CreateExpenseRequest request)
    {
        var errors = Validate(request, out var description, out var category);
        if (errors.HasErrors) return Invalid(errors);

        var expense = await db.Expenses.FindAsync(id);
        if (expense is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el gasto.");
        }

        expense.Description = description;
        expense.Category = category;
        expense.Amount = request.Amount!.Value;
        expense.Date = request.Date!.Value;

        try
        {
            await db.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            return Fail(
                StatusCodes.Status409Conflict,
                "Ese gasto fijo ya tiene otro gasto registrado en esa fecha.");
        }

        return Ok(ExpenseDto.From(expense));
    }

    [HttpDelete("{id:int}")]
    public async Task<IActionResult> Delete(int id)
    {
        var expense = await db.Expenses.FindAsync(id);
        if (expense is null)
        {
            return Fail(StatusCodes.Status404NotFound, "No se encontró el gasto.");
        }

        db.Expenses.Remove(expense);
        await db.SaveChangesAsync();

        return NoContent();
    }

    private static ErrorBag Validate(
        CreateExpenseRequest request, out string description, out string category)
    {
        var errors = new ErrorBag();

        description = Rules.NormalizeText(request.Description);
        category = Rules.NormalizeText(request.Category);

        errors.Add("description", Rules.CheckExpenseDescription(description));
        errors.Add("amount", Rules.CheckExpenseAmount(request.Amount));
        errors.Add("date", Rules.CheckExpenseDate(
            request.Date, DateOnly.FromDateTime(DateTime.UtcNow)));

        if (!ExpenseCategories.All.Contains(category))
        {
            errors.Add("category", "Selecciona una categoría válida.");
        }

        return errors;
    }
}
