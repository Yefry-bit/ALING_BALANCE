using System.Text;
using System.Threading.RateLimiting;
using AlingBalance.Api.Data;
using AlingBalance.Api.Security;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.RateLimiting;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;

var builder = WebApplication.CreateBuilder(args);

// ------------------------------------------------------------- Configuración
var jwt = builder.Configuration.GetSection("Jwt").Get<JwtOptions>() ?? new JwtOptions();

if (string.IsNullOrWhiteSpace(jwt.Key) || jwt.Key.Length < 32)
{
    throw new InvalidOperationException("Jwt:Key debe tener al menos 32 caracteres.");
}

if (!builder.Environment.IsDevelopment() && jwt.Key.StartsWith("cambia-esta-clave", StringComparison.Ordinal))
{
    throw new InvalidOperationException(
        "Define una clave secreta propia en Jwt:Key (variable de entorno Jwt__Key) antes de publicar.");
}

builder.Services.Configure<JwtOptions>(builder.Configuration.GetSection("Jwt"));

// ------------------------------------------------------------- Base de datos
var provider = builder.Configuration["Database:Provider"] ?? "Sqlite";
var connectionString = builder.Configuration.GetConnectionString("Default") ?? "Data Source=alingbalance.db";

builder.Services.AddDbContext<AppDbContext>(options =>
{
    if (provider.Equals("SqlServer", StringComparison.OrdinalIgnoreCase))
    {
        options.UseSqlServer(connectionString);
    }
    else
    {
        options.UseSqlite(connectionString);
    }
});

// ----------------------------------------------------------------- Servicios
builder.Services.AddSingleton<PasswordService>();
builder.Services.AddSingleton<TokenService>();
builder.Services.AddControllers();

// CORS: necesario para que la app Flutter web (Edge/Chrome) pueda llamar a la API.
// La app móvil no lo necesita. Sin orígenes configurados se permite cualquiera
// (la API usa token en el encabezado, no cookies); en producción, define
// "Cors:Origins" con la dirección real de tu app web.
var allowedOrigins = builder.Configuration.GetSection("Cors:Origins").Get<string[]>() ?? Array.Empty<string>();
builder.Services.AddCors(options =>
{
    options.AddPolicy("app", policy =>
    {
        if (allowedOrigins.Length > 0)
        {
            policy.WithOrigins(allowedOrigins);
        }
        else
        {
            policy.AllowAnyOrigin();
        }

        policy.AllowAnyHeader().AllowAnyMethod();
    });
});
builder.Services.AddProblemDetails();

builder.Services
    .AddAuthentication(JwtBearerDefaults.AuthenticationScheme)
    .AddJwtBearer(options =>
    {
        // Mantiene los nombres de claim del token ("sub", "name", "role").
        options.MapInboundClaims = false;
        options.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidIssuer = jwt.Issuer,
            ValidateAudience = true,
            ValidAudience = jwt.Audience,
            ValidateIssuerSigningKey = true,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.Key)),
            ValidateLifetime = true,
            ClockSkew = TimeSpan.FromMinutes(1),
            NameClaimType = "name",
            RoleClaimType = "role",
        };

        // Si desactivan la cuenta mientras la sesión está abierta, el token deja de servir.
        options.Events = new JwtBearerEvents
        {
            OnTokenValidated = async context =>
            {
                var db = context.HttpContext.RequestServices.GetRequiredService<AppDbContext>();
                var userId = context.Principal?.GetUserId() ?? 0;
                var stillActive = await db.Users.AsNoTracking().AnyAsync(u => u.Id == userId && u.Active);

                if (!stillActive)
                {
                    context.Fail("La cuenta no existe o está desactivada.");
                }
            },
        };
    });

builder.Services.AddAuthorization();

// Máximo 10 intentos de inicio de sesión por minuto desde la misma dirección.
builder.Services.AddRateLimiter(options =>
{
    options.RejectionStatusCode = StatusCodes.Status429TooManyRequests;
    options.AddPolicy("login", httpContext =>
        RateLimitPartition.GetFixedWindowLimiter(
            httpContext.Connection.RemoteIpAddress?.ToString() ?? "desconocida",
            _ => new FixedWindowRateLimiterOptions
            {
                PermitLimit = 10,
                Window = TimeSpan.FromMinutes(1),
                QueueLimit = 0,
            }));
});

var app = builder.Build();

// --------------------------------------------------- Crear base de datos y admin
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<AppDbContext>();
    await db.Database.EnsureCreatedAsync();

    // Bases creadas con una versión anterior: agrega Clientes, Vehículos y Gastos.
    await SchemaUpgrader.UpgradeAsync(db);

    await DbSeeder.SeedAsync(
        db,
        app.Configuration,
        scope.ServiceProvider.GetRequiredService<PasswordService>());
}

// ------------------------------------------------------------------ Pipeline
app.UseExceptionHandler();
app.UseStatusCodePages();
app.UseCors("app");
app.UseRateLimiter();
app.UseAuthentication();
app.UseAuthorization();

app.MapControllers();
app.MapGet("/health", () => Results.Ok(new { status = "ok" }));

app.Run();
