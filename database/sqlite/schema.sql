-- =====================================================================
-- AlingBalance - Esquema de la base de datos (SQLite)
--
-- Generado desde las migraciones de Entity Framework Core:
--   cd backend/AlingBalance.Api
--   dotnet ef migrations script --context SqliteAppDbContext -o ../../database/sqlite/schema.sql
--
-- Incluye la tabla "__EFMigrationsHistory" con las migraciones aplicadas,
-- así el servidor reconoce la base y solo aplica las migraciones nuevas.
-- No lo edites a mano: crea una migración nueva y vuelve a generarlo.
--
-- Uso:  sqlite3 alingbalance.db < schema.sql
-- =====================================================================

CREATE TABLE IF NOT EXISTS "__EFMigrationsHistory" (
    "MigrationId" TEXT NOT NULL CONSTRAINT "PK___EFMigrationsHistory" PRIMARY KEY,
    "ProductVersion" TEXT NOT NULL
);

BEGIN TRANSACTION;
CREATE TABLE "Clients" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Clients" PRIMARY KEY AUTOINCREMENT,
    "Name" TEXT NOT NULL,
    "Document" TEXT NOT NULL,
    "Phone" TEXT NOT NULL,
    "CreatedAt" TEXT NOT NULL
);

CREATE TABLE "Employees" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Employees" PRIMARY KEY AUTOINCREMENT,
    "Name" TEXT NOT NULL,
    "Document" TEXT NOT NULL,
    "Phone" TEXT NOT NULL,
    "Active" INTEGER NOT NULL,
    "CreatedAt" TEXT NOT NULL
);

CREATE TABLE "Expenses" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Expenses" PRIMARY KEY AUTOINCREMENT,
    "Description" TEXT NOT NULL,
    "Category" TEXT NOT NULL,
    "Amount" INTEGER NOT NULL,
    "Date" TEXT NOT NULL,
    "RegisteredBy" TEXT NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    CONSTRAINT "CK_Expenses_Amount" CHECK ([Amount] > 0)
);

CREATE TABLE "Users" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Users" PRIMARY KEY AUTOINCREMENT,
    "Name" TEXT NOT NULL,
    "Username" TEXT NOT NULL,
    "PasswordHash" TEXT NOT NULL,
    "Role" TEXT NOT NULL,
    "Active" INTEGER NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    CONSTRAINT "CK_Users_Role" CHECK ([Role] IN ('administrador', 'empleado'))
);

CREATE TABLE "Vehicles" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Vehicles" PRIMARY KEY AUTOINCREMENT,
    "ClientId" INTEGER NOT NULL,
    "Plate" TEXT NOT NULL,
    "Brand" TEXT NOT NULL,
    "Model" TEXT NOT NULL,
    "VehicleType" TEXT NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    CONSTRAINT "FK_Vehicles_Clients_ClientId" FOREIGN KEY ("ClientId") REFERENCES "Clients" ("Id") ON DELETE CASCADE
);

CREATE TABLE "Services" (
    "Operation" INTEGER NOT NULL CONSTRAINT "PK_Services" PRIMARY KEY AUTOINCREMENT,
    "Plate" TEXT NOT NULL,
    "Vehicle" TEXT NOT NULL,
    "VehicleType" TEXT NOT NULL,
    "ServiceType" TEXT NOT NULL,
    "Status" TEXT NOT NULL,
    "Price" INTEGER NOT NULL,
    "Date" TEXT NOT NULL,
    "FinishedAt" TEXT NULL,
    "RegisteredBy" TEXT NOT NULL,
    "EmployeeId" INTEGER NULL,
    "EmployeeName" TEXT NOT NULL,
    CONSTRAINT "CK_Services_Price" CHECK ([Price] > 0),
    CONSTRAINT "CK_Services_Status" CHECK ([Status] IN ('En proceso', 'Terminado')),
    CONSTRAINT "FK_Services_Employees_EmployeeId" FOREIGN KEY ("EmployeeId") REFERENCES "Employees" ("Id") ON DELETE SET NULL
);

CREATE TABLE "ServicePhotos" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_ServicePhotos" PRIMARY KEY AUTOINCREMENT,
    "ServiceOperation" INTEGER NOT NULL,
    "Kind" TEXT NOT NULL,
    "Note" TEXT NOT NULL,
    "ContentType" TEXT NOT NULL,
    "Data" BLOB NOT NULL,
    "TakenById" INTEGER NOT NULL,
    "TakenBy" TEXT NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    CONSTRAINT "FK_ServicePhotos_Services_ServiceOperation" FOREIGN KEY ("ServiceOperation") REFERENCES "Services" ("Operation") ON DELETE CASCADE
);

