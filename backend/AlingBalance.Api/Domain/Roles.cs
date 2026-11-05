namespace AlingBalance.Api.Domain;

/// <summary>Roles de usuario (mismos textos que usa la app Flutter).</summary>
public static class Roles
{
    public const string Admin = "administrador";
    public const string Employee = "empleado";

    public static readonly string[] All = { Admin, Employee };
}

/// <summary>Estados posibles de un servicio.</summary>
public static class ServiceStatuses
{
    public const string InProgress = "En proceso";
    public const string Finished = "Terminado";

    public static readonly string[] All = { InProgress, Finished };
}
