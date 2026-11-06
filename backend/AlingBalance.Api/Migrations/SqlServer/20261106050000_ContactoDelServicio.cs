using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AlingBalance.Api.Migrations.SqlServer
{
    /// <inheritdoc />
    public partial class ContactoDelServicio : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "ContactName",
                table: "Services",
                type: "nvarchar(80)",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ContactPhone",
                table: "Services",
                type: "nvarchar(10)",
                maxLength: 10,
                nullable: false,
                defaultValue: "");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "ContactName",
                table: "Services");

            migrationBuilder.DropColumn(
                name: "ContactPhone",
                table: "Services");
        }
    }
}