CREATE UNIQUE INDEX "IX_Clients_Document" ON "Clients" ("Document");

CREATE UNIQUE INDEX "IX_Employees_Document" ON "Employees" ("Document");

CREATE INDEX "IX_Expenses_Date" ON "Expenses" ("Date");

CREATE INDEX "IX_ServicePhotos_ServiceOperation" ON "ServicePhotos" ("ServiceOperation");

CREATE INDEX "IX_Services_EmployeeId" ON "Services" ("EmployeeId");

CREATE INDEX "IX_Services_Plate" ON "Services" ("Plate");

CREATE INDEX "IX_Services_Status" ON "Services" ("Status");

CREATE UNIQUE INDEX "IX_Users_Username" ON "Users" ("Username");

CREATE INDEX "IX_Vehicles_ClientId" ON "Vehicles" ("ClientId");

CREATE UNIQUE INDEX "IX_Vehicles_Plate" ON "Vehicles" ("Plate");

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20261105230647_InitialCreate', '10.0.14');

COMMIT;

BEGIN TRANSACTION;
ALTER TABLE "Users" ADD "SecurityStamp" TEXT NULL;

ALTER TABLE "Services" ADD "CommissionPaymentId" INTEGER NULL;

ALTER TABLE "Expenses" ADD "RecurringExpenseId" INTEGER NULL;

CREATE TABLE "CommissionPayments" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_CommissionPayments" PRIMARY KEY AUTOINCREMENT,
    "EmployeeId" INTEGER NULL,
    "EmployeeName" TEXT NOT NULL,
    "Year" INTEGER NOT NULL,
    "Month" INTEGER NOT NULL,
    "Amount" INTEGER NOT NULL,
    "ServiceCount" INTEGER NOT NULL,
    "PaidAt" TEXT NOT NULL,
    "PaidBy" TEXT NOT NULL,
    CONSTRAINT "CK_CommissionPayments_Amount" CHECK ([Amount] >= 0),
    CONSTRAINT "CK_CommissionPayments_Month" CHECK ([Month] BETWEEN 1 AND 12),
    CONSTRAINT "FK_CommissionPayments_Employees_EmployeeId" FOREIGN KEY ("EmployeeId") REFERENCES "Employees" ("Id") ON DELETE SET NULL
);

CREATE TABLE "RecurringExpenses" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_RecurringExpenses" PRIMARY KEY AUTOINCREMENT,
    "Description" TEXT NOT NULL,
    "Category" TEXT NOT NULL,
    "Amount" INTEGER NOT NULL,
    "DayOfMonth" INTEGER NOT NULL,
    "Active" INTEGER NOT NULL,
    "LastGeneratedMonth" INTEGER NOT NULL,
    "RegisteredBy" TEXT NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    CONSTRAINT "CK_RecurringExpenses_Amount" CHECK ([Amount] > 0),
    CONSTRAINT "CK_RecurringExpenses_Day" CHECK ([DayOfMonth] BETWEEN 1 AND 28)
);

CREATE INDEX "IX_Services_CommissionPaymentId" ON "Services" ("CommissionPaymentId");

CREATE UNIQUE INDEX "IX_Expenses_RecurringExpenseId_Date" ON "Expenses" ("RecurringExpenseId", "Date") WHERE [RecurringExpenseId] IS NOT NULL;

CREATE INDEX "IX_CommissionPayments_EmployeeId" ON "CommissionPayments" ("EmployeeId");

CREATE INDEX "IX_CommissionPayments_Year_Month" ON "CommissionPayments" ("Year", "Month");

CREATE TABLE "ef_temp_Expenses" (
    "Id" INTEGER NOT NULL CONSTRAINT "PK_Expenses" PRIMARY KEY AUTOINCREMENT,
    "Amount" INTEGER NOT NULL,
    "Category" TEXT NOT NULL,
    "CreatedAt" TEXT NOT NULL,
    "Date" TEXT NOT NULL,
    "Description" TEXT NOT NULL,
    "RecurringExpenseId" INTEGER NULL,
    "RegisteredBy" TEXT NOT NULL,
    CONSTRAINT "CK_Expenses_Amount" CHECK ([Amount] > 0),
    CONSTRAINT "FK_Expenses_RecurringExpenses_RecurringExpenseId" FOREIGN KEY ("RecurringExpenseId") REFERENCES "RecurringExpenses" ("Id") ON DELETE SET NULL
);

