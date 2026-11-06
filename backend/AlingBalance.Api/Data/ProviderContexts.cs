using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace AlingBalance.Api.Data;

// Las migraciones de Entity Framework dependen del motor de base de datos,
// así que hay un juego para SQLite (Migrations/Sqlite) y otro para SQL Server
// (Migrations/SqlServer). Cada juego pertenece a uno de estos contextos; el
// modelo es el mismo (AppDbContext).

/// <summary>Contexto para SQLite (opción por defecto).</summary>
public sealed class SqliteAppDbContext(DbContextOptions<SqliteAppDbContext> options)
    : AppDbContext(options);

/// <summary>Contexto para SQL Server.</summary>
public sealed class SqlServerAppDbContext(DbContextOptions<SqlServerAppDbContext> options)
    : AppDbContext(options);

/// <summary>Usado solo por <c>dotnet ef</c> para crear migraciones de SQLite.</summary>
public sealed class SqliteDesignTimeFactory : IDesignTimeDbContextFactory<SqliteAppDbContext>
{
    public SqliteAppDbContext CreateDbContext(string[] args) =>
        new(new DbContextOptionsBuilder<SqliteAppDbContext>()
            .UseSqlite("Data Source=alingbalance.db")
            .Options);
}

/// <summary>Usado solo por <c>dotnet ef</c> para crear migraciones de SQL Server.</summary>
public sealed class SqlServerDesignTimeFactory : IDesignTimeDbContextFactory<SqlServerAppDbContext>
{
    public SqlServerAppDbContext CreateDbContext(string[] args) =>
        new(new DbContextOptionsBuilder<SqlServerAppDbContext>()
            .UseSqlServer("Server=localhost;Database=AlingBalance;Trusted_Connection=True;TrustServerCertificate=True")
            .Options);
}
