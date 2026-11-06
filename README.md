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
(`admin` / `admin123`); si falta, el servidor la crea solo, y al actualizar el
proyecto aplica solo los cambios de esquema (migraciones) sin borrar datos.
**Antes de actualizar, guarda una copia de `alingbalance.db`.** Scripts, diagrama y
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
| Servicios    | Registrar vehículos con empleado asignado, **cambiar el empleado**, finalizar (con **fotos de evidencia**) / reabrir y **avisar al cliente por WhatsApp** |
| Empleados    | Registrar, activar / desactivar y ver su comisión acumulada           |
| Clientes     | Registrar clientes con **varios vehículos cada uno**, buscar por nombre / documento / placa e historial de servicios por carro |
| Contabilidad | **Dashboard mensual**: ingresos, gastos, comisiones y ganancia; gráfico de 6 meses; gastos por categoría; registrar y **editar** gastos; **gastos fijos** (arriendo, nómina…); **pago de comisiones**; **exportar a PDF / Excel** |
| Usuarios     | Crear cuentas, **editar nombre y rol**, **asignar contraseña nueva** y activar / desactivar; **copias de seguridad** (solo administrador) |
| Tu cuenta    | Menú del ícono de usuario (arriba a la derecha): **cambiar contraseña** y cerrar sesión |

El botón **Actualizar** de la barra superior descarga los cambios que hicieron
otros dispositivos.

## Avisar al cliente por WhatsApp

Cuando un servicio queda **Terminado** y la placa pertenece a un cliente con
**celular** registrado (10 dígitos que empiezan por 3):

- Al finalizar aparece **"Avisar por WhatsApp"** en el mensaje de abajo.
- La tarjeta del servicio tiene el botón **Avisar al cliente** para hacerlo
  después.

