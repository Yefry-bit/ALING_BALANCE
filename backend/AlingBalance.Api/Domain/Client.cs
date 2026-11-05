namespace AlingBalance.Api.Domain;

/// <summary>Cliente del taller. Puede tener varios vehículos registrados.</summary>
public class Client
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    /// <summary>Número de identificación (único).</summary>
    public string Document { get; set; } = string.Empty;

    /// <summary>Opcional ('' si no hay).</summary>
    public string Phone { get; set; } = string.Empty;

    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;

    public ICollection<Vehicle> Vehicles { get; set; } = new List<Vehicle>();
}

/// <summary>
/// Vehículo de un cliente. La placa es única: un vehículo pertenece a un
/// solo cliente. Los servicios se enlazan con el vehículo por la placa.
/// </summary>
public class Vehicle
{
    public int Id { get; set; }

    public int ClientId { get; set; }
    public Client? Client { get; set; }

    public string Plate { get; set; } = string.Empty;
    public string Brand { get; set; } = string.Empty;
    public string Model { get; set; } = string.Empty;
    public string VehicleType { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
