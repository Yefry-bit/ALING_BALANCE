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
