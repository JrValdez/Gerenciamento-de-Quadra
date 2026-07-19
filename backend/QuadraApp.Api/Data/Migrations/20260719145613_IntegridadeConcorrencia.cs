using Microsoft.EntityFrameworkCore.Migrations;

#nullable disable

namespace QuadraApp.Api.Data.Migrations
{
    /// <summary>
    /// Garantias de integridade no nível do banco, à prova de concorrência:
    ///  - Agendamentos: constraint de exclusão que impede dois agendamentos ativos
    ///    (status &lt;&gt; Cancelado) da mesma quadra com horários que se sobrepõem.
    ///  - Caixas: índice único parcial que garante no máximo um caixa Aberto por vez.
    /// A baixa de estoque atômica é feita na aplicação (UPDATE com guarda), sem schema.
    /// </summary>
    public partial class IntegridadeConcorrencia : Migration
    {
        /// <inheritdoc />
        protected override void Up(MigrationBuilder migrationBuilder)
        {
            // btree_gist permite combinar igualdade (QuadraId) com o operador de
            // sobreposição de intervalos (&&) dentro de um índice/constraint gist.
            migrationBuilder.Sql("CREATE EXTENSION IF NOT EXISTS btree_gist;");

            // Anti-overbooking: mesma quadra + faixas [Inicio, Fim) que se cruzam é proibido.
            // Status 3 = Cancelado fica de fora (reserva cancelada não ocupa horário).
            migrationBuilder.Sql(@"
                ALTER TABLE ""Agendamentos""
                ADD CONSTRAINT ""ck_agendamentos_sem_overlap""
                EXCLUDE USING gist (
                    ""QuadraId"" WITH =,
                    tstzrange(""Inicio"", ""Fim"") WITH &&
                )
                WHERE (""Status"" <> 3);");

            // Um único caixa aberto: Status 0 = Aberto. O índice parcial só cobre
            // as linhas abertas, então múltiplos caixas fechados continuam válidos.
            migrationBuilder.Sql(@"
                CREATE UNIQUE INDEX ""ix_caixa_unico_aberto""
                ON ""Caixas"" (""Status"")
                WHERE (""Status"" = 0);");
        }

        /// <inheritdoc />
        protected override void Down(MigrationBuilder migrationBuilder)
        {
            migrationBuilder.Sql(@"DROP INDEX IF EXISTS ""ix_caixa_unico_aberto"";");
            migrationBuilder.Sql(@"ALTER TABLE ""Agendamentos"" DROP CONSTRAINT IF EXISTS ""ck_agendamentos_sem_overlap"";");
            // A extensão btree_gist não é removida: pode estar em uso por outros objetos.
        }
    }
}
