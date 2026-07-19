using Microsoft.AspNetCore.Diagnostics;

namespace QuadraApp.Api.Infra;

/// <summary>
/// Captura exceções não tratadas, registra no log e responde um JSON consistente
/// (<c>{ erro }</c>) — sem vazar stack trace em produção. Mantém o mesmo formato de
/// erro que os controllers já usam, para o cliente conseguir exibir a mensagem.
/// </summary>
public sealed class GlobalExceptionHandler : IExceptionHandler
{
    private readonly ILogger<GlobalExceptionHandler> _logger;
    private readonly IHostEnvironment _env;

    public GlobalExceptionHandler(ILogger<GlobalExceptionHandler> logger, IHostEnvironment env)
    {
        _logger = logger;
        _env = env;
    }

    public async ValueTask<bool> TryHandleAsync(
        HttpContext ctx, Exception ex, CancellationToken ct)
    {
        _logger.LogError(ex, "Erro não tratado em {Method} {Path}",
            ctx.Request.Method, ctx.Request.Path);

        ctx.Response.StatusCode = StatusCodes.Status500InternalServerError;
        var erro = _env.IsDevelopment()
            ? ex.Message
            : "Ocorreu um erro inesperado. Tente novamente.";
        await ctx.Response.WriteAsJsonAsync(new { erro }, ct);
        return true;
    }
}
