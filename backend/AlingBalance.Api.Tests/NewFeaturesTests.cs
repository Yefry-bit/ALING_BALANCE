using AlingBalance.Api.Data;
using AlingBalance.Api.Domain;
using AlingBalance.Api.Services;
using AlingBalance.Api.Validation;
using Microsoft.Data.Sqlite;
using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Xunit;

namespace AlingBalance.Api.Tests;

public class RecurringExpenseTests
{
    private static RecurringExpense Item(int day, int lastGenerated, bool active = true) => new()
    {
        Description = "Arriendo",
        Category = "Arriendo",
        Amount = 1_500_000,
        DayOfMonth = day,
        LastGeneratedMonth = lastGenerated,
        Active = active,
    };

    private static int Month(int year, int month) => RecurringExpenseScheduler.MonthIndex(year, month);

    [Fact]
    public void Genera_el_mes_actual_cuando_ya_llego_el_dia()
    {
        var item = Item(day: 5, lastGenerated: Month(2026, 10));

        var dates = RecurringExpenseScheduler.DueDates(item, new DateOnly(2026, 11, 5));

        Assert.Equal(new[] { new DateOnly(2026, 11, 5) }, dates);
    }

    [Fact]
    public void No_genera_antes_del_dia()
    {
        var item = Item(day: 28, lastGenerated: Month(2026, 10));

        Assert.Empty(RecurringExpenseScheduler.DueDates(item, new DateOnly(2026, 11, 27)));
    }

    [Fact]
    public void Recupera_los_meses_atrasados_incluso_cambiando_de_anio()
    {
        var item = Item(day: 1, lastGenerated: Month(2026, 11));

        var dates = RecurringExpenseScheduler.DueDates(item, new DateOnly(2027, 2, 10));

        Assert.Equal(
            new[] { new DateOnly(2026, 12, 1), new DateOnly(2027, 1, 1), new DateOnly(2027, 2, 1) },
            dates);
    }

    [Fact]
    public void Un_mes_ya_generado_no_se_repite()
    {
        var item = Item(day: 1, lastGenerated: Month(2026, 11));

        Assert.Empty(RecurringExpenseScheduler.DueDates(item, new DateOnly(2026, 11, 30)));
    }

    [Fact]
    public void En_pausa_no_genera()
    {
        var item = Item(day: 1, lastGenerated: Month(2026, 1), active: false);

        Assert.Empty(RecurringExpenseScheduler.DueDates(item, new DateOnly(2026, 11, 30)));
    }

    [Fact]
    public void Al_crear_se_puede_incluir_o_no_el_mes_actual()
    {
        var today = new DateOnly(2026, 11, 15);

        Assert.Equal(Month(2026, 10), RecurringExpenseScheduler.StartingPoint(today, true));
        Assert.Equal(Month(2026, 11), RecurringExpenseScheduler.StartingPoint(today, false));
    }

    [Theory]
    [InlineData(null, false)]
    [InlineData(0, false)]
    [InlineData(1, true)]
    [InlineData(28, true)]
    [InlineData(29, false)]
    [InlineData(31, false)]
    public void Dia_del_gasto_fijo(int? day, bool valid)
    {
        Assert.Equal(valid, Rules.CheckRecurringDay(day) is null);
    }
}

public class CommissionTests
{
    [Theory]
    [InlineData(30_000, 9_000)]
    [InlineData(15_000, 4_500)]
    [InlineData(5, 2)] // 1,5 redondea hacia arriba, igual que la app
    [InlineData(25, 8)] // 7,5 → 8
    public void Es_el_30_por_ciento_redondeado(int price, int expected)
    {
        Assert.Equal(expected, Commission.For(price));
    }
}

/// <summary>Migraciones sobre una base SQLite en memoria.</summary>
public sealed class MigrationTests : IDisposable
{
    private readonly SqliteConnection _connection = new("Data Source=:memory:");

    public MigrationTests() => _connection.Open();

    public void Dispose() => _connection.Dispose();

    private SqliteAppDbContext NewContext() =>
        new(new DbContextOptionsBuilder<SqliteAppDbContext>().UseSqlite(_connection).Options);

    [Fact]
    public async Task Base_nueva_se_crea_con_todas_las_migraciones()
    {
        await using var db = NewContext();

        await DatabaseInitializer.InitializeAsync(db);

        Assert.Empty(await db.Database.GetPendingMigrationsAsync());
        Assert.Equal(0, await db.CommissionPayments.CountAsync());
        Assert.Equal(0, await db.RecurringExpenses.CountAsync());
    }

    [Fact]
    public async Task El_modelo_coincide_con_las_migraciones()
    {
        await using var db = NewContext();

        Assert.False(db.Database.HasPendingModelChanges());
    }

    [Fact]
    public async Task Base_de_una_version_anterior_se_adopta_sin_perder_datos()
    {
        // Base como la creaba la versión anterior: esquema inicial sin historial.
        await using (var db = NewContext())
        {
            await db.GetService<IMigrator>().MigrateAsync(DatabaseInitializer.BaselineMigration);
            await db.Database.ExecuteSqlRawAsync("DROP TABLE \"__EFMigrationsHistory\";");

            // Datos con las columnas de esa versión (sin las nuevas).
            await db.Database.ExecuteSqlRawAsync(
                "INSERT INTO \"Users\" (\"Name\", \"Username\", \"PasswordHash\", \"Role\", \"Active\", \"CreatedAt\") " +
                "VALUES ('Admin', 'admin', 'x', 'administrador', 1, '2026-01-01');");
            await db.Database.ExecuteSqlRawAsync(
                "INSERT INTO \"Services\" (\"Plate\", \"Vehicle\", \"VehicleType\", \"ServiceType\", \"Status\", " +
                "\"Price\", \"Date\", \"RegisteredBy\", \"EmployeeName\") " +
                "VALUES ('ABC-123', 'Kia Rio', 'Taxi', 'Balanceo', 'Terminado', 30000, '2026-01-01', 'Admin', '');");
        }

        await using (var db = NewContext())
        {
            await DatabaseInitializer.InitializeAsync(db);

            Assert.Empty(await db.Database.GetPendingMigrationsAsync());
            Assert.Equal(1, await db.Users.CountAsync());

            var service = await db.Services.SingleAsync();
            Assert.Equal("ABC-123", service.Plate);
            Assert.Null(service.CommissionPaymentId);
        }
    }
}
