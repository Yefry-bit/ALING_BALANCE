using System.Globalization;
using Microsoft.Data.Sqlite;

namespace AlingBalance.Api.Services;

/// <summary>Configuración de las copias (sección "Backup" de appsettings).</summary>
public sealed class BackupOptions
{
    public bool Enabled { get; set; } = true;

    /// <summary>
    /// Carpeta de las copias. Relativa a la carpeta del servidor o absoluta.
    /// Si es una carpeta de OneDrive / Google Drive, las copias suben solas a
    /// la nube.
    /// </summary>
    public string Folder { get; set; } = "backups";

    /// <summary>Hora local (0-23) desde la que se hace la copia del día.</summary>
    public int Hour { get; set; } = 22;

    /// <summary>Cuántas copias conservar (las más antiguas se borran).</summary>
    public int Keep { get; set; } = 30;
}

/// <summary>Una copia de seguridad guardada.</summary>
public sealed record BackupFile(string Name, long SizeBytes, DateTime CreatedAt);

/// <summary>
/// Copias de seguridad de la base SQLite: una al día (desde la hora
/// configurada, o en cuanto arranca el servidor si la última tiene más de un
/// día) y a pedido del administrador. Usa la copia en caliente de SQLite, así
/// es segura aunque la app esté registrando datos en ese momento.
/// </summary>
public sealed class DatabaseBackupService(
    IConfiguration configuration,
    IHostEnvironment environment,
    ILogger<DatabaseBackupService> logger) : BackgroundService
{
    private const string Prefix = "alingbalance-";
    private static readonly TimeSpan CheckEvery = TimeSpan.FromMinutes(30);

    private readonly BackupOptions _options =
        configuration.GetSection("Backup").Get<BackupOptions>() ?? new BackupOptions();

    private readonly SemaphoreSlim _lock = new(1, 1);

    /// <summary>Las copias solo aplican a SQLite (SQL Server tiene las suyas).</summary>
    public bool Available =>
        _options.Enabled
        && !string.Equals(configuration["Database:Provider"], "SqlServer", StringComparison.OrdinalIgnoreCase);

    public string FolderPath => Path.GetFullPath(
        Path.IsPathRooted(_options.Folder)
            ? _options.Folder
            : Path.Combine(environment.ContentRootPath, _options.Folder));

    public int Keep => Math.Max(1, _options.Keep);

    protected override async Task ExecuteAsync(CancellationToken stoppingToken)
    {
        if (!Available)
        {
            logger.LogInformation("Copias automáticas desactivadas (o la base no es SQLite).");
            return;
        }

        logger.LogInformation("Copias de seguridad diarias en {Folder}", FolderPath);

        while (!stoppingToken.IsCancellationRequested)
        {
            try
            {
                if (IsDue(List(), DateTime.Now, _options.Hour))
                {
                    var file = await CreateAsync(stoppingToken);
                    logger.LogInformation("Copia de seguridad creada: {Name}", file.Name);
                }
            }
            catch (Exception error) when (error is not OperationCanceledException)
            {
                // Sin espacio, carpeta sin permisos…: se reintenta más tarde.
                logger.LogError(error, "No se pudo crear la copia de seguridad.");
            }

            try
            {
                await Task.Delay(CheckEvery, stoppingToken);
            }
            catch (OperationCanceledException)
            {
                return;
            }
        }
    }

    /// <summary>
    /// Toca copia si hoy no hay una y ya es la hora configurada, o si la
    /// última tiene más de un día (el servidor estuvo apagado a esa hora).
    /// </summary>
    public static bool IsDue(IReadOnlyList<BackupFile> existing, DateTime now, int hour)
    {
        if (existing.Count == 0) return true;

        var latest = existing.Max(b => b.CreatedAt);
        if (latest.Date == now.Date) return false;

        return now.Hour >= hour || now - latest > TimeSpan.FromDays(1);
    }

    /// <summary>Copias guardadas, de la más reciente a la más antigua.</summary>
    public IReadOnlyList<BackupFile> List()
    {
        if (!Directory.Exists(FolderPath)) return Array.Empty<BackupFile>();

        return new DirectoryInfo(FolderPath)
            .GetFiles(Prefix + "*.db")
            .Select(f => new BackupFile(f.Name, f.Length, f.LastWriteTime))
            .OrderByDescending(b => b.CreatedAt)
            .ToList();
    }

    /// <summary>Hace una copia ahora y borra las que sobren.</summary>
    public async Task<BackupFile> CreateAsync(CancellationToken cancellationToken = default)
    {
        if (!Available)
        {
            throw new InvalidOperationException("Las copias solo están disponibles con SQLite.");
        }

        await _lock.WaitAsync(cancellationToken);
        try
        {
            Directory.CreateDirectory(FolderPath);

            var stamp = DateTime.Now.ToString("yyyy-MM-dd_HHmmss", CultureInfo.InvariantCulture);
            var target = Path.Combine(FolderPath, $"{Prefix}{stamp}.db");
            var temporary = target + ".tmp";

            var source = new SqliteConnectionStringBuilder(
                configuration.GetConnectionString("Default") ?? "Data Source=alingbalance.db");
            if (!Path.IsPathRooted(source.DataSource))
            {
                source.DataSource = Path.Combine(environment.ContentRootPath, source.DataSource);
            }

            // Copia en caliente: consistente aunque haya escrituras en curso.
            await using (var from = new SqliteConnection(source.ToString()))
            await using (var to = new SqliteConnection(
                new SqliteConnectionStringBuilder { DataSource = temporary, Pooling = false }.ToString()))
            {
                await from.OpenAsync(cancellationToken);
                await to.OpenAsync(cancellationToken);
                from.BackupDatabase(to);
            }

            // Solo queda con el nombre final si la copia terminó completa.
            File.Move(temporary, target, overwrite: true);

            foreach (var old in List().Skip(Keep))
            {
                File.Delete(Path.Combine(FolderPath, old.Name));
            }

            var info = new FileInfo(target);
            return new BackupFile(info.Name, info.Length, info.LastWriteTime);
        }
        finally
        {
            _lock.Release();
        }
    }
}
