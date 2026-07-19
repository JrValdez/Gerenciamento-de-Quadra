namespace QuadraApp.Api.Infra;

/// <summary>
/// Paginação por página/tamanho, com defaults e teto para não devolver a tabela
/// inteira. A resposta continua sendo um array (compatível com o cliente); o total
/// de registros vai no cabeçalho <c>X-Total-Count</c> para o cliente saber que há mais.
/// </summary>
public readonly record struct Paginacao(int Page, int PageSize)
{
    public int Skip => (Page - 1) * PageSize;

    public static Paginacao De(int? page, int? pageSize, int padrao, int max)
    {
        var p = page is > 0 ? page.Value : 1;
        var s = Math.Clamp(pageSize ?? padrao, 1, max);
        return new Paginacao(p, s);
    }
}
