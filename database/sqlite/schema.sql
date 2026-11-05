-- =====================================================================
-- AlingBalance - Esquema de la base de datos (SQLite)
-- Es el mismo esquema que crea Entity Framework Core automáticamente.
-- Uso:  sqlite3 alingbalance.db < schema.sql
-- =====================================================================
PRAGMA foreign_keys = ON;

CREATE TABLE "Users" (
    "Id"           INTEGER NOT NULL CONSTRAINT "PK_Users" PRIMARY KEY AUTOINCREMENT,
    "Name"         TEXT    NOT NULL,                 -- nombre completo (3-80)
    "Username"     TEXT    NOT NULL,                 -- usuario en minúsculas (4-20), único
    "PasswordHash" TEXT    NOT NULL,                 -- PBKDF2-SHA256: iteraciones.sal.hash
    "Role"         TEXT    NOT NULL,                 -- 'administrador' | 'empleado'
    "Active"       INTEGER NOT NULL,                 -- 1 activo, 0 inactivo
    "CreatedAt"    TEXT    NOT NULL,
    CONSTRAINT "CK_Users_Role" CHECK ("Role" IN ('administrador', 'empleado'))
);

CREATE TABLE "Employees" (
    "Id"        INTEGER NOT NULL CONSTRAINT "PK_Employees" PRIMARY KEY AUTOINCREMENT,
    "Name"      TEXT    NOT NULL,                    -- nombre completo (3-80)
    "Document"  TEXT    NOT NULL,                    -- identificación (5-12 dígitos), única
    "Phone"     TEXT    NOT NULL,                    -- opcional ('' si no hay)
    "Active"    INTEGER NOT NULL,                    -- 1 activo, 0 inactivo
    "CreatedAt" TEXT    NOT NULL
);

CREATE TABLE "Services" (
    "Operation"    INTEGER NOT NULL CONSTRAINT "PK_Services" PRIMARY KEY AUTOINCREMENT,
    "Plate"        TEXT    NOT NULL,                 -- ABC-123
    "Vehicle"      TEXT    NOT NULL,                 -- marca y modelo
    "VehicleType"  TEXT    NOT NULL,                 -- Particular | Taxi | Camioneta
    "ServiceType"  TEXT    NOT NULL,                 -- servicio del catálogo
    "Status"       TEXT    NOT NULL,                 -- 'En proceso' | 'Terminado'
    "Price"        INTEGER NOT NULL,                 -- pesos colombianos (> 0)
    "Date"         TEXT    NOT NULL,                 -- UTC, hora de ingreso
    "FinishedAt"   TEXT    NULL,                     -- UTC, hora en que se terminó (NULL si está en proceso)
    "RegisteredBy" TEXT    NOT NULL,                 -- quién lo registró
    "EmployeeId"   INTEGER NULL,                     -- quién hizo el trabajo
    "EmployeeName" TEXT    NOT NULL,                 -- nombre al registrar
    CONSTRAINT "CK_Services_Price"  CHECK ("Price" > 0),
    CONSTRAINT "CK_Services_Status" CHECK ("Status" IN ('En proceso', 'Terminado')),
    CONSTRAINT "FK_Services_Employees_EmployeeId" FOREIGN KEY ("EmployeeId")
        REFERENCES "Employees" ("Id") ON DELETE SET NULL
);

CREATE TABLE "Clients" (
    "Id"        INTEGER NOT NULL CONSTRAINT "PK_Clients" PRIMARY KEY AUTOINCREMENT,
    "Name"      TEXT    NOT NULL,                    -- nombre completo (3-80)
    "Document"  TEXT    NOT NULL,                    -- identificación (5-12 dígitos), única
    "Phone"     TEXT    NOT NULL,                    -- opcional ('' si no hay)
    "CreatedAt" TEXT    NOT NULL
);

