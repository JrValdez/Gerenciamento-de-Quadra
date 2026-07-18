using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuadraApp.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class ProfessorPrecoAula : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<decimal>(
                name: "PrecoAula",
                table: "AspNetUsers",
                type: "numeric(10,2)",
                nullable: false,
                defaultValue: 0m);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "PrecoAula",
                table: "AspNetUsers");
        }
    }
}
