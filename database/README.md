# Base de datos de AlingBalance

Guarda usuarios, empleados, servicios (con sus fotos), clientes y vehículos,
gastos (y gastos fijos) y pagos de comisiones. La API (`backend/`) es la única
que la lee y escribe; la app Flutter nunca toca la base de datos directamente.

El esquema se define con **migraciones de Entity Framework**
(`backend/AlingBalance.Api/Migrations`). Los scripts de esta carpeta se
**generan** desde ellas: no los edites a mano.

## ¿Qué archivo uso?

| Quiero…                                     | Uso                                                   |
|---------------------------------------------|-------------------------------------------------------|
| Arrancar ya, sin instalar nada              | **`backend/AlingBalance.Api/alingbalance.db`** (SQLite, ya viene lista con el administrador) |
| Crear la base en SQLite desde cero          | `sqlite/schema.sql` (y opcionalmente `sqlite/demo_data.sql`) |
| Usar SQL Server                             | `sqlserver/01_schema.sql` (y opcionalmente `02_demo_data.sql`) |
| Ver o probar consultas                      | `queries.sql`                                         |

> Si no haces nada, el servidor crea la base (o le aplica las migraciones que
> falten) cada vez que arranca. Estos archivos sirven para tenerla lista,
> revisarla o usar SQL Server. Los scripts de esquema incluyen la tabla
> `__EFMigrationsHistory`, así el servidor reconoce la base creada con ellos.

**Usuario inicial:** `admin` · **contraseña:** `admin123` (cámbiala). Los datos
de ejemplo agregan además `maria` / `clave123` (rol empleado).

## Diagrama

```mermaid
erDiagram
    Users {
        int Id PK
        string Name
        string Username UK
        string PasswordHash
        string Role "administrador | empleado"
        bool Active
        datetime CreatedAt
    }
    Employees {
        int Id PK
        string Name
        string Document UK
        string Phone
        bool Active
        datetime CreatedAt
    }
    Services {
        int Operation PK "número de operación"
        string Plate
        string Vehicle
        string VehicleType
        string ServiceType
        string Status "En proceso | Terminado"
        int Price "COP, mayor a 0"
        datetime Date
        string RegisteredBy
        int EmployeeId FK "puede ser nulo"
        string EmployeeName
    }
    Clients {
        int Id PK
        string Name
        string Document UK
        string Phone
    }
    Vehicles {
        int Id PK
        int ClientId FK
        string Plate UK
        string Brand
        string Model
        string VehicleType
    }
    ServicePhotos {
        int Id PK
        int ServiceOperation FK
        string Kind
        blob Data
    }
    Expenses {
        int Id PK
        string Description
        string Category
        int Amount
        date Date
        int RecurringExpenseId FK "nulo si se registró a mano"
    }
    RecurringExpenses {
        int Id PK
        string Description
        int Amount
        int DayOfMonth "1 a 28"
        bool Active
        int LastGeneratedMonth
    }
    CommissionPayments {
        int Id PK
        int EmployeeId FK
        int Year
        int Month
        int Amount
        datetime PaidAt
    }
    Employees ||--o{ Services : "realiza"
    Clients ||--o{ Vehicles : "tiene"
    Services ||--o{ ServicePhotos : "evidencia"
    RecurringExpenses ||--o{ Expenses : "genera"
    CommissionPayments ||--o{ Services : "paga"
    Employees ||--o{ CommissionPayments : "recibe"
```

Los servicios se enlazan con los vehículos **por la placa** (sin llave
foránea), así el historial se conserva aunque se elimine el cliente.

`Users` no tiene llave foránea: `Services.RegisteredBy` guarda el **nombre** de
quien registró el servicio, y `Services.EmployeeName` el nombre del empleado al
momento de registrarlo (así el historial no cambia si luego editan el nombre).

## Tablas y restricciones

| Tabla       | Campo clave / único        | Reglas que protege la base de datos                          |
|-------------|----------------------------|--------------------------------------------------------------|
| `Users`     | `Username` único           | `Role` solo `administrador` o `empleado`                      |
| `Employees` | `Document` único           | —                                                            |
| `Services`  | `Operation` (autonumérico) | `Price > 0` · `Status` solo `En proceso` o `Terminado` · `EmployeeId` debe existir en `Employees`; si se borra el empleado, el servicio se conserva sin asignar · `CommissionPaymentId` (nulo = comisión pendiente) |
| `Clients`   | `Document` único           | al borrar un cliente se borran sus vehículos                  |
| `Vehicles`  | `Plate` única              | `ClientId` debe existir en `Clients`                          |
| `ServicePhotos` | `Id`                   | `ServiceOperation` debe existir en `Services`                 |
| `Expenses`  | `Id`                       | `Amount > 0` · un solo gasto por gasto fijo y fecha           |
| `RecurringExpenses` | `Id`               | `Amount > 0` · `DayOfMonth` entre 1 y 28                      |
| `CommissionPayments` | `Id`              | `Amount >= 0` · `Month` entre 1 y 12                          |

Las demás validaciones (formato de placa, teléfono, contraseña, precio máximo,
servicios repetidos, etc.) las aplica la API; ver `backend/README.md`.

La contraseña **nunca** se guarda: `PasswordHash` tiene el formato
`iteraciones.sal.hash` (PBKDF2-SHA256), igual que genera la API.

## Cómo usarla

### SQLite (la más simple)

El servidor usa `Data Source=alingbalance.db` (en `appsettings.json`), que es el
archivo de `backend/AlingBalance.Api/`. Solo ejecuta `dotnet run` ahí.

Para crearla desde cero o cargar los datos de ejemplo:

```bash
sqlite3 alingbalance.db < database/sqlite/schema.sql
sqlite3 alingbalance.db < database/sqlite/demo_data.sql   # opcional
```

Para mirarla con interfaz: [DB Browser for SQLite](https://sqlitebrowser.org/)
(abre el archivo `.db`).

### SQL Server

1. Ejecuta `sqlserver/01_schema.sql` (crea la base `AlingBalance`, las tablas y
   el administrador) y, si quieres, `02_demo_data.sql`, en SQL Server Management
   Studio o Azure Data Studio.
2. En `backend/AlingBalance.Api/appsettings.json`:

```json
"Database": { "Provider": "SqlServer" },
"ConnectionStrings": {
  "Default": "Server=localhost;Database=AlingBalance;Trusted_Connection=True;TrustServerCertificate=True"
}
```

### Regenerar los scripts

Después de crear una migración nueva (ver `backend/README.md`):

```bash
cd backend/AlingBalance.Api
dotnet ef migrations script --context SqliteAppDbContext -o ../../database/sqlite/schema.sql
dotnet ef migrations script --idempotent --context SqlServerAppDbContext -o ../../database/sqlserver/01_schema.sql
```

Luego vuelve a poner al inicio de cada archivo el encabezado (en SQL Server,
el `CREATE DATABASE` / `USE`) y al final el administrador inicial.

## Copias de seguridad

- **SQLite:** con el servidor apagado, copia el archivo `alingbalance.db`.
- **SQL Server:** `BACKUP DATABASE AlingBalance TO DISK = 'C:\respaldo\AlingBalance.bak';`

Haz copias seguido: la base es la única fuente de datos del sistema.

## Cambios futuros

Hoy el esquema lo crea `EnsureCreated`, que no actualiza una base ya existente.
Cuando agregues campos o tablas con datos reales, usa migraciones de Entity
Framework Core (`dotnet ef migrations add`, `dotnet ef database update`).
