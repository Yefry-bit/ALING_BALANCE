namespace AlingBalance.Api.Domain;

/// <summary>Gasto del taller (arriendo, insumos, servicios públicos, etc.).</summary>
public class Expense
{
    public int Id { get; set; }
    public string Description { get; set; } = string.Empty;

    /// <summary>Una de <see cref="ExpenseCategories.All"/>.</summary>
    public string Category { get; set; } = string.Empty;

    /// <summary>Valor en pesos colombianos.</summary>
    public int Amount { get; set; }

    /// <summary>Día en que se hizo el gasto (define el mes en el que cuenta).</summary>
    public DateOnly Date { get; set; }

    /// <summary>Nombre del usuario que lo registró.</summary>
    public string RegisteredBy { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    /// <summary>Gasto fijo que lo generó (arriendo, nómina…); null si se registró a mano.</summary>
    public int? RecurringExpenseId { get; set; }
    public RecurringExpense? RecurringExpense { get; set; }
}

/// <summary>
/// Gasto que se repite cada mes (arriendo, nómina, internet…). El servidor
/// registra automáticamente el gasto de cada mes al llegar el día indicado.
/// </summary>
public class RecurringExpense
{
    public int Id { get; set; }
    public string Description { get; set; } = string.Empty;
    public string Category { get; set; } = string.Empty;
    public int Amount { get; set; }

    /// <summary>Día del mes en que se registra (1 a 28, existe en todos los meses).</summary>
    public int DayOfMonth { get; set; }

    /// <summary>Si está en pausa no se generan gastos nuevos.</summary>
    public bool Active { get; set; } = true;

    /// <summary>
    /// Último mes ya generado, como año × 12 + (mes − 1). Si se borra un
    /// gasto generado no se vuelve a crear.
    /// </summary>
    public int LastGeneratedMonth { get; set; }

    public string RegisteredBy { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>Categorías de gasto (mismos textos que usa la app Flutter).</summary>
public static class ExpenseCategories
{
    public static readonly string[] All =
    {
        "Arriendo",
        "Nómina",
        "Servicios públicos",
        "Insumos y repuestos",
        "Mantenimiento de equipos",
        "Impuestos",
        "Otros",
    };
}
