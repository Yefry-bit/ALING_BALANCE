using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace AlingBalance.Api.Migrations.Sqlite
{
    /// <inheritdoc />
    public partial class ComisionesGastosFijosYSesiones : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "SecurityStamp",
                table: "Users",
                type: "TEXT",
                maxLength: 40,
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "CommissionPaymentId",
                table: "Services",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.AddColumn<int>(
                name: "RecurringExpenseId",
                table: "Expenses",
                type: "INTEGER",
                nullable: true);

            migrationBuilder.CreateTable(
                name: "CommissionPayments",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    EmployeeId = table.Column<int>(type: "INTEGER", nullable: true),
                    EmployeeName = table.Column<string>(type: "TEXT", maxLength: 80, nullable: false),
                    Year = table.Column<int>(type: "INTEGER", nullable: false),
                    Month = table.Column<int>(type: "INTEGER", nullable: false),
                    Amount = table.Column<int>(type: "INTEGER", nullable: false),
                    ServiceCount = table.Column<int>(type: "INTEGER", nullable: false),
                    PaidAt = table.Column<DateTime>(type: "TEXT", nullable: false),
                    PaidBy = table.Column<string>(type: "TEXT", maxLength: 80, nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_CommissionPayments", x => x.Id);
                    table.CheckConstraint("CK_CommissionPayments_Amount", "[Amount] >= 0");
                    table.CheckConstraint("CK_CommissionPayments_Month", "[Month] BETWEEN 1 AND 12");
                    table.ForeignKey(
                        name: "FK_CommissionPayments_Employees_EmployeeId",
                        column: x => x.EmployeeId,
                        principalTable: "Employees",
                        principalColumn: "Id",
                        onDelete: ReferentialAction.SetNull);
                });

            migrationBuilder.CreateTable(
                name: "RecurringExpenses",
                columns: table => new
                {
                    Id = table.Column<int>(type: "INTEGER", nullable: false)
                        .Annotation("Sqlite:Autoincrement", true),
                    Description = table.Column<string>(type: "TEXT", maxLength: 80, nullable: false),
                    Category = table.Column<string>(type: "TEXT", maxLength: 40, nullable: false),
                    Amount = table.Column<int>(type: "INTEGER", nullable: false),
                    DayOfMonth = table.Column<int>(type: "INTEGER", nullable: false),
                    Active = table.Column<bool>(type: "INTEGER", nullable: false),
                    LastGeneratedMonth = table.Column<int>(type: "INTEGER", nullable: false),
                    RegisteredBy = table.Column<string>(type: "TEXT", maxLength: 80, nullable: false),
                    CreatedAt = table.Column<DateTime>(type: "TEXT", nullable: false)
                },
                constraints: table =>
                {
                    table.PrimaryKey("PK_RecurringExpenses", x => x.Id);
                    table.CheckConstraint("CK_RecurringExpenses_Amount", "[Amount] > 0");
                    table.CheckConstraint("CK_RecurringExpenses_Day", "[DayOfMonth] BETWEEN 1 AND 28");
                });

            migrationBuilder.CreateIndex(
                name: "IX_Services_CommissionPaymentId",
                table: "Services",
                column: "CommissionPaymentId");

            migrationBuilder.CreateIndex(
                name: "IX_Expenses_RecurringExpenseId_Date",
                table: "Expenses",
                columns: new[] { "RecurringExpenseId", "Date" },
                unique: true,
                filter: "[RecurringExpenseId] IS NOT NULL");

            migrationBuilder.CreateIndex(
                name: "IX_CommissionPayments_EmployeeId",
                table: "CommissionPayments",
                column: "EmployeeId");

            migrationBuilder.CreateIndex(
                name: "IX_CommissionPayments_Year_Month",
                table: "CommissionPayments",
                columns: new[] { "Year", "Month" });

            migrationBuilder.AddForeignKey(
                name: "FK_Expenses_RecurringExpenses_RecurringExpenseId",
                table: "Expenses",
                column: "RecurringExpenseId",
                principalTable: "RecurringExpenses",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);

            migrationBuilder.AddForeignKey(
                name: "FK_Services_CommissionPayments_CommissionPaymentId",
                table: "Services",
                column: "CommissionPaymentId",
                principalTable: "CommissionPayments",
                principalColumn: "Id",
                onDelete: ReferentialAction.SetNull);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropForeignKey(
                name: "FK_Expenses_RecurringExpenses_RecurringExpenseId",
                table: "Expenses");

            migrationBuilder.DropForeignKey(
                name: "FK_Services_CommissionPayments_CommissionPaymentId",
                table: "Services");

            migrationBuilder.DropTable(
                name: "CommissionPayments");

            migrationBuilder.DropTable(
                name: "RecurringExpenses");

            migrationBuilder.DropIndex(
                name: "IX_Services_CommissionPaymentId",
                table: "Services");

            migrationBuilder.DropIndex(
                name: "IX_Expenses_RecurringExpenseId_Date",
                table: "Expenses");

            migrationBuilder.DropColumn(
                name: "SecurityStamp",
                table: "Users");

            migrationBuilder.DropColumn(
                name: "CommissionPaymentId",
                table: "Services");

            migrationBuilder.DropColumn(
                name: "RecurringExpenseId",
                table: "Expenses");
        }
    }
}
