namespace AlingBalance.Api.Domain;

/// <summary>Cuenta de acceso a la aplicación.</summary>
public class AppUser
{
    public int Id { get; set; }
    public string Name { get; set; } = string.Empty;

    /// <summary>Nombre de usuario en minúsculas (único).</summary>
    public string Username { get; set; } = string.Empty;

    /// <summary>Hash PBKDF2 de la contraseña; nunca se guarda la contraseña.</summary>
    public string PasswordHash { get; set; } = string.Empty;

    public string Role { get; set; } = Roles.Employee;
    public bool Active { get; set; } = true;
    public DateTime CreatedAt { get; set; } = DateTime.UtcNow;
}
