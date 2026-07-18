using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Identity.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.Data;

public class AppDbContext : IdentityDbContext<ApplicationUser, IdentityRole<Guid>, Guid>
{
    public AppDbContext(DbContextOptions<AppDbContext> options) : base(options) { }

    public DbSet<Quadra> Quadras => Set<Quadra>();
    public DbSet<Agendamento> Agendamentos => Set<Agendamento>();
    public DbSet<Produto> Produtos => Set<Produto>();
    public DbSet<Caixa> Caixas => Set<Caixa>();
    public DbSet<MovimentacaoCaixa> MovimentacoesCaixa => Set<MovimentacaoCaixa>();
    public DbSet<Venda> Vendas => Set<Venda>();
    public DbSet<VendaItem> VendaItens => Set<VendaItem>();
    public DbSet<Modalidade> Modalidades => Set<Modalidade>();
    public DbSet<Competidor> Competidores => Set<Competidor>();
    public DbSet<CompetidorMembro> CompetidorMembros => Set<CompetidorMembro>();
    public DbSet<LancamentoPonto> LancamentosPonto => Set<LancamentoPonto>();
    public DbSet<Bloqueio> Bloqueios => Set<Bloqueio>();
    public DbSet<Cupom> Cupons => Set<Cupom>();

    protected override void OnModelCreating(ModelBuilder builder)
    {
        base.OnModelCreating(builder);

        builder.Entity<Quadra>(e =>
        {
            e.Property(q => q.PrecoHora).HasColumnType("numeric(10,2)");
            e.HasIndex(q => q.Ativa);
        });

        builder.Entity<Agendamento>(e =>
        {
            e.Property(a => a.ValorTotal).HasColumnType("numeric(10,2)");
            e.Property(a => a.ValorDesconto).HasColumnType("numeric(10,2)");
            e.HasOne(a => a.Quadra)
                .WithMany(q => q.Agendamentos)
                .HasForeignKey(a => a.QuadraId)
                .OnDelete(DeleteBehavior.Restrict);
            e.HasIndex(a => new { a.QuadraId, a.Inicio, a.Fim });
        });

        builder.Entity<Produto>(e =>
        {
            e.Property(p => p.Preco).HasColumnType("numeric(10,2)");
            e.HasIndex(p => p.Ativo);
        });

        builder.Entity<Caixa>(e =>
        {
            e.Property(c => c.ValorAbertura).HasColumnType("numeric(12,2)");
            e.Property(c => c.ValorFechamentoInformado).HasColumnType("numeric(12,2)");
            e.HasIndex(c => c.Status);
        });

        builder.Entity<MovimentacaoCaixa>(e =>
        {
            e.Property(m => m.Valor).HasColumnType("numeric(12,2)");
            e.HasOne(m => m.Caixa)
                .WithMany(c => c.Movimentacoes)
                .HasForeignKey(m => m.CaixaId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(m => m.CaixaId);
        });

        builder.Entity<Venda>(e =>
        {
            e.Property(v => v.Total).HasColumnType("numeric(12,2)");
            e.HasOne(v => v.Caixa)
                .WithMany()
                .HasForeignKey(v => v.CaixaId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<VendaItem>(e =>
        {
            e.Property(i => i.PrecoUnitario).HasColumnType("numeric(10,2)");
            e.Property(i => i.Subtotal).HasColumnType("numeric(12,2)");
            e.HasOne(i => i.Venda)
                .WithMany(v => v.Itens)
                .HasForeignKey(i => i.VendaId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(i => i.Produto)
                .WithMany()
                .HasForeignKey(i => i.ProdutoId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<Modalidade>(e =>
        {
            e.HasIndex(m => m.Ativa);
        });

        builder.Entity<Competidor>(e =>
        {
            e.HasOne(c => c.Modalidade)
                .WithMany(m => m.Competidores)
                .HasForeignKey(c => c.ModalidadeId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(c => new { c.ModalidadeId, c.Tipo });
        });

        builder.Entity<CompetidorMembro>(e =>
        {
            e.HasOne(cm => cm.Competidor)
                .WithMany(c => c.Membros)
                .HasForeignKey(cm => cm.CompetidorId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasOne(cm => cm.Aluno)
                .WithMany()
                .HasForeignKey(cm => cm.AlunoId)
                .OnDelete(DeleteBehavior.Restrict);
        });

        builder.Entity<LancamentoPonto>(e =>
        {
            e.HasOne(l => l.Competidor)
                .WithMany(c => c.Lancamentos)
                .HasForeignKey(l => l.CompetidorId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(l => l.ModalidadeId);
        });

        builder.Entity<Bloqueio>(e =>
        {
            e.HasOne(b => b.Quadra)
                .WithMany()
                .HasForeignKey(b => b.QuadraId)
                .OnDelete(DeleteBehavior.Cascade);
            e.HasIndex(b => new { b.QuadraId, b.Inicio, b.Fim });
        });

        builder.Entity<Cupom>(e =>
        {
            e.Property(c => c.Valor).HasColumnType("numeric(10,2)");
            e.HasIndex(c => c.Codigo).IsUnique();
            e.HasIndex(c => c.Ativo);
        });
    }
}
