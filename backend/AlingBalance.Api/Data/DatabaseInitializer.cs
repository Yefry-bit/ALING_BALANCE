using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Infrastructure;
using Microsoft.EntityFrameworkCore.Migrations;
using Microsoft.EntityFrameworkCore.Storage;

namespace AlingBalance.Api.Data;

/// <summary>
/// Prepara la base de datos al arrancar el servidor usando las migraciones
/// de Entity Framework (carpeta Migrations).
///
/// - Base nueva: se crea completa con las migraciones.
/// - Base creada con una versión anterior (con <c>EnsureCreated</c>, sin
///   historial de migraciones): se completa con <see cref="SchemaUpgrader"/>
///   hasta quedar igual a la migración inicial, se marca esa migración como
///   aplicada y luego se aplican las siguientes. No se pierde ningún dato.
/// - Base ya migrada: solo se aplican las migraciones pendientes.
/// </summary>
public static class DatabaseInitializer
{
    /// <summary>Migración que corresponde al esquema anterior a usar migraciones.</summary>
    public const string BaselineMigration = "InitialCreate";

    public static async Task InitializeAsync(AppDbContext db)
    {
        var creator = db.GetService<IRelationalDatabaseCreator>();
        var history = db.GetService<IHistoryRepository>();

        if (await creator.ExistsAsync()
            && await creator.HasTablesAsync()
            && !await history.ExistsAsync())
        {
            await AdoptExistingDatabaseAsync(db, history);
        }

        await db.Database.MigrateAsync();
    }

    private static async Task AdoptExistingDatabaseAsync(AppDbContext db, IHistoryRepository history)
    {
        // Agrega lo que le falte respecto a la migración inicial.
        await SchemaUpgrader.UpgradeAsync(db);

        var baseline = db.Database.GetMigrations()
            .First(id => id.EndsWith("_" + BaselineMigration, StringComparison.Ordinal));

        await db.Database.ExecuteSqlRawAsync(history.GetCreateIfNotExistsScript());
        await db.Database.ExecuteSqlRawAsync(
            history.GetInsertScript(new HistoryRow(baseline, ProductInfo.GetVersion())));
    }
}
