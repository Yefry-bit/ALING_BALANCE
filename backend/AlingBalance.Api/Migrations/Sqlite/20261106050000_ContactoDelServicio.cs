using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AlingBalance.Api.Migrations.Sqlite
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
                type: "TEXT",
                maxLength: 80,
                nullable: false,
                defaultValue: "");

            migrationBuilder.AddColumn<string>(
                name: "ContactPhone",
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
                name: "ContactName",
                table: "Services");

            migrationBuilder.DropColumn(
                name: "ContactPhone",
                table: "Services");
        }
    }
}