-- Un cliente puede tener varios vehículos; una placa pertenece a un solo cliente.
-- Los servicios se enlazan con el vehículo por la placa.
CREATE TABLE "Vehicles" (
    "Id"          INTEGER NOT NULL CONSTRAINT "PK_Vehicles" PRIMARY KEY AUTOINCREMENT,
    "ClientId"    INTEGER NOT NULL,
    "Plate"       TEXT    NOT NULL,                  -- ABC-123, única
    "Brand"       TEXT    NOT NULL,
    "Model"       TEXT    NOT NULL,
    "VehicleType" TEXT    NOT NULL,                  -- Particular | Taxi | Camioneta
    "CreatedAt"   TEXT    NOT NULL,
    CONSTRAINT "FK_Vehicles_Clients_ClientId" FOREIGN KEY ("ClientId")
        REFERENCES "Clients" ("Id") ON DELETE CASCADE
);

CREATE TABLE "Expenses" (
    "Id"           INTEGER NOT NULL CONSTRAINT "PK_Expenses" PRIMARY KEY AUTOINCREMENT,
    "Description"  TEXT    NOT NULL,                 -- 3-80 caracteres
    "Category"     TEXT    NOT NULL,                 -- Arriendo, Nómina, ...
    "Amount"       INTEGER NOT NULL,                 -- pesos colombianos (> 0)
    "Date"         TEXT    NOT NULL,                 -- día del gasto (aaaa-mm-dd)
    "RegisteredBy" TEXT    NOT NULL,
    "CreatedAt"    TEXT    NOT NULL,
    CONSTRAINT "CK_Expenses_Amount" CHECK ("Amount" > 0)
);

CREATE TABLE "ServicePhotos" (
    "Id"               INTEGER NOT NULL CONSTRAINT "PK_ServicePhotos" PRIMARY KEY AUTOINCREMENT,
    "ServiceOperation" INTEGER NOT NULL,             -- servicio al que pertenece
    "Kind"             TEXT    NOT NULL,             -- Vehículo | Máquina / equipo | Falla o daño | Pieza faltante
    "Note"             TEXT    NOT NULL,             -- descripción opcional (máx. 200)
    "ContentType"      TEXT    NOT NULL,             -- image/jpeg | image/png | image/webp
    "Data"             BLOB    NOT NULL,             -- la imagen (máx. 5 MB)
    "TakenById"        INTEGER NOT NULL,
    "TakenBy"          TEXT    NOT NULL,
    "CreatedAt"        TEXT    NOT NULL,
    CONSTRAINT "FK_ServicePhotos_Services_ServiceOperation" FOREIGN KEY ("ServiceOperation")
        REFERENCES "Services" ("Operation") ON DELETE CASCADE
);

CREATE UNIQUE INDEX "IX_Users_Username"     ON "Users" ("Username");
CREATE UNIQUE INDEX "IX_Employees_Document" ON "Employees" ("Document");
CREATE INDEX "IX_Services_EmployeeId" ON "Services" ("EmployeeId");
CREATE INDEX "IX_Services_Plate"      ON "Services" ("Plate");
CREATE INDEX "IX_Services_Status"     ON "Services" ("Status");
CREATE UNIQUE INDEX "IX_Clients_Document" ON "Clients" ("Document");
CREATE INDEX "IX_Vehicles_ClientId"       ON "Vehicles" ("ClientId");
CREATE UNIQUE INDEX "IX_Vehicles_Plate"   ON "Vehicles" ("Plate");
CREATE INDEX "IX_Expenses_Date"           ON "Expenses" ("Date");
CREATE INDEX "IX_ServicePhotos_ServiceOperation" ON "ServicePhotos" ("ServiceOperation");

-- Administrador inicial: usuario admin / contraseña admin123  (¡cámbiala!)
INSERT INTO "Users" ("Name", "Username", "PasswordHash", "Role", "Active", "CreatedAt")
VALUES ('Administrador', 'admin', '210000.UCqeQ0CfI4f7koKJRPxVsA==.a65PBQMaLPP+F3zuhuK/9g5Ak7s4KrNwVgsdPzjDfvM=', 'administrador', 1, datetime('now'));
