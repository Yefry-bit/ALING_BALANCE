namespace AlingBalance.Api.Domain;

/// <summary>Empleado del taller (quien realiza los trabajos y gana comisión).</summary>
public class Employee
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    /// <summary>Número de identificación (único).</summary>
    public string Document { get; set; } = string.Empty;

    public string Phone { get; set; } = string.Empty;
    public bool Active { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<ServiceRecord> Services { get; set; } = new List<ServiceRecord>();
}
