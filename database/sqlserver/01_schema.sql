-- =====================================================================
-- AlingBalance - Esquema de la base de datos (SQL Server)
-- Es el mismo esquema que crea Entity Framework Core automáticamente.
-- Uso: abrir en SQL Server Management Studio / Azure Data Studio y ejecutar.
-- =====================================================================
IF DB_ID(N'AlingBalance') IS NULL
    CREATE DATABASE AlingBalance;
GO

USE AlingBalance;
GO

CREATE TABLE dbo.Users (
    Id           INT IDENTITY(1,1) NOT NULL,
    [Name]       NVARCHAR(80)  NOT NULL,             -- nombre completo (3-80)
    Username     NVARCHAR(20)  NOT NULL,             -- usuario en minúsculas (4-20), único
    PasswordHash NVARCHAR(200) NOT NULL,             -- PBKDF2-SHA256: iteraciones.sal.hash
    [Role]       NVARCHAR(20)  NOT NULL,             -- 'administrador' | 'empleado'
    Active       BIT           NOT NULL,
    CreatedAt    DATETIME2     NOT NULL,
    CONSTRAINT PK_Users PRIMARY KEY (Id),
    CONSTRAINT CK_Users_Role CHECK ([Role] IN (N'administrador', N'empleado'))
);
GO

CREATE TABLE dbo.Employees (
    Id         INT IDENTITY(1,1) NOT NULL,
    [Name]     NVARCHAR(80) NOT NULL,                -- nombre completo (3-80)
    Document   NVARCHAR(12) NOT NULL,                -- identificación (5-12 dígitos), única
    Phone      NVARCHAR(10) NOT NULL,                -- opcional ('' si no hay)
    Active     BIT          NOT NULL,
    CreatedAt  DATETIME2    NOT NULL,
    CONSTRAINT PK_Employees PRIMARY KEY (Id)
);
GO

CREATE TABLE dbo.Services (
    Operation    INT IDENTITY(1,1) NOT NULL,         -- número de operación
    Plate        NVARCHAR(8)  NOT NULL,              -- ABC-123
    Vehicle      NVARCHAR(70) NOT NULL,              -- marca y modelo
    VehicleType  NVARCHAR(20) NOT NULL,              -- Particular | Taxi | Camioneta
    ServiceType  NVARCHAR(40) NOT NULL,              -- servicio del catálogo
    [Status]     NVARCHAR(20) NOT NULL,              -- 'En proceso' | 'Terminado'
    Price        INT          NOT NULL,               -- pesos colombianos (> 0)
    [Date]       DATETIME2    NOT NULL,               -- UTC, hora de ingreso
    FinishedAt   DATETIME2    NULL,                   -- UTC, hora en que se terminó
    RegisteredBy NVARCHAR(80) NOT NULL,               -- quién lo registró
    EmployeeId   INT          NULL,                   -- quién hizo el trabajo
    EmployeeName NVARCHAR(80) NOT NULL,               -- nombre al registrar
    CONSTRAINT PK_Services PRIMARY KEY (Operation),
    CONSTRAINT CK_Services_Price  CHECK (Price > 0),
    CONSTRAINT CK_Services_Status CHECK ([Status] IN (N'En proceso', N'Terminado')),
    CONSTRAINT FK_Services_Employees_EmployeeId FOREIGN KEY (EmployeeId)
        REFERENCES dbo.Employees (Id) ON DELETE SET NULL
);
GO

CREATE TABLE dbo.Clients (
    Id         INT IDENTITY(1,1) NOT NULL,
    [Name]     NVARCHAR(80) NOT NULL,                -- nombre completo (3-80)
    Document   NVARCHAR(12) NOT NULL,                -- identificación (5-12 dígitos), única
    Phone      NVARCHAR(10) NOT NULL,                -- opcional ('' si no hay)
    CreatedAt  DATETIME2    NOT NULL,
    CONSTRAINT PK_Clients PRIMARY KEY (Id)
);
GO