La app abre WhatsApp con el mensaje ya escrito ("Hola Ana, le escribimos de
AlingBalance. Su vehículo … de placa … ya está listo …"); el empleado solo
toca **Enviar**. Sale desde el WhatsApp del celular o computador que se use,
es gratis y no necesita cuentas ni claves. En el celular también se puede
elegir **SMS**. En el computador abre WhatsApp Web o la app de escritorio.

El nombre con el que se firma (`shopName`) y el texto están en
`lib/core/utils/client_notifier.dart`.

## Copias de seguridad

El servidor guarda **una copia de la base al día** (desde las 10 p. m., o al
arrancar si la última tiene más de un día) en
`backend/AlingBalance.Api/backups/` y conserva las **últimas 30**. La copia se
hace en caliente: es segura aunque estén registrando servicios.

En **Usuarios → Copias de seguridad** se ve la última copia y el botón
**Hacer copia ahora** (úsalo antes de actualizar el servidor).

Para tenerlas **en la nube**, apunta la carpeta a una carpeta sincronizada de
OneDrive o Google Drive en `appsettings.json`:

```json
"Backup": { "Enabled": true, "Folder": "C:\Users\TU_USUARIO\OneDrive\AlingBalance", "Hour": 22, "Keep": 30 }
```

**Restaurar una copia:** detén el servidor, reemplaza
`backend/AlingBalance.Api/alingbalance.db` por la copia (renómbrala a
`alingbalance.db`) y vuelve a iniciarlo.

## Sesión guardada

Al iniciar sesión, **"Mantener la sesión iniciada"** (marcado por defecto)
guarda la sesión cifrada en el dispositivo (`flutter_secure_storage`: Keychain
en iOS, Keystore en Android, DPAPI en Windows, almacenamiento cifrado en el
navegador) y la app no pide la contraseña durante **30 días**. Se guarda el
token, **nunca la contraseña**. Desmárcalo en equipos compartidos.

La sesión guardada deja de servir si se cierra sesión, si vence, si se
desactiva la cuenta o si cambian su contraseña o su rol.

> En el navegador, el cifrado solo está disponible en `localhost` o con
> `https`. Si abres la app web por la IP de la red (`http://192.168…`), la
> sesión no se guarda y se pide la contraseña al abrirla (todo lo demás
> funciona igual).
>
> Para compilar la app de **Windows** (`flutter run -d windows`), Visual Studio
> necesita el componente **"C++ ATL"** (lo usa `flutter_secure_storage`).

## Usuarios y roles

El primer acceso es `admin` / `admin123` (se define en
`backend/AlingBalance.Api/appsettings.json` → `Seed`). Crea tu propio
administrador desde **Usuarios** y desactiva esa cuenta.

| Permiso                                   | Administrador | Empleado |
|-------------------------------------------|:-------------:|:--------:|
| Ver Inicio, Servicios y Clientes          | ✅            | ✅       |
| Registrar / editar clientes y vehículos   | ✅            | ✅       |
| Eliminar clientes o quitarles vehículos   | ✅            | ❌       |
| Registrar, editar y eliminar gastos y gastos fijos | ✅   | ❌       |
| Pagar comisiones y exportar el resumen    | ✅            | ❌       |
| Cambiar el empleado de un servicio        | ✅            | ❌       |
| Registrar servicios y finalizar / reabrir | ✅            | ✅       |
| Cambiar el precio de un servicio          | ✅            | ❌ (precio fijo del catálogo) |
| Ver totales de dinero y Contabilidad      | ✅            | ❌       |
| Gestionar empleados                       | ✅            | ❌       |
| Crear, editar y desactivar usuarios       | ✅            | ❌       |
| Cambiar su propia contraseña              | ✅            | ✅       |

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
- El administrador puede **cambiar el empleado** de un servicio ya registrado
  (botón *Cambiar empleado* en la tarjeta): la comisión pasa al nuevo.

### Pago de comisiones

En **Contabilidad → Pago de comisiones** se ve, para el mes elegido, cuánto
generó cada empleado, cuánto se le pagó y el botón **Pagar $…** para lo
pendiente. El pago queda registrado (fecha, valor, quién lo registró) y sus
servicios se marcan **"Comisión pagada"**:

- Un servicio con la comisión pagada **no se puede reabrir ni cambiar de
  empleado**.
- **Deshacer** un pago devuelve sus servicios a pendientes.
- El valor lo calcula el servidor (30 % de cada servicio), no la app.

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

### Gastos fijos

**Contabilidad → Gastos fijos → Agregar**: arriendo, nómina, internet… con
su valor y el **día del mes** (1 a 28). El servidor los registra solos cada
mes cuando llega ese día (también los meses atrasados si nadie abrió la app),
marcados con el ícono ↻. Se pueden **pausar** (los meses en pausa no se
cobran), editar (aplica a los meses siguientes) o eliminar (los ya registrados
se conservan). Cada gasto registrado se puede **editar** con el lápiz.

### Exportar el resumen

**Contabilidad → Exportar** descarga el resumen del mes elegido:

- **PDF**: listo para imprimir o enviar (cifras del mes, últimos 6 meses,
  comisiones pagadas / pendientes, gastos y servicios).
- **Excel (.xlsx)**: una hoja por tema (*Resumen*, *Servicios*, *Gastos*,
  *Comisiones*) con números de verdad para sumar o filtrar.

En el navegador se descarga; en Windows y en el celular se abre "Guardar como".

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
│   ├── constants/                Colores, catálogo de servicios y de marcas
│   ├── navigation/app_section.dart  Las 6 secciones del menú
│   ├── reports/                  Resumen mensual en PDF y Excel (y cómo guardarlo)
│   ├── theme/app_theme.dart      Tema oscuro
│   └── utils/                    validators · formatters · snackbar · fotos
├── models/                       Clases de datos (sin interfaz) y roles
├── data/
│   ├── api_client.dart           Cliente HTTP: token, errores, tiempo de espera
│   ├── auth_repository.dart      Login, contraseña y usuarios
│   ├── session_store.dart        Sesión guardada y cifrada en el dispositivo
│   └── workshop_repository.dart  Servicios, empleados, clientes, gastos y comisiones
├── state/
│   ├── auth_controller.dart      Sesión (guardar / recuperar) y cuentas
│   └── workshop_controller.dart  Servicios, clientes, gastos, comisiones y resumen mensual
├── screens/
│   ├── login/login_screen.dart
│   └── dashboard/                Panel + una sección por archivo
└── widgets/                      Tarjetas, menú y diálogos reutilizables

test/                             Validadores, cliente HTTP, controladores y
                                  pantallas (con un servidor simulado en memoria)
backend/
├── AlingBalance.Api/             Servidor (controladores, dominio, datos, seguridad)
│   ├── Migrations/               Cambios de esquema (uno por motor: Sqlite y SqlServer)
│   └── alingbalance.db           Base de datos SQLite lista para usar
└── AlingBalance.Api.Tests/       Pruebas del servidor
database/                         Scripts SQL (SQLite y SQL Server), datos de ejemplo,
                                  consultas y diagrama → ver database/README.md
```

Flujo: los widgets solo dibujan → los controladores guardan el estado y las
reglas → los repositorios hablan con la API → el servidor valida y guarda en la
base de datos.
