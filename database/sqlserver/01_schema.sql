-- =====================================================================
-- AlingBalance - Esquema de la base de datos (SQL Server)
--
-- Generado desde las migraciones de Entity Framework Core:
--   cd backend/AlingBalance.Api
--   dotnet ef migrations script --idempotent --context SqlServerAppDbContext
--
-- Es idempotente: se puede ejecutar sobre una base nueva o ya creada y solo
-- aplica las migraciones que falten (quedan registradas en
-- "__EFMigrationsHistory"). No lo edites a mano: crea una migración nueva y
-- vuelve a generarlo.
--
-- Uso: abrir en SQL Server Management Studio / Azure Data Studio y ejecutar.
-- =====================================================================
IF DB_ID(N'AlingBalance') IS NULL
    CREATE DATABASE AlingBalance;
GO

USE AlingBalance;
GO

IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE TABLE [Clients] (
        [Id] int NOT NULL IDENTITY,
        [Name] nvarchar(80) NOT NULL,
        [Document] nvarchar(12) NOT NULL,
        [Phone] nvarchar(10) NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_Clients] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE TABLE [Employees] (
        [Id] int NOT NULL IDENTITY,
        [Name] nvarchar(80) NOT NULL,
        [Document] nvarchar(12) NOT NULL,
        [Phone] nvarchar(10) NOT NULL,
        [Active] bit NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_Employees] PRIMARY KEY ([Id])
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE TABLE [Expenses] (
        [Id] int NOT NULL IDENTITY,
        [Description] nvarchar(80) NOT NULL,
        [Category] nvarchar(40) NOT NULL,
        [Amount] int NOT NULL,
        [Date] date NOT NULL,
        [RegisteredBy] nvarchar(80) NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_Expenses] PRIMARY KEY ([Id]),
        CONSTRAINT [CK_Expenses_Amount] CHECK ([Amount] > 0)
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE TABLE [Users] (
        [Id] int NOT NULL IDENTITY,
        [Name] nvarchar(80) NOT NULL,
        [Username] nvarchar(20) NOT NULL,
        [PasswordHash] nvarchar(200) NOT NULL,
        [Role] nvarchar(20) NOT NULL,
        [Active] bit NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_Users] PRIMARY KEY ([Id]),
        CONSTRAINT [CK_Users_Role] CHECK ([Role] IN ('administrador', 'empleado'))
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE TABLE [Vehicles] (
        [Id] int NOT NULL IDENTITY,
        [ClientId] int NOT NULL,
        [Plate] nvarchar(8) NOT NULL,
        [Brand] nvarchar(30) NOT NULL,
        [Model] nvarchar(30) NOT NULL,
        [VehicleType] nvarchar(20) NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_Vehicles] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_Vehicles_Clients_ClientId] FOREIGN KEY ([ClientId]) REFERENCES [Clients] ([Id]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE TABLE [Services] (
        [Operation] int NOT NULL IDENTITY,
        [Plate] nvarchar(8) NOT NULL,
        [Vehicle] nvarchar(70) NOT NULL,
        [VehicleType] nvarchar(20) NOT NULL,
        [ServiceType] nvarchar(40) NOT NULL,
        [Status] nvarchar(20) NOT NULL,
        [Price] int NOT NULL,
        [Date] datetime2 NOT NULL,
        [FinishedAt] datetime2 NULL,
        [RegisteredBy] nvarchar(80) NOT NULL,
        [EmployeeId] int NULL,
        [EmployeeName] nvarchar(80) NOT NULL,
        CONSTRAINT [PK_Services] PRIMARY KEY ([Operation]),
        CONSTRAINT [CK_Services_Price] CHECK ([Price] > 0),
        CONSTRAINT [CK_Services_Status] CHECK ([Status] IN ('En proceso', 'Terminado')),
        CONSTRAINT [FK_Services_Employees_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [Employees] ([Id]) ON DELETE SET NULL
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE TABLE [ServicePhotos] (
        [Id] int NOT NULL IDENTITY,
        [ServiceOperation] int NOT NULL,
        [Kind] nvarchar(30) NOT NULL,
        [Note] nvarchar(200) NOT NULL,
        [ContentType] nvarchar(30) NOT NULL,
        [Data] varbinary(max) NOT NULL,
        [TakenById] int NOT NULL,
        [TakenBy] nvarchar(80) NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_ServicePhotos] PRIMARY KEY ([Id]),
        CONSTRAINT [FK_ServicePhotos_Services_ServiceOperation] FOREIGN KEY ([ServiceOperation]) REFERENCES [Services] ([Operation]) ON DELETE CASCADE
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Clients_Document] ON [Clients] ([Document]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Employees_Document] ON [Employees] ([Document]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Expenses_Date] ON [Expenses] ([Date]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_ServicePhotos_ServiceOperation] ON [ServicePhotos] ([ServiceOperation]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Services_EmployeeId] ON [Services] ([EmployeeId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Services_Plate] ON [Services] ([Plate]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Services_Status] ON [Services] ([Status]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Users_Username] ON [Users] ([Username]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE INDEX [IX_Vehicles_ClientId] ON [Vehicles] ([ClientId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    CREATE UNIQUE INDEX [IX_Vehicles_Plate] ON [Vehicles] ([Plate]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105230705_InitialCreate'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261105230705_InitialCreate', N'10.0.14');
END;

COMMIT;
GO

BEGIN TRANSACTION;
IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105232005_ComisionesGastosFijosYSesiones'
)
BEGIN
    ALTER TABLE [Users] ADD [SecurityStamp] nvarchar(40) NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105232005_ComisionesGastosFijosYSesiones'
)
BEGIN
    ALTER TABLE [Services] ADD [CommissionPaymentId] int NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105232005_ComisionesGastosFijosYSesiones'
)
BEGIN
    ALTER TABLE [Expenses] ADD [RecurringExpenseId] int NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105232005_ComisionesGastosFijosYSesiones'
)
BEGIN
    CREATE TABLE [CommissionPayments] (
        [Id] int NOT NULL IDENTITY,
        [EmployeeId] int NULL,
        [EmployeeName] nvarchar(80) NOT NULL,
        [Year] int NOT NULL,
        [Month] int NOT NULL,
        [Amount] int NOT NULL,
        [ServiceCount] int NOT NULL,
        [PaidAt] datetime2 NOT NULL,
        [PaidBy] nvarchar(80) NOT NULL,
        CONSTRAINT [PK_CommissionPayments] PRIMARY KEY ([Id]),
        CONSTRAINT [CK_CommissionPayments_Amount] CHECK ([Amount] >= 0),
        CONSTRAINT [CK_CommissionPayments_Month] CHECK ([Month] BETWEEN 1 AND 12),
        CONSTRAINT [FK_CommissionPayments_Employees_EmployeeId] FOREIGN KEY ([EmployeeId]) REFERENCES [Employees] ([Id]) ON DELETE SET NULL
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105232005_ComisionesGastosFijosYSesiones'
)
BEGIN
    CREATE TABLE [RecurringExpenses] (
        [Id] int NOT NULL IDENTITY,
        [Description] nvarchar(80) NOT NULL,
        [Category] nvarchar(40) NOT NULL,
        [Amount] int NOT NULL,
        [DayOfMonth] int NOT NULL,
        [Active] bit NOT NULL,
        [LastGeneratedMonth] int NOT NULL,
        [RegisteredBy] nvarchar(80) NOT NULL,
        [CreatedAt] datetime2 NOT NULL,
        CONSTRAINT [PK_RecurringExpenses] PRIMARY KEY ([Id]),
        CONSTRAINT [CK_RecurringExpenses_Amount] CHECK ([Amount] > 0),
        CONSTRAINT [CK_RecurringExpenses_Day] CHECK ([DayOfMonth] BETWEEN 1 AND 28)
    );
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105232005_ComisionesGastosFijosYSesiones'
)
BEGIN
    CREATE INDEX [IX_Services_CommissionPaymentId] ON [Services] ([CommissionPaymentId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105232005_ComisionesGastosFijosYSesiones'
)
BEGIN
    EXEC(N'CREATE UNIQUE INDEX [IX_Expenses_RecurringExpenseId_Date] ON [Expenses] ([RecurringExpenseId], [Date]) WHERE [RecurringExpenseId] IS NOT NULL');
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105232005_ComisionesGastosFijosYSesiones'
)
BEGIN
    CREATE INDEX [IX_CommissionPayments_EmployeeId] ON [CommissionPayments] ([EmployeeId]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105232005_ComisionesGastosFijosYSesiones'
)
BEGIN
    CREATE INDEX [IX_CommissionPayments_Year_Month] ON [CommissionPayments] ([Year], [Month]);
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105232005_ComisionesGastosFijosYSesiones'
)
BEGIN
    ALTER TABLE [Expenses] ADD CONSTRAINT [FK_Expenses_RecurringExpenses_RecurringExpenseId] FOREIGN KEY ([RecurringExpenseId]) REFERENCES [RecurringExpenses] ([Id]) ON DELETE SET NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105232005_ComisionesGastosFijosYSesiones'
)
BEGIN
    ALTER TABLE [Services] ADD CONSTRAINT [FK_Services_CommissionPayments_CommissionPaymentId] FOREIGN KEY ([CommissionPaymentId]) REFERENCES [CommissionPayments] ([Id]) ON DELETE SET NULL;
END;

IF NOT EXISTS (
    SELECT * FROM [__EFMigrationsHistory]
    WHERE [MigrationId] = N'20261105232005_ComisionesGastosFijosYSesiones'
)
BEGIN
    INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
    VALUES (N'20261105232005_ComisionesGastosFijosYSesiones', N'10.0.14');
END;

COMMIT;
GO

-- Administrador inicial: admin / admin123 (cámbiala al entrar en
-- "Cambiar contraseña"). No se agrega si ya existe.
IF NOT EXISTS (SELECT 1 FROM dbo.Users WHERE Username = N'admin')
    INSERT INTO dbo.Users ([Name], Username, PasswordHash, [Role], Active, CreatedAt)
    VALUES (N'Administrador', N'admin', N'210000.Gdye3eeXrCd/GQpDdx7GiQ==.G0oh9o/nFJRYhqIhNmOYq3gJfSuZV8Lfuj2bxt5ZFjY=', N'administrador', 1, SYSUTCDATETIME());
GO
