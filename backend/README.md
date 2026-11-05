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
| `Services`  | Servicios (operaciones)        | `Price > 0` · estado válido · `EmployeeId` → `Employees`   |

El número de operación es el identificador autonumérico de `Services`.

### SQLite (por defecto) o SQL Server

En `appsettings.json`:

```json
"Database": { "Provider": "SqlServer" },
"ConnectionStrings": {
  "Default": "Server=localhost;Database=AlingBalance;Trusted_Connection=True;TrustServerCertificate=True"
}
```

Las tablas se crean automáticamente con `EnsureCreated`. Cuando el modelo
cambie con datos reales en producción, conviene pasar a migraciones
(`dotnet ef migrations add ...`).

## Endpoints

Todos devuelven JSON. Excepto el login, requieren `Authorization: Bearer <token>`.

| Método | Ruta                             | Quién            | Descripción                              |
|--------|----------------------------------|------------------|------------------------------------------|
| POST   | `/api/auth/login`                | Público          | Devuelve token JWT y datos del usuario   |
| GET    | `/api/auth/me`                   | Autenticado      | Usuario de la sesión                     |
| GET    | `/api/users`                     | Administrador    | Lista de usuarios                        |
| POST   | `/api/users`                     | Administrador    | Crear usuario                            |
| PATCH  | `/api/users/{id}/active`         | Administrador    | Activar / desactivar                     |
| GET    | `/api/employees`                 | Autenticado      | Admin: todos. Empleado: activos (sin datos personales) |
| POST   | `/api/employees`                 | Administrador    | Registrar empleado                       |
| PATCH  | `/api/employees/{id}/active`     | Administrador    | Activar / desactivar                     |
| GET    | `/api/services`                  | Autenticado      | Lista de servicios                       |
| POST   | `/api/services`                  | Autenticado      | Registrar servicio                       |
| PATCH  | `/api/services/{operation}/status` | Autenticado    | Finalizar / reabrir                      |
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
| DELETE | `/api/expenses/{id}`             | Administrador    | Eliminar gasto                           |
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
