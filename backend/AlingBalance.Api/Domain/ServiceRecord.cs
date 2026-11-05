namespace AlingBalance.Api.Domain;

/// <summary>Una operación de servicio realizada a un vehículo.</summary>
public class ServiceRecord
{
    /// <summary>Número consecutivo de la operación (lo asigna la base de datos).</summary>
    public int Operation { get; set; }

    public string Plate { get; set; } = string.Empty;

    /// <summary>Marca y modelo, por ejemplo "Chevrolet Spark".</summary>
    public string Vehicle { get; set; } = string.Empty;

    public string VehicleType { get; set; } = string.Empty;
    public string ServiceType { get; set; } = string.Empty;
    public string Status { get; set; } = ServiceStatuses.InProgress;

    /// <summary>Precio en pesos colombianos.</summary>
    public int Price { get; set; }

    public DateTime Date { get; set; } = DateTime.UtcNow;

    /// <summary>
    /// Momento (UTC) en que el servicio pasó a "Terminado"; null si está en
    /// proceso. Al reabrirlo se borra y al terminarlo de nuevo se actualiza.
    /// </summary>
    public DateTime? FinishedAt { get; set; }

    /// <summary>Nombre del usuario que registró el servicio.</summary>
    public string RegisteredBy { get; set; } = string.Empty;

    public int? EmployeeId { get; set; }
    public Employee? Employee { get; set; }

    /// <summary>Nombre del empleado al momento de registrar el servicio.</summary>
    public string EmployeeName { get; set; } = string.Empty;
}
