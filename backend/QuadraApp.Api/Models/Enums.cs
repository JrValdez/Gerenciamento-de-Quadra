namespace QuadraApp.Api.Models;

/// <summary>Papéis de acesso do sistema. Usados como roles do ASP.NET Identity.</summary>
public static class Roles
{
    public const string Admin = "Admin";
    public const string Atendente = "Atendente";
    public const string Cliente = "Cliente";
    public const string Professor = "Professor";
    public const string Aluno = "Aluno";

    public static readonly string[] All = { Admin, Atendente, Cliente, Professor, Aluno };

    /// <summary>Papéis que podem gerenciar a competição (modalidades, competidores, pontos).</summary>
    public const string GestoresCompeticao = $"{Admin},{Atendente},{Professor}";
}

public enum TipoCompetidor
{
    Individual = 0,
    Equipe = 1
}

public enum StatusAgendamento
{
    Pendente = 0,
    Confirmado = 1,
    Concluido = 2,
    Cancelado = 3
}

public enum TipoMovimentacao
{
    Entrada = 0,
    Saida = 1
}

public enum FormaPagamento
{
    Dinheiro = 0,
    Cartao = 1,
    Pix = 2
}

public enum StatusCaixa
{
    Aberto = 0,
    Fechado = 1
}

public enum TipoDesconto
{
    /// <summary>Desconto percentual sobre o valor (0-100).</summary>
    Percentual = 0,
    /// <summary>Desconto de valor fixo em reais.</summary>
    ValorFixo = 1
}
