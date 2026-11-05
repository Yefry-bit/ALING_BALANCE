using AlingBalance.Api.Data;
using AlingBalance.Api.Domain;
using AlingBalance.Api.Dtos;
using AlingBalance.Api.Security;
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
    /// <summary>Todos los gastos, del más reciente al más antiguo.</summary>
    [HttpGet]
    public async Task<IActionResult> GetAll()
    {
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
        var errors = new ErrorBag();

        var description = Rules.NormalizeText(request.Description);
        var category = Rules.NormalizeText(request.Category);

        errors.Add("description", Rules.CheckExpenseDescription(description));
        errors.Add("amount", Rules.CheckExpenseAmount(request.Amount));
        errors.Add("date", Rules.CheckExpenseDate(
            request.Date, DateOnly.FromDateTime(DateTime.UtcNow)));

        if (!ExpenseCategories.All.Contains(category))
        {
            errors.Add("category", "Selecciona una categoría válida.");
        }

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
}
