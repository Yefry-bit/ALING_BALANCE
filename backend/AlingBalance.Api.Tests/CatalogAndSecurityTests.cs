using AlingBalance.Api.Catalog;
using AlingBalance.Api.Security;
using Xunit;

namespace AlingBalance.Api.Tests;

public class CatalogAndSecurityTests
{
    [Theory]
    [InlineData("Alineación sencilla", "Taxi", 15000)]
    [InlineData("Balanceo", "Camioneta", 50000)]
    [InlineData("Rines", "Particular", 50000)]
    public void El_catalogo_tiene_precios_fijos(string service, string vehicle, int expected)
    {
        Assert.True(ServiceCatalog.TryGetPrice(service, vehicle, out var price));
        Assert.Equal(expected, price);
    }

    [Fact]
    public void El_catalogo_rechaza_combinaciones_desconocidas()
    {
        Assert.False(ServiceCatalog.TryGetPrice("Pintura", "Taxi", out _));
        Assert.False(ServiceCatalog.TryGetPrice("Balanceo", "Moto", out _));
    }

    [Fact]
    public void Todas_las_combinaciones_del_catalogo_tienen_precio()
    {
        foreach (var service in ServiceCatalog.ServiceTypes)
        {
            foreach (var vehicle in ServiceCatalog.VehicleTypes)
            {
                Assert.True(ServiceCatalog.TryGetPrice(service, vehicle, out var price));
                Assert.True(price > 0);
            }
        }
    }

    [Fact]
    public void La_contrasena_se_guarda_con_hash_y_se_verifica()
    {
        var service = new PasswordService();

        var hash = service.Hash("clave1234");

        Assert.DoesNotContain("clave1234", hash);
        Assert.True(service.Verify("clave1234", hash));
        Assert.False(service.Verify("otraClave1", hash));
    }

    [Fact]
    public void Dos_hashes_de_la_misma_contrasena_son_distintos()
    {
        var service = new PasswordService();

        Assert.NotEqual(service.Hash("clave1234"), service.Hash("clave1234"));
    }

    [Fact]
    public void Un_hash_con_formato_invalido_no_verifica()
    {
        Assert.False(new PasswordService().Verify("clave1234", "no-es-un-hash"));
    }
}
