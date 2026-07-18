using System.Security.Claims;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using QuadraApp.Api.DTOs;
using QuadraApp.Api.Models;

namespace QuadraApp.Api.Controllers;

[ApiController]
[Route("api/[controller]")]
public class ProfessoresController : ControllerBase
{
    private readonly UserManager<ApplicationUser> _userManager;
    public ProfessoresController(UserManager<ApplicationUser> userManager) => _userManager = userManager;

    private static ProfessorDto Map(ApplicationUser u) =>
        new(u.Id, u.NomeCompleto, u.Email ?? "", u.PrecoAula, u.Ativo);

    /// <summary>Lista os professores e o preço de aula de cada um. Admin/Atendente.</summary>
    [HttpGet]
    [Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
    public async Task<ActionResult<IEnumerable<ProfessorDto>>> Listar()
    {
        var profs = await _userManager.GetUsersInRoleAsync(Roles.Professor);
        var lista = profs.OrderBy(p => p.NomeCompleto).Select(Map);
        return Ok(lista);
    }

    /// <summary>Preço de aula do professor autenticado.</summary>
    [HttpGet("me")]
    [Authorize(Roles = Roles.Professor)]
    public async Task<ActionResult<ProfessorDto>> Me()
    {
        var id = User.FindFirstValue(ClaimTypes.NameIdentifier);
        if (id is null) return Unauthorized();
        var user = await _userManager.FindByIdAsync(id);
        return user is null ? Unauthorized() : Ok(Map(user));
    }

    /// <summary>Define o preço por hora da aula de um professor. Admin/Atendente.</summary>
    [HttpPut("{id:guid}/preco")]
    [Authorize(Roles = $"{Roles.Admin},{Roles.Atendente}")]
    public async Task<ActionResult<ProfessorDto>> DefinirPreco(Guid id, PrecoAulaRequest req)
    {
        var user = await _userManager.FindByIdAsync(id.ToString());
        if (user is null) return NotFound();
        if (!await _userManager.IsInRoleAsync(user, Roles.Professor))
            return BadRequest(new { erro = "Usuário não é professor." });

        user.PrecoAula = req.PrecoAula;
        await _userManager.UpdateAsync(user);
        return Ok(Map(user));
    }

    /// <summary>Cria um usuário da categoria Aluno. Somente professores.</summary>
    [HttpPost("alunos")]
    [Authorize(Roles = Roles.Professor)]
    public async Task<ActionResult<AlunoDto>> CriarAluno(CriarAlunoRequest req)
    {
        if (await _userManager.FindByEmailAsync(req.Email) is not null)
            return Conflict(new { erro = "E-mail já cadastrado." });

        var user = new ApplicationUser
        {
            UserName = req.Email,
            Email = req.Email,
            EmailConfirmed = true,
            NomeCompleto = req.NomeCompleto,
            PhoneNumber = req.Telefone,
        };

        var result = await _userManager.CreateAsync(user, req.Senha);
        if (!result.Succeeded)
            return BadRequest(new { erro = string.Join("; ", result.Errors.Select(e => e.Description)) });

        await _userManager.AddToRoleAsync(user, Roles.Aluno);
        return Ok(new AlunoDto(user.Id, user.NomeCompleto, user.Email!, user.PhoneNumber));
    }
}
