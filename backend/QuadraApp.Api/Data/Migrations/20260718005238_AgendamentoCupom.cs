using System;
using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuadraApp.Api.Data.Migrations
{
    /// <inheritdoc />
    public partial class AgendamentoCupom : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.AddColumn<string>(
                name: "CupomCodigo",
                table: "Agendamentos",
                type: "character varying(40)",
                maxLength: 40,
                nullable: true);

            migrationBuilder.AddColumn<Guid>(
                name: "CupomId",
                table: "Agendamentos",
                type: "uuid",
                nullable: true);

            migrationBuilder.AddColumn<decimal>(
                name: "ValorDesconto",
                table: "Agendamentos",
                type: "numeric(10,2)",
                nullable: false,
                defaultValue: 0m);
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.DropColumn(
                name: "CupomCodigo",
                table: "Agendamentos");

            migrationBuilder.DropColumn(
                name: "CupomId",
                table: "Agendamentos");

            migrationBuilder.DropColumn(
                name: "ValorDesconto",
                table: "Agendamentos");
        }
    }
}
