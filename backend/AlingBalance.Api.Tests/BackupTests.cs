using AlingBalance.Api.Services;
using Microsoft.Data.Sqlite;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.FileProviders;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging.Abstractions;
using Xunit;

namespace AlingBalance.Api.Tests;

public class BackupScheduleTests
{
    private static BackupFile At(DateTime date) => new("x.db", 1, date);

    [Fact]
    public void Sin_copias_se_hace_una_de_inmediato()
    {
        Assert.True(DatabaseBackupService.IsDue([], new DateTime(2026, 11, 5, 9, 0, 0), 22));
    }

    [Fact]
    public void Si_hoy_ya_hay_copia_no_se_repite()
    {
        var existing = new[] { At(new DateTime(2026, 11, 5, 8, 0, 0)) };

        Assert.False(DatabaseBackupService.IsDue(existing, new DateTime(2026, 11, 5, 23, 0, 0), 22));
    }

    [Fact]
    public void Espera_la_hora_configurada_si_la_ultima_es_de_ayer_reciente()
    {
        var existing = new[] { At(new DateTime(2026, 11, 4, 22, 5, 0)) };

        Assert.False(DatabaseBackupService.IsDue(existing, new DateTime(2026, 11, 5, 10, 0, 0), 22));
        Assert.True(DatabaseBackupService.IsDue(existing, new DateTime(2026, 11, 5, 22, 0, 0), 22));
    }

    [Fact]
    public void Si_el_servidor_estuvo_apagado_se_hace_al_arrancar()
    {
        var existing = new[] { At(new DateTime(2026, 11, 2, 22, 0, 0)) };

        Assert.True(DatabaseBackupService.IsDue(existing, new DateTime(2026, 11, 5, 8, 0, 0), 22));
    }
}

public sealed class BackupCopyTests : IDisposable
{
    private readonly string _folder =
        Path.Combine(Path.GetTempPath(), "ab-backup-test-" + Guid.NewGuid().ToString("N"));

    public BackupCopyTests() => Directory.CreateDirectory(_folder);

    public void Dispose()
    {
        SqliteConnection.ClearAllPools();
        Directory.Delete(_folder, recursive: true);
    }

    private sealed class TestEnvironment(string root) : IHostEnvironment
    {
        public string EnvironmentName { get; set; } = "Development";
        public string ApplicationName { get; set; } = "Tests";
        public string ContentRootPath { get; set; } = root;
        public IFileProvider ContentRootFileProvider { get; set; } = new NullFileProvider();
    }

    private DatabaseBackupService NewService(int keep) =>
        new(
            new ConfigurationBuilder()
                .AddInMemoryCollection(new Dictionary<string, string?>
                {
                    ["ConnectionStrings:Default"] = "Data Source=datos.db",
                    ["Backup:Folder"] = "copias",
                    ["Backup:Keep"] = keep.ToString(),
                })
                .Build(),
            new TestEnvironment(_folder),
            NullLogger<DatabaseBackupService>.Instance);

    [Fact]
    public async Task La_copia_tiene_los_mismos_datos_y_se_conservan_solo_las_ultimas()
    {
        await using (var db = new SqliteConnection($"Data Source={Path.Combine(_folder, "datos.db")}"))
        {
            await db.OpenAsync();
            var command = db.CreateCommand();
            command.CommandText =
                "CREATE TABLE Services (Plate TEXT); INSERT INTO Services VALUES ('ABC-123'), ('XYZ-987');";
            await command.ExecuteNonQueryAsync();
        }

        var service = NewService(keep: 2);
        var first = await service.CreateAsync();

        await using (var copy = new SqliteConnection(
            $"Data Source={Path.Combine(service.FolderPath, first.Name)};Pooling=False"))
        {
            await copy.OpenAsync();
            var count = copy.CreateCommand();
            count.CommandText = "SELECT COUNT(*) FROM Services";
            Assert.Equal(2L, await count.ExecuteScalarAsync());
        }

        // Nombres con segundos: se espera para que no coincidan.
        await Task.Delay(1100);
        await service.CreateAsync();
        await Task.Delay(1100);
        await service.CreateAsync();

        var files = service.List();
        Assert.Equal(2, files.Count);
        Assert.DoesNotContain(files, f => f.Name == first.Name);
        Assert.Empty(Directory.GetFiles(service.FolderPath, "*.tmp"));
    }
}
