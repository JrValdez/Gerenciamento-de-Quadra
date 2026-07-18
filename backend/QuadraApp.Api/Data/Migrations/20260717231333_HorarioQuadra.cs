using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuadraApp.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class HorarioQuadra : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<int>(
                name: "HoraAbertura",
                table: "Quadras",
                type: "integer",
                nullable: false,
                defaultValue: 8);

            migrationBuilder.AddColumn<int>(
                name: "HoraFechamento",
                table: "Quadras",
                type: "integer",
                nullable: false,
                defaultValue: 22);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "HoraAbertura",
                table: "Quadras");

            migrationBuilder.DropColumn(
                name: "HoraFechamento",
                table: "Quadras");
        }
    }
}
