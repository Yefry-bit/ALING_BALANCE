using AlingBalance.Api.Validation;
using Xunit;

namespace AlingBalance.Api.Tests;

public class RulesTests
{
    [Theory]
    [InlineData("abc123", "ABC-123")]
    [InlineData(" ABC 123 ", "ABC-123")]
    [InlineData("abc-123", "ABC-123")]
    public void NormalizePlate_da_formato_ABC_123(string raw, string expected)
    {
        Assert.Equal(expected, Rules.NormalizePlate(raw));
    }

    [Theory]
    [InlineData("ABC-123", true)]
    [InlineData("AB-1234", false)]
    [InlineData("ABCD-12", false)]
    [InlineData("", false)]
    public void CheckPlate_valida_el_formato(string plate, bool valid)
    {
        Assert.Equal(valid, Rules.CheckPlate(plate) is null);
    }

    [Theory]
    [InlineData("Carlos Pérez", true)]
    [InlineData("María-José O'Neil", true)]
    [InlineData("Al", false)]
    [InlineData("Carlos123", false)]
    [InlineData("", false)]
    public void CheckName_acepta_solo_nombres_validos(string name, bool valid)
    {
        Assert.Equal(valid, Rules.CheckName(name) is null);
    }

    [Theory]
    [InlineData("1234567890", true)]
    [InlineData("12345", true)]
    [InlineData("1234", false)]
    [InlineData("12AB567", false)]
    public void CheckDocument_exige_solo_numeros(string document, bool valid)
    {
        Assert.Equal(valid, Rules.CheckDocument(document) is null);
    }

    [Theory]
    [InlineData("", true)]
    [InlineData("3001234567", true)]
    [InlineData("6012345678", true)]
    [InlineData("1234567", true)]
    [InlineData("12345", false)]
    [InlineData("2001234567", false)]
    public void CheckPhone_es_opcional_pero_debe_ser_valido(string phone, bool valid)
    {
        Assert.Equal(valid, Rules.CheckPhone(phone) is null);
    }

    [Theory]
    [InlineData("+57 300 123 4567", "3001234567")]
    [InlineData("(300) 123-4567", "3001234567")]
    public void NormalizePhone_deja_solo_digitos(string raw, string expected)
    {
        Assert.Equal(expected, Rules.NormalizePhone(raw));
    }

    [Theory]
    [InlineData("maria", true)]
    [InlineData("maria.gomez_2", true)]
    [InlineData("ana", false)]
    [InlineData("maria gomez", false)]
    [InlineData("María", false)]
    public void CheckUsername_valida_longitud_y_caracteres(string username, bool valid)
    {
        Assert.Equal(valid, Rules.CheckUsername(username) is null);
    }

    [Theory]
    [InlineData("clave123", true)]
    [InlineData("corta1", false)]
    [InlineData("sololetras", false)]
    [InlineData("12345678", false)]
    [InlineData(null, false)]
    public void CheckPassword_exige_longitud_letra_y_numero(string? password, bool valid)
    {
        Assert.Equal(valid, Rules.CheckPassword(password) is null);
    }

    [Theory]
    [InlineData(1, true)]
    [InlineData(5_000_000, true)]
    [InlineData(0, false)]
    [InlineData(-5, false)]
    [InlineData(5_000_001, false)]
    public void CheckPrice_limita_el_rango(int price, bool valid)
    {
        Assert.Equal(valid, Rules.CheckPrice(price) is null);
    }

    [Theory]
    [InlineData("Chevrolet", true)]
    [InlineData("Spark GT", true)]
    [InlineData("CX-5", true)]
    [InlineData("A", false)]
    [InlineData("<script>", false)]
    public void CheckVehicleText_valida_marca_y_modelo(string value, bool valid)
    {
        Assert.Equal(valid, Rules.CheckVehicleText(value, "La marca") is null);
    }

    [Theory]
    [InlineData("Arriendo del local", true)]
    [InlineData("Luz", true)]
    [InlineData("Ab", false)]
    [InlineData("", false)]
    public void CheckExpenseDescription_exige_entre_3_y_80_caracteres(string value, bool valid)
    {
        Assert.Equal(valid, Rules.CheckExpenseDescription(value) is null);
    }

    [Fact]
    public void CheckExpenseDescription_rechaza_textos_largos()
    {
        Assert.NotNull(Rules.CheckExpenseDescription(new string('a', 81)));
    }

    [Theory]
    [InlineData(1, true)]
    [InlineData(50_000_000, true)]
    [InlineData(0, false)]
    [InlineData(-5, false)]
    [InlineData(50_000_001, false)]
    [InlineData(null, false)]
    public void CheckExpenseAmount_valida_el_rango(int? amount, bool valid)
    {
        Assert.Equal(valid, Rules.CheckExpenseAmount(amount) is null);
    }

    [Fact]
    public void DetectImageType_reconoce_jpeg_png_y_webp_por_su_contenido()
    {
        Assert.Equal("image/jpeg", Rules.DetectImageType(new byte[] { 0xFF, 0xD8, 0xFF, 0xE0, 0x00 }));
        Assert.Equal(
            "image/png",
            Rules.DetectImageType(new byte[] { 0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00 }));
        Assert.Equal(
            "image/webp",
            Rules.DetectImageType("RIFF\0\0\0\0WEBPVP8 "u8.ToArray()));
    }

    [Fact]
    public void DetectImageType_rechaza_archivos_que_no_son_imagenes()
    {
        Assert.Null(Rules.DetectImageType("<script>alert(1)</script>"u8.ToArray()));
        Assert.Null(Rules.DetectImageType("%PDF-1.7"u8.ToArray()));
        Assert.Null(Rules.DetectImageType("RIFF\0\0\0\0WAVEfmt "u8.ToArray()));
        Assert.Null(Rules.DetectImageType(Array.Empty<byte>()));
    }

    [Fact]
    public void CheckPhotoNote_limita_la_descripcion()
    {
        Assert.Null(Rules.CheckPhotoNote(""));
        Assert.Null(Rules.CheckPhotoNote(new string('a', 200)));
        Assert.NotNull(Rules.CheckPhotoNote(new string('a', 201)));
    }

    [Theory]
    [InlineData("2026-11-05", true)]   // hoy
    [InlineData("2026-11-06", true)]   // margen de un día por zona horaria
    [InlineData("2025-01-31", true)]
    [InlineData("2026-11-08", false)]  // futura
    [InlineData("1999-12-31", false)]
    [InlineData(null, false)]
    public void CheckExpenseDate_no_acepta_fechas_futuras(string? date, bool valid)
    {
        var today = new DateOnly(2026, 11, 5);
        DateOnly? value = date is null ? null : DateOnly.Parse(date);

        Assert.Equal(valid, Rules.CheckExpenseDate(value, today) is null);
    }
}