-- Un cliente puede tener varios vehículos; una placa pertenece a un solo cliente.
CREATE TABLE dbo.Vehicles (
    Id          INT IDENTITY(1,1) NOT NULL,
    ClientId    INT          NOT NULL,
    Plate       NVARCHAR(8)  NOT NULL,               -- ABC-123, única
    Brand       NVARCHAR(30) NOT NULL,
    Model       NVARCHAR(30) NOT NULL,
    VehicleType NVARCHAR(20) NOT NULL,
    CreatedAt   DATETIME2    NOT NULL,
    CONSTRAINT PK_Vehicles PRIMARY KEY (Id),
    CONSTRAINT FK_Vehicles_Clients_ClientId FOREIGN KEY (ClientId)
        REFERENCES dbo.Clients (Id) ON DELETE CASCADE
);
GO

CREATE TABLE dbo.Expenses (
    Id            INT IDENTITY(1,1) NOT NULL,
    [Description] NVARCHAR(80) NOT NULL,
    Category      NVARCHAR(40) NOT NULL,
    Amount        INT          NOT NULL,             -- pesos colombianos (> 0)
    [Date]        DATE         NOT NULL,             -- día del gasto
    RegisteredBy  NVARCHAR(80) NOT NULL,
    CreatedAt     DATETIME2    NOT NULL,
    CONSTRAINT PK_Expenses PRIMARY KEY (Id),
    CONSTRAINT CK_Expenses_Amount CHECK (Amount > 0)
);
GO

CREATE TABLE dbo.ServicePhotos (
    Id               INT IDENTITY(1,1) NOT NULL,
    ServiceOperation INT            NOT NULL,        -- servicio al que pertenece
    Kind             NVARCHAR(30)   NOT NULL,        -- Vehículo | Máquina / equipo | Falla o daño | Pieza faltante
    Note             NVARCHAR(200)  NOT NULL,
    ContentType      NVARCHAR(30)   NOT NULL,        -- image/jpeg | image/png | image/webp
    Data             VARBINARY(MAX) NOT NULL,        -- la imagen (máx. 5 MB)
    TakenById        INT            NOT NULL,
    TakenBy          NVARCHAR(80)   NOT NULL,
    CreatedAt        DATETIME2      NOT NULL,
    CONSTRAINT PK_ServicePhotos PRIMARY KEY (Id),
    CONSTRAINT FK_ServicePhotos_Services_ServiceOperation FOREIGN KEY (ServiceOperation)
        REFERENCES dbo.Services (Operation) ON DELETE CASCADE
);
GO

CREATE UNIQUE INDEX IX_Users_Username     ON dbo.Users (Username);
CREATE UNIQUE INDEX IX_Employees_Document ON dbo.Employees (Document);
CREATE INDEX IX_Services_EmployeeId ON dbo.Services (EmployeeId);
CREATE INDEX IX_Services_Plate      ON dbo.Services (Plate);
CREATE INDEX IX_Services_Status     ON dbo.Services ([Status]);
CREATE UNIQUE INDEX IX_Clients_Document ON dbo.Clients (Document);
CREATE INDEX IX_Vehicles_ClientId       ON dbo.Vehicles (ClientId);
CREATE UNIQUE INDEX IX_Vehicles_Plate   ON dbo.Vehicles (Plate);
CREATE INDEX IX_Expenses_Date           ON dbo.Expenses ([Date]);
CREATE INDEX IX_ServicePhotos_ServiceOperation ON dbo.ServicePhotos (ServiceOperation);
GO

-- Administrador inicial: usuario admin / contraseña admin123  (¡cámbiala!)
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = N'admin')
    INSERT INTO dbo.Users ([Name], Username, PasswordHash, [Role], Active, CreatedAt)
    VALUES (N'Administrador', N'admin', N'210000.UCqeQ0CfI4f7koKJRPxVsA==.a65PBQMaLPP+F3zuhuK/9g5Ak7s4KrNwVgsdPzjDfvM=', N'administrador', 1, SYSUTCDATETIME());
GO
