using Microsoft.EntityFrameworkCore;

namespace AlingBalance.Api.Data;

/// <summary>
/// Puente para bases creadas <b>antes de usar migraciones</b> (con
/// <c>EnsureCreated</c>): les agrega lo que se creó después de la primera
/// versión (Clientes, Vehículos, Gastos, Fotos y la hora de finalización)
/// para que queden iguales a la migración <c>InitialCreate</c>.
///
/// Solo lo usa <see cref="DatabaseInitializer"/> una vez por base; después,
/// los cambios de esquema se hacen con migraciones (carpeta Migrations).
/// No agregues aquí cambios nuevos: crea una migración.
/// </summary>
public static class SchemaUpgrader
{
    public static async Task UpgradeAsync(AppDbContext db)
    {
        var isSqlServer = db.Database.IsSqlServer();
        var statements = isSqlServer ? SqlServer : Sqlite;

        foreach (var sql in statements)
        {
            await db.Database.ExecuteSqlRawAsync(sql);
        }

        // Columna nueva en una tabla existente: hora en que se terminó el servicio.
        if (isSqlServer)
        {
            await db.Database.ExecuteSqlRawAsync(
                "IF COL_LENGTH(N'dbo.Services', N'FinishedAt') IS NULL " +
                "ALTER TABLE dbo.Services ADD FinishedAt DATETIME2 NULL;");
        }
        else
        {
            var exists = await db.Database
                .SqlQueryRaw<int>(
                    "SELECT COUNT(*) AS \"Value\" FROM pragma_table_info('Services') " +
                    "WHERE name = 'FinishedAt'")
                .SingleAsync();

            if (exists == 0)
            {
                await db.Database.ExecuteSqlRawAsync(
                    "ALTER TABLE \"Services\" ADD COLUMN \"FinishedAt\" TEXT NULL;");
            }
        }
    }

    private static readonly string[] Sqlite =
    {
        """
        CREATE TABLE IF NOT EXISTS "Clients" (
            "Id"        INTEGER NOT NULL CONSTRAINT "PK_Clients" PRIMARY KEY AUTOINCREMENT,
            "Name"      TEXT    NOT NULL,
            "Document"  TEXT    NOT NULL,
            "Phone"     TEXT    NOT NULL,
            "CreatedAt" TEXT    NOT NULL
        );
        """,
        """CREATE UNIQUE INDEX IF NOT EXISTS "IX_Clients_Document" ON "Clients" ("Document");""",
        """
        CREATE TABLE IF NOT EXISTS "Vehicles" (
            "Id"          INTEGER NOT NULL CONSTRAINT "PK_Vehicles" PRIMARY KEY AUTOINCREMENT,
            "ClientId"    INTEGER NOT NULL,
            "Plate"       TEXT    NOT NULL,
            "Brand"       TEXT    NOT NULL,
            "Model"       TEXT    NOT NULL,
            "VehicleType" TEXT    NOT NULL,
            "CreatedAt"   TEXT    NOT NULL,
            CONSTRAINT "FK_Vehicles_Clients_ClientId" FOREIGN KEY ("ClientId")
                REFERENCES "Clients" ("Id") ON DELETE CASCADE
        );
        """,
        """CREATE INDEX IF NOT EXISTS "IX_Vehicles_ClientId" ON "Vehicles" ("ClientId");""",
        """CREATE UNIQUE INDEX IF NOT EXISTS "IX_Vehicles_Plate" ON "Vehicles" ("Plate");""",
        """
        CREATE TABLE IF NOT EXISTS "Expenses" (
            "Id"           INTEGER NOT NULL CONSTRAINT "PK_Expenses" PRIMARY KEY AUTOINCREMENT,
            "Description"  TEXT    NOT NULL,
            "Category"     TEXT    NOT NULL,
            "Amount"       INTEGER NOT NULL,
            "Date"         TEXT    NOT NULL,
            "RegisteredBy" TEXT    NOT NULL,
            "CreatedAt"    TEXT    NOT NULL,
            CONSTRAINT "CK_Expenses_Amount" CHECK ("Amount" > 0)
        );
        """,
        """CREATE INDEX IF NOT EXISTS "IX_Expenses_Date" ON "Expenses" ("Date");""",
        """
        CREATE TABLE IF NOT EXISTS "ServicePhotos" (
            "Id"               INTEGER NOT NULL CONSTRAINT "PK_ServicePhotos" PRIMARY KEY AUTOINCREMENT,
            "ServiceOperation" INTEGER NOT NULL,
            "Kind"             TEXT    NOT NULL,
            "Note"             TEXT    NOT NULL,
            "ContentType"      TEXT    NOT NULL,
            "Data"             BLOB    NOT NULL,
            "TakenById"        INTEGER NOT NULL,
            "TakenBy"          TEXT    NOT NULL,
            "CreatedAt"        TEXT    NOT NULL,
            CONSTRAINT "FK_ServicePhotos_Services_ServiceOperation" FOREIGN KEY ("ServiceOperation")
                REFERENCES "Services" ("Operation") ON DELETE CASCADE
        );
        """,
        """CREATE INDEX IF NOT EXISTS "IX_ServicePhotos_ServiceOperation" ON "ServicePhotos" ("ServiceOperation");""",
    };

