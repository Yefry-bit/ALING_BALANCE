namespace AlingBalance.Api.Domain;

/// <summary>
/// Foto de evidencia de un servicio: el carro, las máquinas usadas o una
/// falla / pieza faltante. La imagen se guarda en la base de datos para que
/// todos los dispositivos la vean.
/// </summary>
public class ServicePhoto
{
    public int Id { get; set; }

    public int ServiceOperation { get; set; }
    public ServiceRecord? Service { get; set; }

    /// <summary>Una de <see cref="PhotoKinds.All"/>.</summary>
    public string Kind { get; set; } = PhotoKinds.Vehicle;

    /// <summary>Descripción opcional (por ejemplo, "Rayón en la puerta").</summary>
    public string Note { get; set; } = string.Empty;

    /// <summary>image/jpeg, image/png o image/webp.</summary>
    public string ContentType { get; set; } = "image/jpeg";

    public byte[] Data { get; set; } = Array.Empty<byte>();

    public int TakenById { get; set; }
    public string TakenBy { get; set; } = string.Empty;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}

/// <summary>Tipos de foto (mismos textos que la app Flutter).</summary>
public static class PhotoKinds
{
    public const string Vehicle = "Vehículo";
    public const string Machine = "Máquina / equipo";
    public const string Damage = "Falla o daño";
    public const string Missing = "Pieza faltante";

    public static readonly string[] All = { Vehicle, Machine, Damage, Missing };
}
