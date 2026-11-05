namespace AlingBalance.Api.Catalog;

/// <summary>
/// Catálogo fijo de servicios, tipos de vehículo y precios (COP).
/// Es la fuente de verdad: los empleados siempre usan estos precios.
/// </summary>
public static class ServiceCatalog
{
    public static readonly IReadOnlyList<string> VehicleTypes = new[]
    {
        "Particular", "Taxi", "Camioneta",
    };

    private static readonly IReadOnlyDictionary<string, IReadOnlyDictionary<string, int>> Prices =
        new Dictionary<string, IReadOnlyDictionary<string, int>>
        {
            ["Alineación sencilla"] = new Dictionary<string, int>
            {
                ["Taxi"] = 15000, ["Particular"] = 20000, ["Camioneta"] = 30000,
            },
            ["Balanceo"] = new Dictionary<string, int>
            {
                ["Taxi"] = 30000, ["Particular"] = 30000, ["Camioneta"] = 50000,
            },
            ["Alineación doble"] = new Dictionary<string, int>
            {
                ["Taxi"] = 40000, ["Particular"] = 40000, ["Camioneta"] = 50000,
            },
            ["Montaje de llantas"] = new Dictionary<string, int>
            {
                ["Taxi"] = 15000, ["Particular"] = 15000, ["Camioneta"] = 30000,
            },
            ["Nitrógeno"] = new Dictionary<string, int>
            {
                ["Taxi"] = 20000, ["Particular"] = 20000, ["Camioneta"] = 30000,
            },
            ["Rines"] = new Dictionary<string, int>
            {
                ["Taxi"] = 50000, ["Particular"] = 50000, ["Camioneta"] = 50000,
            },
        };

    public static IEnumerable<string> ServiceTypes => Prices.Keys;

    public static bool IsValidVehicleType(string value) => VehicleTypes.Contains(value);

    public static bool IsValidServiceType(string value) => Prices.ContainsKey(value);

    public static bool TryGetPrice(string serviceType, string vehicleType, out int price)
    {
        price = 0;
        return Prices.TryGetValue(serviceType, out var byVehicle)
            && byVehicle.TryGetValue(vehicleType, out price);
    }
}
