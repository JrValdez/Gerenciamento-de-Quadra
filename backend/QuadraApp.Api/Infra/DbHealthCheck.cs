using Microsoft.Extensions.Diagnostics.HealthChecks;
using QuadraApp.Api.Data;

namespace QuadraApp.Api.Infra;

/// <summary>Health check de readiness: confirma que a API alcança o banco.</summary>
public sealed class DbHealthCheck : IHealthCheck
{
    private readonly AppDbContext _db;
    public DbHealthCheck(AppDbContext db) => _db = db;

    public async Task<HealthCheckResult> CheckHealthAsync(
        HealthCheckContext context, CancellationToken cancellationToken = default)
    {
        return await _db.Database.CanConnectAsync(cancellationToken)
            ? HealthCheckResult.Healthy()
            : HealthCheckResult.Unhealthy("Banco de dados indisponível.");
    }
}