INSERT INTO "ef_temp_Expenses" ("Id", "Amount", "Category", "CreatedAt", "Date", "Description", "RecurringExpenseId", "RegisteredBy")
SELECT "Id", "Amount", "Category", "CreatedAt", "Date", "Description", "RecurringExpenseId", "RegisteredBy"
FROM "Expenses";

CREATE TABLE "ef_temp_Services" (
    "Operation" INTEGER NOT NULL CONSTRAINT "PK_Services" PRIMARY KEY AUTOINCREMENT,
    "CommissionPaymentId" INTEGER NULL,
    "Date" TEXT NOT NULL,
    "EmployeeId" INTEGER NULL,
    "EmployeeName" TEXT NOT NULL,
    "FinishedAt" TEXT NULL,
    "Plate" TEXT NOT NULL,
    "Price" INTEGER NOT NULL,
    "RegisteredBy" TEXT NOT NULL,
    "ServiceType" TEXT NOT NULL,
    "Status" TEXT NOT NULL,
    "Vehicle" TEXT NOT NULL,
    "VehicleType" TEXT NOT NULL,
    CONSTRAINT "CK_Services_Price" CHECK ([Price] > 0),
    CONSTRAINT "CK_Services_Status" CHECK ([Status] IN ('En proceso', 'Terminado')),
    CONSTRAINT "FK_Services_CommissionPayments_CommissionPaymentId" FOREIGN KEY ("CommissionPaymentId") REFERENCES "CommissionPayments" ("Id") ON DELETE SET NULL,
    CONSTRAINT "FK_Services_Employees_EmployeeId" FOREIGN KEY ("EmployeeId") REFERENCES "Employees" ("Id") ON DELETE SET NULL
);

INSERT INTO "ef_temp_Services" ("Operation", "CommissionPaymentId", "Date", "EmployeeId", "EmployeeName", "FinishedAt", "Plate", "Price", "RegisteredBy", "ServiceType", "Status", "Vehicle", "VehicleType")
SELECT "Operation", "CommissionPaymentId", "Date", "EmployeeId", "EmployeeName", "FinishedAt", "Plate", "Price", "RegisteredBy", "ServiceType", "Status", "Vehicle", "VehicleType"
FROM "Services";

COMMIT;

PRAGMA foreign_keys = 0;

BEGIN TRANSACTION;
DROP TABLE "Expenses";

ALTER TABLE "ef_temp_Expenses" RENAME TO "Expenses";

DROP TABLE "Services";

ALTER TABLE "ef_temp_Services" RENAME TO "Services";

COMMIT;

PRAGMA foreign_keys = 1;

BEGIN TRANSACTION;
CREATE INDEX "IX_Expenses_Date" ON "Expenses" ("Date");

CREATE UNIQUE INDEX "IX_Expenses_RecurringExpenseId_Date" ON "Expenses" ("RecurringExpenseId", "Date") WHERE [RecurringExpenseId] IS NOT NULL;

CREATE INDEX "IX_Services_CommissionPaymentId" ON "Services" ("CommissionPaymentId");

CREATE INDEX "IX_Services_EmployeeId" ON "Services" ("EmployeeId");

CREATE INDEX "IX_Services_Plate" ON "Services" ("Plate");

CREATE INDEX "IX_Services_Status" ON "Services" ("Status");

COMMIT;

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20261105231939_ComisionesGastosFijosYSesiones', '10.0.14');

BEGIN TRANSACTION;
ALTER TABLE "Services" ADD "ContactName" TEXT NOT NULL DEFAULT '';

ALTER TABLE "Services" ADD "ContactPhone" TEXT NOT NULL DEFAULT '';

INSERT INTO "__EFMigrationsHistory" ("MigrationId", "ProductVersion")
VALUES ('20261106050000_ContactoDelServicio', '10.0.14');

COMMIT;

-- Administrador inicial: admin / admin123 (cámbiala al entrar en
-- "Cambiar contraseña"). No se agrega si ya existe.
INSERT INTO "Users" ("Name", "Username", "PasswordHash", "Role", "Active", "CreatedAt")
SELECT 'Administrador', 'admin', '210000.Gdye3eeXrCd/GQpDdx7GiQ==.G0oh9o/nFJRYhqIhNmOYq3gJfSuZV8Lfuj2bxt5ZFjY=', 'administrador', 1, datetime('now')
WHERE NOT EXISTS (SELECT 1 FROM "Users" WHERE "Username" = 'admin');
