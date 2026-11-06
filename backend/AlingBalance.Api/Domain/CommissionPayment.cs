namespace AlingBalance.Api.Domain;

/// <summary>
/// Pago de comisiones a un empleado: agrupa los servicios terminados cuya
/// comisión se le pagó. Se puede deshacer (los servicios vuelven a quedar
/// pendientes).
/// </summary>
public class CommissionPayment
{
    public int Id { get; set; }

    public int? EmployeeId { get; set; }
    public Employee? Employee { get; set; }

    /// <summary>Nombre del empleado al momento del pago.</summary>
    public string EmployeeName { get; set; } = string.Empty;

    /// <summary>Mes al que corresponden los servicios.</summary>
    public int Year { get; set; }
    public int Month { get; set; }

    /// <summary>Total pagado en pesos.</summary>
    public int Amount { get; set; }

    public int ServiceCount { get; set; }

    public DateTime PaidAt { get; set; } = DateTime.UtcNow;

    /// <summary>Nombre del administrador que registró el pago.</summary>
    public string PaidBy { get; set; } = string.Empty;

    public ICollection<ServiceRecord> Services { get; set; } = new List<ServiceRecord>();
}

/// <summary>Regla de comisión (la misma que usa la app Flutter).</summary>
public static class Commission
{
    /// <summary>El empleado gana el 30 % del precio de cada servicio terminado.</summary>
    public const double Rate = 0.3;

    public static int For(int price) =>
        (int)Math.Round(price * Rate, MidpointRounding.AwayFromZero);
}
