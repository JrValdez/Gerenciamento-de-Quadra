using Microsoft.EntityFrameworkCore;
using QuadraApp.Api.Data;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.Services;

/// <summary>
/// Regras de domínio de agendamento reaproveitadas pelos três fluxos de reserva
/// (público, interno e de professor): cálculo de valor, resolução de cupom e
/// checagem de conflito/bloqueio. Tira a lógica do controller e a torna testável —
/// os métodos de cálculo são puros e cobertos por testes de unidade.
/// </summary>
public class AgendamentoService
{
    private readonly AppDbContext _db;
    public AgendamentoService(AppDbContext db) => _db = db;

    /// <summary>Valor bruto de uma reserva: preço/hora × horas, arredondado a 2 casas.</summary>
    public static decimal CalcularValor(decimal precoHora, DateTime inicio, DateTime fim)
    {
        var horas = (decimal)(fim - inicio).TotalHours;
        return Math.Round(precoHora * horas, 2);
    }

    /// <summary>
    /// Desconto de um cupom sobre um valor bruto. Percentual aplica a taxa; valor fixo
    /// abate direto. O desconto nunca ultrapassa o valor bruto.
    /// </summary>
    public static decimal CalcularDesconto(TipoDesconto tipo, decimal valorCupom, decimal bruto)
    {
        var desconto = tipo == TipoDesconto.Percentual
            ? Math.Round(bruto * valorCupom / 100m, 2)
            : valorCupom;
        return desconto > bruto ? bruto : desconto;
    }

    /// <summary>True se já existe reserva ativa sobrepondo o intervalo na mesma quadra.</summary>
    public Task<bool> ExisteConflitoAsync(Guid quadraId, DateTime inicio, DateTime fim, Guid? ignorarId = null) =>
        _db.Agendamentos.AnyAsync(a =>
            a.QuadraId == quadraId &&
            a.Status != StatusAgendamento.Cancelado &&
            (ignorarId == null || a.Id != ignorarId) &&
            inicio < a.Fim && a.Inicio < fim);

    /// <summary>True se há bloqueio da quadra sobrepondo o intervalo.</summary>
    public Task<bool> ExisteBloqueioAsync(Guid quadraId, DateTime inicio, DateTime fim) =>
        _db.Bloqueios.AnyAsync(b =>
            b.QuadraId == quadraId && inicio < b.Fim && b.Inicio < fim);

    /// <summary>
    /// Resolve e valida um cupom para um valor bruto. Retorna o cupom, o desconto a
    /// abater e uma mensagem de erro (quando o código foi informado mas é inválido).
    /// </summary>
    public async Task<(Cupom? cupom, decimal desconto, string? erro)> ResolverCupomAsync(
        string? codigo, decimal bruto)
    {
        if (string.IsNullOrWhiteSpace(codigo)) return (null, 0m, null);

        var cod = codigo.Trim().ToUpperInvariant();
        var cupom = await _db.Cupons.FirstOrDefaultAsync(c => c.Codigo == cod);
        if (cupom is null) return (null, 0m, "Cupom não encontrado.");
        if (!cupom.Ativo) return (null, 0m, "Cupom inativo.");
        if (cupom.ValidoAte < DateTime.UtcNow) return (null, 0m, "Cupom expirado.");

        return (cupom, CalcularDesconto(cupom.Tipo, cupom.Valor, bruto), null);
    }
}
