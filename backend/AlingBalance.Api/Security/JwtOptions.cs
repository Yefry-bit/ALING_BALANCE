namespace AlingBalance.Api.Security;

/// <summary>Configuración de los tokens JWT (sección "Jwt" de appsettings).</summary>
public sealed class JwtOptions
{
    public string Key { get; set; } = string.Empty;
    public string Issuer { get; set; } = "AlingBalance";
    public string Audience { get; set; } = "AlingBalance.App";
    public int ExpiryMinutes { get; set; } = 480;

    /// <summary>Duración de la sesión cuando se elige "Mantener la sesión iniciada".</summary>
    public int RememberDays { get; set; } = 30;
}
