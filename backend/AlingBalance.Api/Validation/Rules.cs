using System.Text.RegularExpressions;

namespace AlingBalance.Api.Validation;

/// <summary>
/// Reglas de validación y normalización de datos. Cada método Check devuelve
/// el mensaje de error, o null si el dato es válido. Las mismas reglas están
/// en la app Flutter (lib/core/utils/validators.dart).
/// </summary>
public static class Rules
{
    public const int MaxPrice = 5_000_000;
    public const int MinPasswordLength = 8;
    public const int MaxPasswordLength = 64;

    private static readonly Regex PersonNameRegex =
        new(@"^[\p{L}][\p{L}\p{M}'. -]*$", RegexOptions.Compiled);

    private static readonly Regex VehicleTextRegex =
        new(@"^[\p{L}\p{N}][\p{L}\p{N}\p{M} .\-/+]*$", RegexOptions.Compiled);

    private static readonly Regex PlateRegex = new(@"^[A-Z]{3}-\d{3}$", RegexOptions.Compiled);
    private static readonly Regex UsernameRegex = new(@"^[a-z0-9._]+$", RegexOptions.Compiled);
    private static readonly Regex DocumentRegex = new(@"^\d{5,12}$", RegexOptions.Compiled);
    private static readonly Regex PhoneRegex = new(@"^(\d{7}|3\d{9}|60\d{8})$", RegexOptions.Compiled);

    // ------------------------------------------------------------ Normalizar

    /// <summary>Quita espacios al inicio/final y junta los espacios repetidos.</summary>
    public static string NormalizeText(string? value)
    {
        return Regex.Replace((value ?? string.Empty).Trim(), @"\s+", " ");
    }

    /// <summary>"abc123" o "ABC 123" se convierten en "ABC-123".</summary>
    public static string NormalizePlate(string? value)
    {
        var plate = (value ?? string.Empty).Trim().ToUpperInvariant().Replace(" ", string.Empty);

        if (Regex.IsMatch(plate, @"^[A-Z]{3}\d{3}$"))
        {
            plate = plate[..3] + "-" + plate[3..];
        }

        return plate;
    }

    public static string NormalizeUsername(string? value)
    {
        return (value ?? string.Empty).Trim().ToLowerInvariant();
    }

    /// <summary>Deja solo los dígitos y quita el indicativo +57.</summary>
    public static string NormalizePhone(string? value)
    {
        var phone = Regex.Replace(value ?? string.Empty, @"[\s\-()]", string.Empty);

        if (phone.StartsWith("+57", StringComparison.Ordinal))
        {
            phone = phone[3..];
        }

        return phone;
    }

    // -------------------------------------------------------------- Validar

    public static string? CheckName(string name, string label = "El nombre")
    {
        if (name.Length == 0) return $"Ingresa {label.ToLowerInvariant()}.";
        if (name.Length < 3) return $"{label} debe tener al menos 3 caracteres.";
        if (name.Length > 80) return $"{label} no puede superar los 80 caracteres.";
        if (!PersonNameRegex.IsMatch(name))
        {
            return $"{label} solo puede tener letras, espacios, puntos, apóstrofes y guiones.";
        }

        return null;
    }

    public static string? CheckDocument(string document)
    {
        if (document.Length == 0) return "Ingresa el número de identificación.";
        if (!DocumentRegex.IsMatch(document))
        {
            return "La identificación debe tener solo números (entre 5 y 12 dígitos).";
        }

        return null;
    }

    /// <summary>El teléfono es opcional; si se escribe debe ser válido.</summary>
    public static string? CheckPhone(string phone)
    {
        if (phone.Length == 0) return null;
        if (!PhoneRegex.IsMatch(phone))
        {
            return "El teléfono debe tener 7 dígitos (fijo) o 10 dígitos (celular).";
        }

        return null;
    }

    public static string? CheckPlate(string plate)
    {
        if (plate.Length == 0) return "Ingresa la placa del vehículo.";
        if (!PlateRegex.IsMatch(plate)) return "La placa debe tener el formato ABC-123.";

        return null;
    }

    public static string? CheckVehicleText(string value, string label)
    {
        if (value.Length == 0) return $"Ingresa {label.ToLowerInvariant()}.";
        if (value.Length < 2) return $"{label} debe tener al menos 2 caracteres.";
        if (value.Length > 30) return $"{label} no puede superar los 30 caracteres.";
        if (!VehicleTextRegex.IsMatch(value))
        {
            return $"{label} contiene caracteres no permitidos.";
        }

        return null;
    }

