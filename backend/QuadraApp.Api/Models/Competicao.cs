using System.ComponentModel.DataAnnotations;

namespace QuadraApp.Api.Models;

/// <summary>Modalidade esportiva da competição (Beach Tennis, Vôlei, Futvôlei...).</summary>
public class Modalidade
{
    public Guid Id { get; set; } = Guid.NewGuid();

    [MaxLength(80)]
    public string Nome { get; set; } = string.Empty;

    public bool Ativa { get; set; } = true;

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;

    public ICollection<Competidor> Competidores { get; set; } = new List<Competidor>();
}

/// <summary>
/// Um competidor na classificação de uma modalidade. Pode ser um aluno
/// (individual) ou uma equipe/dupla com vários alunos.
/// </summary>
public class Competidor
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid ModalidadeId { get; set; }
    public Modalidade? Modalidade { get; set; }

    public TipoCompetidor Tipo { get; set; }

    /// <summary>Nome exibido: nome do aluno (individual) ou da equipe.</summary>
    [MaxLength(120)]
    public string Nome { get; set; } = string.Empty;

    public bool Ativo { get; set; } = true;

    public DateTime CriadoEm { get; set; } = DateTime.UtcNow;

    public ICollection<CompetidorMembro> Membros { get; set; } = new List<CompetidorMembro>();
    public ICollection<LancamentoPonto> Lancamentos { get; set; } = new List<LancamentoPonto>();
}

/// <summary>Vínculo de um aluno a um competidor (1 para individual, N para equipe).</summary>
public class CompetidorMembro
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid CompetidorId { get; set; }
    public Competidor? Competidor { get; set; }

    public Guid AlunoId { get; set; }
    public ApplicationUser? Aluno { get; set; }

    [MaxLength(120)]
    public string AlunoNome { get; set; } = string.Empty;
}

/// <summary>Lançamento manual de pontos para um competidor (evento pontuado).</summary>
public class LancamentoPonto
{
    public Guid Id { get; set; } = Guid.NewGuid();

    public Guid CompetidorId { get; set; }
    public Competidor? Competidor { get; set; }

    public Guid ModalidadeId { get; set; }

    public int Pontos { get; set; }

    [MaxLength(200)]
    public string Motivo { get; set; } = string.Empty;

    public DateTime Data { get; set; } = DateTime.UtcNow;

    public Guid RegistradoPorUserId { get; set; }
}
