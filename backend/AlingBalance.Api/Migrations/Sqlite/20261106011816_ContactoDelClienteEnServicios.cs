using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AlingBalance.Api.Migrations.Sqlite
{
    /// <inheritdoc />
    public partial class ContactoDelClienteEnServicios : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CustomerName",
                table: "Services",
                type: "TEXT",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "CustomerPhone",
                table: "Services",
                type: "TEXT",
                maxLength: 10,
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CustomerName",
                table: "Services");

            migrationBuilder.DropColumn(
                name: "CustomerPhone",
                table: "Services");
        }
    }
}