    public static string? CheckUsername(string username)
    {
        if (username.Length == 0) return "Ingresa el nombre de usuario.";
        if (username.Length < 4) return "El usuario debe tener al menos 4 caracteres.";
        if (username.Length > 20) return "El usuario no puede superar los 20 caracteres.";
        if (!UsernameRegex.IsMatch(username))
        {
            return "El usuario solo puede tener letras, números, punto y guion bajo.";
        }

        return null;
    }

    public static string? CheckPassword(string? password)
    {
        if (string.IsNullOrEmpty(password)) return "Ingresa la contraseña.";
        if (password.Length < MinPasswordLength)
        {
            return $"La contraseña debe tener al menos {MinPasswordLength} caracteres.";
        }

        if (password.Length > MaxPasswordLength)
        {
            return $"La contraseña no puede superar los {MaxPasswordLength} caracteres.";
        }

        if (!password.Any(char.IsLetter)) return "La contraseña debe incluir al menos una letra.";
        if (!password.Any(char.IsDigit)) return "La contraseña debe incluir al menos un número.";

        return null;
    }

    public static string? CheckPrice(int price)
    {
        if (price <= 0) return "El precio debe ser mayor a cero.";
        if (price > MaxPrice) return "El precio no puede superar $5.000.000.";

        return null;
    }

    // ---------------------------------------------------------------- Fotos

    public const int MaxPhotoBytes = 5 * 1024 * 1024;
    public const int MaxPhotosPerService = 12;
    public const int MaxPhotoNoteLength = 200;

    /// <summary>
    /// Tipo real de la imagen según sus primeros bytes (JPEG, PNG o WebP), o
    /// null si no es una imagen permitida. No se confía en la extensión ni en
    /// el tipo que declara el cliente.
    /// </summary>
    public static string? DetectImageType(ReadOnlySpan<byte> data)
    {
        if (data.Length >= 3 && data[0] == 0xFF && data[1] == 0xD8 && data[2] == 0xFF)
        {
            return "image/jpeg";
        }

        if (data.Length >= 8
            && data[..8].SequenceEqual(new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A }))
        {
            return "image/png";
        }

        if (data.Length >= 12
            && data[..4].SequenceEqual("RIFF"u8)
            && data[8..12].SequenceEqual("WEBP"u8))
        {
            return "image/webp";
        }

        return null;
    }

    public static string? CheckPhotoNote(string note)
    {
        return note.Length > MaxPhotoNoteLength
            ? $"La descripción no puede superar los {MaxPhotoNoteLength} caracteres."
            : null;
    }

    // --------------------------------------------------------------- Gastos

    public const int MaxExpense = 50_000_000;

    public static string? CheckExpenseDescription(string description)
    {
        if (description.Length == 0) return "Ingresa la descripción del gasto.";
        if (description.Length < 3) return "La descripción debe tener al menos 3 caracteres.";
        if (description.Length > 80) return "La descripción no puede superar los 80 caracteres.";

        return null;
    }

    public static string? CheckExpenseAmount(int? amount)
    {
        if (amount is null) return "Ingresa el valor del gasto.";
        if (amount <= 0) return "El valor debe ser mayor a cero.";
        if (amount > MaxExpense) return "El valor no puede superar $50.000.000.";

        return null;
    }

    /// <summary>
    /// La fecha es obligatoria, no puede ser futura (se admite un día de
    /// margen por la diferencia horaria) ni anterior al año 2000.
    /// </summary>
    /// <summary>Día de un gasto fijo: 1 a 28 (así existe en todos los meses).</summary>
    public static string? CheckRecurringDay(int? day)
    {
        if (day is null) return "Indica el día del mes.";
        if (day < 1 || day > 28) return "El día debe estar entre 1 y 28.";

        return null;
    }

    public static string? CheckExpenseDate(DateOnly? date, DateOnly today)
    {
        if (date is null) return "Ingresa la fecha del gasto.";
        if (date.Value > today.AddDays(1)) return "La fecha del gasto no puede ser futura.";
        if (date.Value.Year < 2000) return "La fecha del gasto no es válida.";

        return null;
    }
}
