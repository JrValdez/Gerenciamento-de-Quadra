using Microsoft.EntityFrameworkCore;
using Npgsql;

namespace QuadraApp.Api.Infra;

/// <summary>
/// Traduz erros específicos do PostgreSQL (lançados via <see cref="DbUpdateException"/>)
/// para condições de negócio, permitindo responder 409 em vez de vazar um 500.
/// </summary>
public static class PgErros
{
    // SQLSTATE do PostgreSQL: 23505 = unique_violation, 23P01 = exclusion_violation.
    public static bool EhViolacaoUnica(DbUpdateException ex) =>
        ex.InnerException is PostgresException { SqlState: "23505" };

    public static bool EhOverlap(DbUpdateException ex) =>
        ex.InnerException is PostgresException { SqlState: "23P01" };
}
