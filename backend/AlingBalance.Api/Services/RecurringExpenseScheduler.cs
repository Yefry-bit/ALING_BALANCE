using AlingBalance.Api.Data;
using AlingBalance.Api.Domain;
using Microsoft.EntityFrameworkCore;

namespace AlingBalance.Api.Services;

/// <summary>
/// Registra los gastos fijos (arriendo, nómina…) de cada mes cuando llega su
/// día. Se ejecuta al consultar los gastos, así no hace falta un proceso
/// aparte. Cada mes se genera una sola vez, aunque luego se borre el gasto.
/// </summary>
public static class RecurringExpenseScheduler
{
    /// <summary>Mes como número: año × 12 + (mes − 1).</summary>
    public static int MonthIndex(int year, int month) => year * 12 + month - 1;

    public static int MonthIndex(DateOnly date) => MonthIndex(date.Year, date.Month);

    /// <summary>
    /// Fechas de los gastos que faltan por registrar hasta <paramref name="today"/>.
    /// </summary>
    public static IReadOnlyList<DateOnly> DueDates(RecurringExpense recurring, DateOnly today)
    {
        var dates = new List<DateOnly>();
        if (!recurring.Active) return dates;

        for (var index = recurring.LastGeneratedMonth + 1; index <= MonthIndex(today); index++)
        {
            var date = new DateOnly(index / 12, index % 12 + 1, recurring.DayOfMonth);
            if (date > today) break;
            dates.Add(date);
        }

        return dates;
    }

    /// <summary>Último mes ya cubierto al crear (o reanudar) un gasto fijo.</summary>
    public static int StartingPoint(DateOnly today, bool includeCurrentMonth) =>
        MonthIndex(today) - (includeCurrentMonth ? 1 : 0);

    /// <summary>Crea los gastos pendientes de todos los gastos fijos activos.</summary>
    public static async Task<int> GenerateAsync(AppDbContext db, DateOnly today)
    {
        var recurring = await db.RecurringExpenses.Where(r => r.Active).ToListAsync();
        var created = 0;

        foreach (var item in recurring)
        {
            var dates = DueDates(item, today);
            if (dates.Count == 0) continue;

            var registeredBy = $"Automático ({item.RegisteredBy})";
            if (registeredBy.Length > 80) registeredBy = "Automático";

            foreach (var date in dates)
            {
                db.Expenses.Add(new Expense
                {
                    Description = item.Description,
                    Category = item.Category,
                    Amount = item.Amount,
                    Date = date,
                    RegisteredBy = registeredBy,
                    RecurringExpenseId = item.Id,
                    CreatedAt = DateTime.UtcNow,
                });
            }

            item.LastGeneratedMonth = MonthIndex(dates[^1]);
            created += dates.Count;
        }

        if (created == 0) return 0;

        try
        {
            await db.SaveChangesAsync();
        }
        catch (DbUpdateException)
        {
            // Otra petición los generó al mismo tiempo (índice único).
            db.ChangeTracker.Clear();
            return 0;
        }

        return created;
    }

    /// <summary>Hoy según la hora local del servidor (el taller).</summary>
    public static DateOnly Today() => DateOnly.FromDateTime(DateTime.Now);
}
