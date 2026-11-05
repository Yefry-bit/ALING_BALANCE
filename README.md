# AlingBalance


Sistema para administrar un taller de **alineación y balanceo**: servicios por
vehículo, empleados, comisiones, contabilidad y usuarios con roles.

Tiene dos partes que se conectan por HTTP:

| Parte        | Carpeta                    | Tecnología                                  |
|--------------|----------------------------|---------------------------------------------|
| App móvil    | raíz (`lib/`)              | Flutter (Android / iOS)                     |
| Servidor + base de datos | `backend/`     | ASP.NET Core (.NET 10) + Entity Framework + SQL |

Todos los datos (servicios, empleados y usuarios) viven en la **base de datos
del servidor**, así que se comparten entre todos los dispositivos.

```
App Flutter (celulares) ──HTTP + JWT──▶ API ASP.NET Core ──▶ Base de datos SQL
```

## Puesta en marcha

### 1. Servidor

Requiere el [SDK de .NET 10](https://dotnet.microsoft.com/download).

```bash
cd backend/AlingBalance.Api
dotnet run
```

Queda en `http://0.0.0.0:5080`. La base de datos ya viene lista en
`backend/AlingBalance.Api/alingbalance.db` con el administrador inicial
(`admin` / `admin123`); si falta, el servidor la crea solo. Scripts, diagrama y
SQL Server en [`database/README.md`](database/README.md). Comprueba en
`http://localhost:5080/health`. Detalles, endpoints y publicación en
[`backend/README.md`](backend/README.md).

### 2. App

```bash
flutter pub get
flutter run -d edge        # navegador Edge (o -d chrome, -d windows)
```

Sin `API_URL`, la app busca el servidor en el lugar correcto según dónde
corre: en el navegador y en Windows usa este mismo computador
(`localhost:5080`) y en el emulador de Android `10.0.2.2:5080`. Solo hace
falta indicarlo en estos casos:

| Dónde corre la app          | Comando                                                            |
|-----------------------------|--------------------------------------------------------------------|
| Celular físico (misma WiFi) | `flutter run --dart-define=API_URL=http://IP-DEL-COMPUTADOR:5080` (ej. `192.168.1.20`) |
| Servidor publicado          | `flutter run --dart-define=API_URL=https://tu-servidor.com`        |

Con un celular físico, el firewall del computador debe permitir el puerto 5080.
La IP del computador se ve con `ipconfig`.

`10.0.2.2` solo existe dentro del emulador de Android; si se pasa esa
dirección al abrir la app en el navegador o en Windows, la app la cambia sola
por `localhost`. El servidor ya permite las llamadas desde el navegador (CORS,
configurable en `appsettings.json` → `Cors:Origins`).

**Si sale "el servidor tardó demasiado en responder":** el mensaje muestra la
dirección que intentó usar. Revisa que el servidor esté encendido
(`http://localhost:5080/health` debe responder `{"status":"ok"}`).

### 3. Pruebas

```bash
flutter test                                # app
dotnet test backend/AlingBalance.Api.Tests  # servidor
```

## Funciones

| Módulo       | Qué hace                                                              |
|--------------|-----------------------------------------------------------------------|
| Inicio       | Métricas (el administrador ve la ganancia del mes), accesos rápidos y últimos 5 servicios |
| Servicios    | Registrar vehículos con empleado asignado, finalizar (con **fotos de evidencia**) / reabrir |
| Empleados    | Registrar, activar / desactivar y ver su comisión acumulada           |
| Clientes     | Registrar clientes con **varios vehículos cada uno**, buscar por nombre / documento / placa e historial de servicios por carro |
| Contabilidad | **Dashboard mensual**: ingresos, gastos, comisiones y ganancia; gráfico de 6 meses; gastos por categoría; registro de gastos; comisiones por empleado |
| Usuarios     | Crear cuentas, asignar rol y activar / desactivar (solo administrador) |

El botón **Actualizar** de la barra superior descarga los cambios que hicieron
otros dispositivos.

## Usuarios y roles

El primer acceso es `admin` / `admin123` (se define en
`backend/AlingBalance.Api/appsettings.json` → `Seed`). Crea tu propio
administrador desde **Usuarios** y desactiva esa cuenta.

| Permiso                                   | Administrador | Empleado |
|-------------------------------------------|:-------------:|:--------:|
| Ver Inicio, Servicios y Clientes          | ✅            | ✅       |
| Registrar / editar clientes y vehículos   | ✅            | ✅       |
| Eliminar clientes o quitarles vehículos   | ✅            | ❌       |
| Registrar y eliminar gastos               | ✅            | ❌       |
| Registrar servicios y finalizar / reabrir | ✅            | ✅       |
| Cambiar el precio de un servicio          | ✅            | ❌ (precio fijo del catálogo) |
| Ver totales de dinero y Contabilidad      | ✅            | ❌       |
| Gestionar empleados                       | ✅            | ❌       |
| Crear y desactivar usuarios               | ✅            | ❌       |

Los permisos se aplican **en el servidor** (la app solo oculta lo que no
corresponde), así que un empleado no puede saltárselos. En la app están en
`lib/models/user_role.dart`.

## Comisiones

- Al registrar un servicio se elige el **empleado que realiza el trabajo**
  (entre los activos; es obligatorio si hay empleados activos).
- Cada empleado gana el **30 %** del precio de los servicios que **termina**
  (`WorkshopController.commissionRate`). Un servicio "En proceso" no genera
  comisión; si se reabre, la comisión se descuenta.
- No se puede desactivar a un empleado que tiene servicios en proceso.

## Clientes y vehículos

- Un cliente tiene **varios vehículos**; cada placa pertenece a **un solo** cliente.
- Los servicios se enlazan con el vehículo **por la placa**: al registrar un
  servicio con una placa ya registrada, el formulario completa marca, modelo y
  tipo, y la tarjeta del servicio muestra el cliente.
- Eliminar un cliente borra sus vehículos, pero **no** sus servicios (siguen en
  el historial y en la contabilidad).

## Registro de servicios

- **Marca y modelo con sugerencias**: al escribir aparecen las marcas más
  comunes en Colombia (Chevrolet, Renault, Mazda, Kia, Toyota…) y los modelos
  de la marca elegida. Al guardar se corrige la escritura ("chevrolet" →
  "Chevrolet", "cx5" → "CX-5"); también se puede escribir una que no esté en
  la lista. El catálogo está en `lib/core/constants/vehicle_catalog.dart`.
- **Hora de ingreso y de finalización**: cada servicio muestra cuándo
  ingresó, cuándo se terminó y cuánto tardó. Al reabrirlo se borra la hora de
  finalización y se vuelve a guardar al terminarlo. Los servicios terminados
  antes de esta versión muestran "Hora no registrada".

## Fotos de evidencia

- Al pulsar **Finalizar** en un servicio se abre un formulario para tomar
  fotos del **carro**, de las **máquinas / equipo**, de una **falla o daño** o
  de una **pieza faltante**, cada una con una descripción. Son opcionales.
- En Android / iOS se usa la cámara; en el navegador o en Windows se eligen
  archivos. Las fotos se reducen a 1600 px antes de subirlas.
- Se guardan en la base de datos (tabla `ServicePhotos`), así todos los
  dispositivos las ven. Máximo 12 por servicio y 5 MB por foto; el servidor
  revisa que el archivo sea realmente JPG, PNG o WebP.
- El botón **Fotos (n)** de cada servicio abre la galería: ampliar, agregar
  más o eliminar (quien la tomó o un administrador).

## Contabilidad (dashboard mensual)

| Concepto   | Cómo se calcula                                                   |
|------------|-------------------------------------------------------------------|
| Ingresos   | Precio de los servicios **terminados** registrados en el mes      |
| Comisiones | 30 % de esos servicios (los que tienen empleado)                  |
| Gastos     | Gastos registrados con fecha dentro del mes                       |
| Ganancia   | Ingresos − comisiones − gastos (si es negativa, se muestra pérdida) |

Los servicios "En proceso" no cuentan como ingreso hasta que se terminan.

## Valores fijos

| Valor                                   | Dónde se cambia                                          |
|-----------------------------------------|----------------------------------------------------------|
| Precios, servicios y tipos de vehículo  | `backend/.../Catalog/ServiceCatalog.cs` y `lib/core/constants/service_catalog.dart` |
| Comisión (30 %)                         | `WorkshopController.commissionRate`                      |
| Categorías de gasto                     | `backend/.../Domain/Expense.cs` y `lib/models/expense.dart` |
| Administrador inicial                   | `backend/.../appsettings.json` → `Seed`                  |
| Clave de los tokens                     | `backend/.../appsettings.json` → `Jwt` (en producción, variable `Jwt__Key`) |

Los precios del catálogo deben ser iguales en ambos lados: el servidor es el
que manda (los empleados siempre usan el precio del servidor).

## Validaciones

Se validan **dos veces**: en la app (respuesta inmediata en cada campo) y en el
servidor (seguridad real). Las reglas son las mismas:
`lib/core/utils/validators.dart` y `backend/.../Validation/Rules.cs`.

| Dato          | Regla                                                                      |
|---------------|----------------------------------------------------------------------------|
| Placa         | Formato `ABC-123` (acepta `abc123` y la normaliza)                         |
| Marca / modelo| 2–30 caracteres; letras, números, espacio, `. - / +`                       |
| Precio        | Entero entre $1 y $5.000.000                                               |
| Nombre        | 3–80 caracteres; solo letras, espacios, `.`, `'` y `-`                     |
| Identificación| 5–12 dígitos; única por empleado                                           |
| Teléfono      | Opcional; 7 dígitos (fijo) o 10 (celular `3…` / `60…`); acepta `+57`        |
| Usuario       | 4–20 caracteres (`a-z`, `0-9`, `.`, `_`); único                            |
| Contraseña    | 8–64 caracteres con al menos una letra y un número; con confirmación       |
| Servicio      | Tipo de vehículo y servicio del catálogo; empleado activo; no se repite un servicio igual "En proceso" para la misma placa |
| Cuentas       | No se desactiva la propia ni al último administrador activo                |

Además: confirmación antes de desactivar o reabrir, formularios que no se
cierran si el servidor rechaza los datos (no se pierde lo escrito), botones
bloqueados mientras se guarda, y restricciones de la base de datos (únicos,
llaves foráneas y `CHECK`) como última barrera.

## Estructura de la app

```
lib/
├── main.dart, app.dart           Arranque, tema y pantalla inicial
├── core/
│   ├── config/api_config.dart    Dirección del servidor (API_URL)
│   ├── constants/                Colores y catálogo de servicios
│   ├── navigation/app_section.dart  Las 6 secciones del menú
│   ├── theme/app_theme.dart      Tema oscuro
│   └── utils/                    validators · formatters · snackbar
├── models/                       Clases de datos (sin interfaz) y roles
├── data/
│   ├── api_client.dart           Cliente HTTP: token, errores, tiempo de espera
│   ├── auth_repository.dart      Login y usuarios
│   └── workshop_repository.dart  Servicios y empleados
├── state/
│   ├── auth_controller.dart      Sesión y cuentas
│   └── workshop_controller.dart  Servicios, empleados y comisiones
├── screens/
│   ├── login/login_screen.dart
│   └── dashboard/                Panel + una sección por archivo
└── widgets/                      Tarjetas, menú y diálogos reutilizables

test/                             Validadores, cliente HTTP, controladores y
                                  pantallas (con un servidor simulado en memoria)
backend/
├── AlingBalance.Api/             Servidor (controladores, dominio, datos, seguridad)
│   └── alingbalance.db           Base de datos SQLite lista para usar
└── AlingBalance.Api.Tests/       Pruebas del servidor
database/                         Scripts SQL (SQLite y SQL Server), datos de ejemplo,
                                  consultas y diagrama → ver database/README.md
```

Flujo: los widgets solo dibujan → los controladores guardan el estado y las
reglas → los repositorios hablan con la API → el servidor valida y guarda en la
base de datos.

## Próximos pasos sugeridos

1. Migraciones de Entity Framework (`dotnet ef migrations`) en lugar de
   `EnsureCreated` + `SchemaUpgrader` (que hoy agrega las tablas nuevas a una
   base existente), antes de tener datos reales en producción.
2. Guardar la sesión de forma segura (`flutter_secure_storage`) para no pedir
   la contraseña cada vez que se abre la app.
3. Poder reasignar el empleado de un servicio ya registrado.
4. Marcar comisiones como pagadas y exportar el resumen mensual (PDF / Excel).
5. Editar un gasto ya registrado y gastos recurrentes (arriendo, nómina).
6. Cambiar contraseña y editar el rol de un usuario existente.
