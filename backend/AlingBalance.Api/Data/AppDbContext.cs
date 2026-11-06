using AlingBalance.Api.Domain;
using Microsoft.EntityFrameworkCore;

namespace AlingBalance.Api.Data;

/// <summary>
/// Base de datos de AlingBalance. Las restricciones (únicos, llaves foráneas,
/// longitudes y CHECK) se definen aquí, así la base protege los datos aunque
/// falle alguna validación de la API.
/// </summary>
public class AppDbContext(DbContextOptions options) : DbContext(options)
{
    public DbSet<AppUser> Users => Set<AppUser>();
    public DbSet<Employee> Employees => Set<Employee>();
    public DbSet<ServiceRecord> Services => Set<ServiceRecord>();
    public DbSet<Client> Clients => Set<Client>();
    public DbSet<Vehicle> Vehicles => Set<Vehicle>();
    public DbSet<Expense> Expenses => Set<Expense>();
    public DbSet<ServicePhoto> ServicePhotos => Set<ServicePhoto>();
    public DbSet<CommissionPayment> CommissionPayments => Set<CommissionPayment>();
    public DbSet<RecurringExpense> RecurringExpenses => Set<RecurringExpense>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AppUser>(entity =>
        {
            entity.ToTable("Users", table =>
                table.HasCheckConstraint("CK_Users_Role", "[Role] IN ('administrador', 'empleado')"));

            entity.HasKey(u => u.Id);
            entity.Property(u => u.Name).HasMaxLength(80).IsRequired();
            entity.Property(u => u.Username).HasMaxLength(20).IsRequired();
            entity.Property(u => u.PasswordHash).HasMaxLength(200).IsRequired();
            entity.Property(u => u.Role).HasMaxLength(20).IsRequired();
            entity.Property(u => u.SecurityStamp).HasMaxLength(40);
            entity.HasIndex(u => u.Username).IsUnique();
        });

        modelBuilder.Entity<Employee>(entity =>
        {
            entity.ToTable("Employees");
            entity.HasKey(e => e.Id);
            entity.Property(e => e.Name).HasMaxLength(80).IsRequired();
            entity.Property(e => e.Document).HasMaxLength(12).IsRequired();
            entity.Property(e => e.Phone).HasMaxLength(10).IsRequired();
            entity.HasIndex(e => e.Document).IsUnique();
        });

