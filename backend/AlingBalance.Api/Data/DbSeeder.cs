using AlingBalance.Api.Domain;
using AlingBalance.Api.Security;
using Microsoft.EntityFrameworkCore;

namespace AlingBalance.Api.Data;

/// <summary>Crea el administrador inicial la primera vez que arranca el servidor.</summary>
public static class DbSeeder
{
    public static async Task SeedAsync(
        AppDbContext db, IConfiguration configuration, PasswordService passwords)
    {
        if (await db.Users.AnyAsync())
        {
            return;
        }

        var name = configuration["Seed:AdminName"] ?? "Administrador";
        var username = (configuration["Seed:AdminUsername"] ?? "admin").Trim().ToLowerInvariant();
        var password = configuration["Seed:AdminPassword"] ?? "admin123";

        db.Users.Add(new AppUser
        {
            Name = name,
            Username = username,
            PasswordHash = passwords.Hash(password),
            Role = Roles.Admin,
            Active = true,
            CreatedAt = DateTime.UtcNow,
        });

        await db.SaveChangesAsync();
    }
}