    private static readonly string[] SqlServer =
    {
        """
        IF OBJECT_ID(N'dbo.Clients', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.Clients (
                Id        INT IDENTITY(1,1) NOT NULL,
                [Name]    NVARCHAR(80) NOT NULL,
                Document  NVARCHAR(12) NOT NULL,
                Phone     NVARCHAR(10) NOT NULL,
                CreatedAt DATETIME2    NOT NULL,
                CONSTRAINT PK_Clients PRIMARY KEY (Id)
            );
            CREATE UNIQUE INDEX IX_Clients_Document ON dbo.Clients (Document);
        END
        """,
        """
        IF OBJECT_ID(N'dbo.Vehicles', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.Vehicles (
                Id          INT IDENTITY(1,1) NOT NULL,
                ClientId    INT          NOT NULL,
                Plate       NVARCHAR(8)  NOT NULL,
                Brand       NVARCHAR(30) NOT NULL,
                Model       NVARCHAR(30) NOT NULL,
                VehicleType NVARCHAR(20) NOT NULL,
                CreatedAt   DATETIME2    NOT NULL,
                CONSTRAINT PK_Vehicles PRIMARY KEY (Id),
                CONSTRAINT FK_Vehicles_Clients_ClientId FOREIGN KEY (ClientId)
                    REFERENCES dbo.Clients (Id) ON DELETE CASCADE
            );
            CREATE INDEX IX_Vehicles_ClientId ON dbo.Vehicles (ClientId);
            CREATE UNIQUE INDEX IX_Vehicles_Plate ON dbo.Vehicles (Plate);
        END
        """,
        """
        IF OBJECT_ID(N'dbo.Expenses', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.Expenses (
                Id           INT IDENTITY(1,1) NOT NULL,
                [Description] NVARCHAR(80) NOT NULL,
                Category     NVARCHAR(40) NOT NULL,
                Amount       INT          NOT NULL,
                [Date]       DATE         NOT NULL,
                RegisteredBy NVARCHAR(80) NOT NULL,
                CreatedAt    DATETIME2    NOT NULL,
                CONSTRAINT PK_Expenses PRIMARY KEY (Id),
                CONSTRAINT CK_Expenses_Amount CHECK (Amount > 0)
            );
            CREATE INDEX IX_Expenses_Date ON dbo.Expenses ([Date]);
        END
        """,
        """
        IF OBJECT_ID(N'dbo.ServicePhotos', N'U') IS NULL
        BEGIN
            CREATE TABLE dbo.ServicePhotos (
                Id               INT IDENTITY(1,1) NOT NULL,
                ServiceOperation INT            NOT NULL,
                Kind             NVARCHAR(30)   NOT NULL,
                Note             NVARCHAR(200)  NOT NULL,
                ContentType      NVARCHAR(30)   NOT NULL,
                Data             VARBINARY(MAX) NOT NULL,
                TakenById        INT            NOT NULL,
                TakenBy          NVARCHAR(80)   NOT NULL,
                CreatedAt        DATETIME2      NOT NULL,
                CONSTRAINT PK_ServicePhotos PRIMARY KEY (Id),
                CONSTRAINT FK_ServicePhotos_Services_ServiceOperation FOREIGN KEY (ServiceOperation)
                    REFERENCES dbo.Services (Operation) ON DELETE CASCADE
            );
            CREATE INDEX IX_ServicePhotos_ServiceOperation ON dbo.ServicePhotos (ServiceOperation);
        END
        """,
    };
}