        modelBuilder.Entity<ServiceRecord>(entity =>
        {
            entity.ToTable("Services", table =>
            {
                table.HasCheckConstraint("CK_Services_Price", "[Price] > 0");
                table.HasCheckConstraint(
                    "CK_Services_Status", "[Status] IN ('En proceso', 'Terminado')");
            });

            entity.HasKey(s => s.Operation);
            entity.Property(s => s.Plate).HasMaxLength(8).IsRequired();
            entity.Property(s => s.Vehicle).HasMaxLength(70).IsRequired();
            entity.Property(s => s.VehicleType).HasMaxLength(20).IsRequired();
            entity.Property(s => s.ServiceType).HasMaxLength(40).IsRequired();
            entity.Property(s => s.Status).HasMaxLength(20).IsRequired();
            entity.Property(s => s.RegisteredBy).HasMaxLength(80).IsRequired();
            entity.Property(s => s.EmployeeName).HasMaxLength(80).IsRequired();

            // Si se borrara un empleado, sus servicios se conservan sin asignar.
            entity.HasOne(s => s.Employee)
                .WithMany(e => e.Services)
                .HasForeignKey(s => s.EmployeeId)
                .OnDelete(DeleteBehavior.SetNull);

            entity.HasIndex(s => s.Plate);
            entity.HasIndex(s => s.Status);

            // Al deshacer un pago, sus servicios vuelven a quedar pendientes.
            entity.HasOne(s => s.CommissionPayment)
                .WithMany(p => p.Services)
                .HasForeignKey(s => s.CommissionPaymentId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<CommissionPayment>(entity =>
        {
            entity.ToTable("CommissionPayments", table =>
            {
                table.HasCheckConstraint("CK_CommissionPayments_Amount", "[Amount] >= 0");
                table.HasCheckConstraint("CK_CommissionPayments_Month", "[Month] BETWEEN 1 AND 12");
            });

            entity.HasKey(p => p.Id);
            entity.Property(p => p.EmployeeName).HasMaxLength(80).IsRequired();
            entity.Property(p => p.PaidBy).HasMaxLength(80).IsRequired();
            entity.HasIndex(p => new { p.Year, p.Month });

            entity.HasOne(p => p.Employee)
                .WithMany()
                .HasForeignKey(p => p.EmployeeId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<Client>(entity =>
        {
            entity.ToTable("Clients");
            entity.HasKey(c => c.Id);
            entity.Property(c => c.Name).HasMaxLength(80).IsRequired();
            entity.Property(c => c.Document).HasMaxLength(12).IsRequired();
            entity.Property(c => c.Phone).HasMaxLength(10).IsRequired();
            entity.HasIndex(c => c.Document).IsUnique();
        });

        modelBuilder.Entity<Vehicle>(entity =>
        {
            entity.ToTable("Vehicles");
            entity.HasKey(v => v.Id);
            entity.Property(v => v.Plate).HasMaxLength(8).IsRequired();
            entity.Property(v => v.Brand).HasMaxLength(30).IsRequired();
            entity.Property(v => v.Model).HasMaxLength(30).IsRequired();
            entity.Property(v => v.VehicleType).HasMaxLength(20).IsRequired();

            // Una placa pertenece a un solo cliente.
            entity.HasIndex(v => v.Plate).IsUnique();

            // Al eliminar un cliente se eliminan sus vehículos; los servicios
            // (enlazados por placa) se conservan en el historial.
            entity.HasOne(v => v.Client)
                .WithMany(c => c.Vehicles)
                .HasForeignKey(v => v.ClientId)
                .OnDelete(DeleteBehavior.Cascade);
        });

        modelBuilder.Entity<Expense>(entity =>
        {
            entity.ToTable("Expenses", table =>
                table.HasCheckConstraint("CK_Expenses_Amount", "[Amount] > 0"));

            entity.HasKey(e => e.Id);
            entity.Property(e => e.Description).HasMaxLength(80).IsRequired();
            entity.Property(e => e.Category).HasMaxLength(40).IsRequired();
            entity.Property(e => e.RegisteredBy).HasMaxLength(80).IsRequired();
            entity.HasIndex(e => e.Date);

            // Un solo gasto generado por gasto fijo y fecha.
            entity.HasIndex(e => new { e.RecurringExpenseId, e.Date })
                .IsUnique()
                .HasFilter("[RecurringExpenseId] IS NOT NULL");

            // Si se elimina el gasto fijo, los gastos ya generados se conservan.
            entity.HasOne(e => e.RecurringExpense)
                .WithMany()
                .HasForeignKey(e => e.RecurringExpenseId)
                .OnDelete(DeleteBehavior.SetNull);
        });

        modelBuilder.Entity<RecurringExpense>(entity =>
        {
            entity.ToTable("RecurringExpenses", table =>
            {
                table.HasCheckConstraint("CK_RecurringExpenses_Amount", "[Amount] > 0");
                table.HasCheckConstraint("CK_RecurringExpenses_Day", "[DayOfMonth] BETWEEN 1 AND 28");
            });

            entity.HasKey(r => r.Id);
            entity.Property(r => r.Description).HasMaxLength(80).IsRequired();
            entity.Property(r => r.Category).HasMaxLength(40).IsRequired();
            entity.Property(r => r.RegisteredBy).HasMaxLength(80).IsRequired();
        });

        modelBuilder.Entity<ServicePhoto>(entity =>
        {
            entity.ToTable("ServicePhotos");
            entity.HasKey(p => p.Id);
            entity.Property(p => p.Kind).HasMaxLength(30).IsRequired();
            entity.Property(p => p.Note).HasMaxLength(200).IsRequired();
            entity.Property(p => p.ContentType).HasMaxLength(30).IsRequired();
            entity.Property(p => p.Data).IsRequired();
            entity.Property(p => p.TakenBy).HasMaxLength(80).IsRequired();

            entity.HasOne(p => p.Service)
                .WithMany()
                .HasForeignKey(p => p.ServiceOperation)
                .OnDelete(DeleteBehavior.Cascade);
        });
    }
}
