using AlingBalance.Api.Domain;

namespace AlingBalance.Api.Dtos;

// ------------------------------------------------------------------ Acceso

/// <param name="RememberMe">
/// Mantener la sesión iniciada en el dispositivo: el token dura días en vez de horas.
/// </param>
public record LoginRequest(string? Username, string? Password, bool? RememberMe = null);

public record ChangePasswordRequest(string? CurrentPassword, string? NewPassword);

public record LoginResponse(string Token, DateTime ExpiresAt, UserDto User);

// ---------------------------------------------------------------- Usuarios

public record UserDto(int Id, string Name, string Username, string Role, bool Active)
{
    public static UserDto From(AppUser user) =>
        new(user.Id, user.Name, user.Username, user.Role, user.Active);
}

public record CreateUserRequest(string? Name, string? Username, string? Password, string? Role);

public record SetActiveRequest(bool? Active);

/// <summary>Editar nombre y rol de una cuenta (el usuario no se cambia).</summary>
public record UpdateUserRequest(string? Name, string? Role);

/// <summary>El administrador asigna una contraseña nueva a otra cuenta.</summary>
public record ResetPasswordRequest(string? Password);

// --------------------------------------------------------------- Empleados

public record EmployeeDto(int Id, string Name, string Document, string Phone, bool Active)
{
    public static EmployeeDto From(Employee e) =>
        new(e.Id, e.Name, e.Document, e.Phone, e.Active);

    /// <summary>Versión para empleados (sin documento ni teléfono).</summary>
    public static EmployeeDto Public(Employee e) =>
        new(e.Id, e.Name, string.Empty, string.Empty, e.Active);
}

public record CreateEmployeeRequest(string? Name, string? Document, string? Phone);

// --------------------------------------------------------------- Servicios

public record ServiceDto(
    int Operation,
    string Plate,
    string Vehicle,
    string VehicleType,
    string Service,
    string Status,
    int Price,
    DateTime Date,
    string RegisteredBy,
    int? EmployeeId,
    string EmployeeName,
    int PhotoCount = 0,
    DateTime? FinishedAt = null,
    int? CommissionPaymentId = null)
{
    public static ServiceDto From(ServiceRecord s, int photoCount = 0) => new(
        s.Operation,
        s.Plate,
        s.Vehicle,
        s.VehicleType,
        s.ServiceType,
        s.Status,
        s.Price,
        // Las fechas se guardan en UTC; se marca el tipo para que viajen con "Z".
        DateTime.SpecifyKind(s.Date, DateTimeKind.Utc),
        s.RegisteredBy,
        s.EmployeeId,
        s.EmployeeName,
        photoCount,
        s.FinishedAt is DateTime finished
            ? DateTime.SpecifyKind(finished, DateTimeKind.Utc)
            : null,
        s.CommissionPaymentId);
}

// ------------------------------------------------------------------- Fotos

public record PhotoDto(
    int Id,
    int Operation,
    string Kind,
    string Note,
    int TakenById,
    string TakenBy,
    DateTime CreatedAt)
{
    public static PhotoDto From(ServicePhoto p) => new(
        p.Id,
        p.ServiceOperation,
        p.Kind,
        p.Note,
        p.TakenById,
        p.TakenBy,
        DateTime.SpecifyKind(p.CreatedAt, DateTimeKind.Utc));
}

/// <summary>Formulario multipart para subir una foto.</summary>
public class UploadPhotoRequest
{
    public IFormFile? File { get; set; }
    public string? Kind { get; set; }
    public string? Note { get; set; }
}

public record CreateServiceRequest(
    string? Plate,
    string? Brand,
    string? Model,
    string? VehicleType,
    string? ServiceType,
    string? Status,
    int? Price,
    int? EmployeeId);

public record UpdateStatusRequest(string? Status);

public record AssignEmployeeRequest(int? EmployeeId);

// ---------------------------------------------------------------- Clientes

public record VehicleDto(
    int Id,
    int ClientId,
    string Plate,
    string Brand,
    string Model,
    string VehicleType)
{
    public static VehicleDto From(Vehicle v) =>
        new(v.Id, v.ClientId, v.Plate, v.Brand, v.Model, v.VehicleType);
}

public record ClientDto(
    int Id,
    string Name,
    string Document,
    string Phone,
    DateTime CreatedAt,
    IReadOnlyList<VehicleDto> Vehicles)
{
    public static ClientDto From(Client c) => new(
        c.Id,
        c.Name,
        c.Document,
        c.Phone,
        DateTime.SpecifyKind(c.CreatedAt, DateTimeKind.Utc),
        c.Vehicles.OrderBy(v => v.Plate).Select(VehicleDto.From).ToList());
}

/// <summary>Crear o editar un cliente.</summary>
public record ClientRequest(string? Name, string? Document, string? Phone);

public record CreateVehicleRequest(
    string? Plate,
    string? Brand,
    string? Model,
    string? VehicleType);

// ------------------------------------------------------------------ Gastos

public record ExpenseDto(
    int Id,
    string Description,
    string Category,
    int Amount,
    DateOnly Date,
    string RegisteredBy,
    int? RecurringExpenseId = null)
{
    public static ExpenseDto From(Expense e) => new(
        e.Id, e.Description, e.Category, e.Amount, e.Date, e.RegisteredBy, e.RecurringExpenseId);
}

public record CreateExpenseRequest(
    string? Description,
    string? Category,
    int? Amount,
    DateOnly? Date);

/// <summary>Gasto fijo mensual.</summary>
public record RecurringExpenseDto(
    int Id,
    string Description,
    string Category,
    int Amount,
    int DayOfMonth,
    bool Active)
{
    public static RecurringExpenseDto From(RecurringExpense r) =>
        new(r.Id, r.Description, r.Category, r.Amount, r.DayOfMonth, r.Active);
}

/// <param name="IncludeCurrentMonth">
/// Al crearlo: registrar también el gasto de este mes (si ya pasó el día).
/// </param>
public record RecurringExpenseRequest(
    string? Description,
    string? Category,
    int? Amount,
    int? DayOfMonth,
    bool? Active = null,
    bool? IncludeCurrentMonth = null);

// -------------------------------------------------------------- Comisiones

public record CommissionPaymentDto(
    int Id,
    int? EmployeeId,
    string EmployeeName,
    int Year,
    int Month,
    int Amount,
    int ServiceCount,
    DateTime PaidAt,
    string PaidBy)
{
    public static CommissionPaymentDto From(CommissionPayment p) => new(
        p.Id,
        p.EmployeeId,
        p.EmployeeName,
        p.Year,
        p.Month,
        p.Amount,
        p.ServiceCount,
        DateTime.SpecifyKind(p.PaidAt, DateTimeKind.Utc),
        p.PaidBy);
}

/// <summary>
/// Pagar la comisión de estos servicios (los que la app muestra como
/// pendientes del empleado en ese mes).
/// </summary>
public record PayCommissionsRequest(
    int? EmployeeId,
    int? Year,
    int? Month,
    IReadOnlyList<int>? Operations);
