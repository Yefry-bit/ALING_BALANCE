# AlingBalance API (backend)

API REST en **ASP.NET Core (.NET 10)** con **Entity Framework Core** y base de
datos SQL compartida por todos los dispositivos. La app Flutter (carpeta
raíz) se conecta a esta API.

## Requisitos

- [.NET 10 SDK](https://dotnet.microsoft.com/download) (LTS)

## Ejecutar

```bash
cd backend/AlingBalance.Api
dotnet run
```

El servidor queda en `http://0.0.0.0:5080` y, la primera vez:

1. Crea la base de datos (`alingbalance.db`, SQLite) con todas las tablas.
2. Crea el administrador inicial: usuario `admin`, contraseña `admin123`
   (cámbiala en `appsettings.json` → `Seed` antes del primer arranque, o crea
   otro administrador desde la app y desactiva este).

Comprobar que funciona: abre `http://localhost:5080/health` → `{"status":"ok"}`.

## Base de datos

Scripts SQL, datos de ejemplo, diagrama y consultas en [`../database/`](../database/README.md).
El archivo `AlingBalance.Api/alingbalance.db` ya trae las tablas y el administrador.

| Tabla       | Contenido                      | Restricciones principales                                  |
|-------------|--------------------------------|------------------------------------------------------------|
| `Users`     | Cuentas y rol                  | `Username` único · rol solo `administrador` / `empleado`   |
| `Employees` | Empleados del taller           | `Document` único                                           |
| `Services`  | Servicios (operaciones)        | `Price > 0` · estado válido · `EmployeeId` → `Employees` · `CommissionPaymentId` → `CommissionPayments` |
| `Clients` / `Vehicles` | Clientes y sus vehículos | `Document` único · `Plate` única                     |
| `Expenses`  | Gastos                         | `Amount > 0` · `RecurringExpenseId` → `RecurringExpenses`  |
| `RecurringExpenses` | Gastos fijos mensuales | `Amount > 0` · día 1 a 28                                  |
| `CommissionPayments` | Pagos de comisiones   | un pago agrupa los servicios pagados a un empleado         |
| `ServicePhotos` | Fotos de evidencia         | `ServiceOperation` → `Services`                            |

El número de operación es el identificador autonumérico de `Services`.

### SQLite (por defecto) o SQL Server

En `appsettings.json`:

```json
"Database": { "Provider": "SqlServer" },
"ConnectionStrings": {
  "Default": "Server=localhost;Database=AlingBalance;Trusted_Connection=True;TrustServerCertificate=True"
}
```

### Migraciones

El esquema se maneja con **migraciones de Entity Framework**
(`AlingBalance.Api/Migrations`). Al arrancar, el servidor aplica solo las que
falten (`Data/DatabaseInitializer.cs`):

- **Base nueva**: se crea completa.
- **Base de una versión anterior** (creada antes de usar migraciones): se
  completa con `SchemaUpgrader`, se marca la migración `InitialCreate` como
  aplicada y luego se aplican las demás. **No se pierde ningún dato.**
- **Base ya migrada**: solo se aplican las migraciones nuevas.

Hay un juego de migraciones por motor (`Migrations/Sqlite` y
`Migrations/SqlServer`), porque el SQL que generan es distinto. Para cambiar el
modelo:

```bash
cd backend
dotnet tool restore                       # instala dotnet-ef (una sola vez)
cd AlingBalance.Api
# 1. Cambia las clases en Domain/ y su configuración en Data/AppDbContext.cs
# 2. Crea la migración para los dos motores (mismo nombre):
dotnet ef migrations add NombreDelCambio --context SqliteAppDbContext --output-dir Migrations/Sqlite
dotnet ef migrations add NombreDelCambio --context SqlServerAppDbContext --output-dir Migrations/SqlServer
# 3. Regenera los scripts de ../database (ver database/README.md)
```

> Si el servidor está corriendo, el compilador no puede reemplazar el `.exe`:
> agrega `--configuration Release` a los comandos de `dotnet ef` o detén el
> servidor primero.

Haz una **copia de `alingbalance.db`** antes de actualizar el servidor en
producción. Algunas migraciones en SQLite reconstruyen tablas (así funciona
SQLite al agregar llaves foráneas); los datos se copian, pero la copia de
seguridad es la red de protección.

## Endpoints

Todos devuelven JSON. Excepto el login, requieren `Authorization: Bearer <token>`.

| Método | Ruta                             | Quién            | Descripción                              |
|--------|----------------------------------|------------------|------------------------------------------|
| POST   | `/api/auth/login`                | Público          | Devuelve token JWT y datos del usuario. Con `rememberMe: true` el token dura 30 días (`Jwt:RememberDays`) |
| GET    | `/api/auth/me`                   | Autenticado      | Usuario de la sesión                     |
| POST   | `/api/auth/change-password`      | Autenticado      | Cambiar la contraseña propia (`currentPassword`, `newPassword`); cierra las demás sesiones y devuelve un token nuevo |
| GET    | `/api/users`                     | Administrador    | Lista de usuarios                        |
| POST   | `/api/users`                     | Administrador    | Crear usuario                            |
| PUT    | `/api/users/{id}`                | Administrador    | Editar nombre y rol (no el propio rol; siempre queda un admin activo) |
| PATCH  | `/api/users/{id}/password`       | Administrador    | Asignar contraseña nueva a otra cuenta   |
| PATCH  | `/api/users/{id}/active`         | Administrador    | Activar / desactivar                     |
| GET    | `/api/employees`                 | Autenticado      | Admin: todos. Empleado: activos (sin datos personales) |
| POST   | `/api/employees`                 | Administrador    | Registrar empleado                       |
| PATCH  | `/api/employees/{id}/active`     | Administrador    | Activar / desactivar                     |
| GET    | `/api/services`                  | Autenticado      | Lista de servicios                       |
| POST   | `/api/services`                  | Autenticado      | Registrar servicio                       |
| PATCH  | `/api/services/{operation}/status` | Autenticado    | Finalizar / reabrir (no se reabre si su comisión ya se pagó) |
| PATCH  | `/api/services/{operation}/employee` | Administrador | Cambiar el empleado (`employeeId`); no si la comisión ya se pagó |
| GET    | `/api/clients`                   | Autenticado      | Clientes con sus vehículos               |
| POST   | `/api/clients`                   | Autenticado      | Registrar cliente                        |
| PUT    | `/api/clients/{id}`              | Autenticado      | Editar nombre, identificación y teléfono |
| DELETE | `/api/clients/{id}`              | Administrador    | Eliminar cliente y sus vehículos (los servicios se conservan) |
| POST   | `/api/clients/{id}/vehicles`     | Autenticado      | Agregar vehículo (placa única)           |
| DELETE | `/api/clients/{id}/vehicles/{vehicleId}` | Administrador | Quitar vehículo                     |
| GET    | `/api/services/{operation}/photos` | Autenticado    | Fotos de un servicio (sin la imagen)     |
| POST   | `/api/services/{operation}/photos` | Autenticado    | Subir foto (multipart: `file`, `kind`, `note`) |
| GET    | `/api/photos/{id}`               | Autenticado      | La imagen                                |
| DELETE | `/api/photos/{id}`               | Quien la tomó o admin | Eliminar foto                       |
| GET    | `/api/expenses`                  | Administrador    | Lista de gastos                          |
| POST   | `/api/expenses`                  | Administrador    | Registrar gasto (descripción, categoría, valor, fecha) |
| PUT    | `/api/expenses/{id}`             | Administrador    | Editar gasto                             |
| DELETE | `/api/expenses/{id}`             | Administrador    | Eliminar gasto                           |
| GET    | `/api/recurring-expenses`        | Administrador    | Gastos fijos mensuales                   |
| POST   | `/api/recurring-expenses`        | Administrador    | Crear gasto fijo (`dayOfMonth` 1-28, `includeCurrentMonth`) |
| PUT    | `/api/recurring-expenses/{id}`   | Administrador    | Editar, pausar (`active: false`) o reanudar |
| DELETE | `/api/recurring-expenses/{id}`   | Administrador    | Eliminar (los gastos ya registrados se conservan) |
| GET    | `/api/commissions/payments`      | Administrador    | Pagos de comisiones                      |
| POST   | `/api/commissions/payments`      | Administrador    | Pagar comisiones (`employeeId`, `year`, `month`, `operations`); el valor lo calcula el servidor |
| DELETE | `/api/commissions/payments/{id}` | Administrador    | Deshacer un pago (los servicios vuelven a pendientes) |
| GET    | `/api/backups`                   | Administrador    | Copias de seguridad guardadas y carpeta  |
| POST   | `/api/backups`                   | Administrador    | Hacer una copia ahora                    |
| GET    | `/health`                        | Público          | Estado del servidor                      |

Ejemplo:

```bash
curl -X POST http://localhost:5080/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"username":"admin","password":"admin123"}'
```

### Formato de errores

- **400**: `{"errors": {"plate": ["La placa debe tener el formato ABC-123."]}}`
- **401 / 403 / 404 / 409**: `{"detail": "Mensaje claro en español"}`
- **429**: demasiados intentos de inicio de sesión.

### Sesiones

- El token lleva un **código de seguridad** de la cuenta (`Users.SecurityStamp`).
  Al cambiar la contraseña o el rol se genera uno nuevo y los tokens anteriores
  dejan de servir (401): así una sesión guardada en un celular no conserva una
  contraseña o permisos viejos.
- Desactivar una cuenta también invalida sus tokens.

### Copias de seguridad

`Services/DatabaseBackupService.cs` copia la base SQLite una vez al día (copia
en caliente con la API de *backup* de SQLite, segura con la app en uso) y borra
las que sobren. Configuración en `appsettings.json`:

| Clave            | Por defecto | Qué hace                                             |
|------------------|-------------|------------------------------------------------------|
| `Backup:Enabled` | `true`      | Activa las copias automáticas                        |
| `Backup:Folder`  | `backups`   | Carpeta (relativa al servidor o absoluta; puede ser de OneDrive / Google Drive) |
| `Backup:Hour`    | `22`        | Hora local desde la que se hace la copia del día     |
| `Backup:Keep`    | `30`        | Cuántas copias conservar                             |

Si el servidor estuvo apagado y la última copia tiene más de un día, hace una
al arrancar. Con SQL Server no aplica (usa las copias del propio SQL Server).

### Gastos fijos

Cada vez que se consultan los gastos (`GET /api/expenses`), el servidor
registra los gastos fijos cuyo día ya llegó (`Services/RecurringExpenseScheduler.cs`),
incluidos los meses atrasados si nadie abrió la app. Cada mes se genera una
sola vez, aunque luego se borre ese gasto; los meses en pausa no se cobran.

## Validaciones

**Usuarios:** nombre 3–80 letras · usuario 4–20 (`a-z`, `0-9`, `.`, `_`, único) ·
contraseña 8–64 con letra y número · rol válido · no se puede desactivar la
propia cuenta ni al último administrador activo.

**Empleados:** nombre 3–80 letras · identificación 5–12 dígitos, única ·
teléfono opcional (7 dígitos fijo, 10 celular) · no se puede desactivar a un
empleado con servicios en proceso.

**Servicios:** placa `ABC-123` · marca y modelo 2–30 caracteres · tipo de
vehículo y servicio del catálogo · precio entre $1 y $5.000.000 · empleado
activo y existente (obligatorio si hay empleados activos) · no puede haber dos
servicios iguales «En proceso» para la misma placa · **el precio de los
empleados siempre es el del catálogo** (`Catalog/ServiceCatalog.cs`); solo el
administrador puede cambiarlo.

**Seguridad:** contraseñas con PBKDF2-SHA256 y sal · tokens JWT de 8 horas ·
el token deja de servir si la cuenta se desactiva · límite de 10 intentos de
login por minuto por dirección.

## Publicar para usar desde varios dispositivos

1. Define una clave propia: variable de entorno `Jwt__Key` (mínimo 32 caracteres).
   En producción el servidor **no arranca** con la clave de ejemplo.
2. Cambia la contraseña del administrador inicial.
3. Publica detrás de **HTTPS** (Azure App Service, Render, un VPS con Nginx,
   etc.) y usa SQL Server o un volumen persistente para el archivo SQLite.
4. En la app Flutter compila con la dirección pública:
   `flutter run --dart-define=API_URL=https://tu-servidor.com`

## Pruebas

```bash
dotnet test backend/AlingBalance.Api.Tests
```
