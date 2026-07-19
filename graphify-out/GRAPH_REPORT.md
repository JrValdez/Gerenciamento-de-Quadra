# Graph Report - .  (2026-07-19)

## Corpus Check
- Corpus is ~41,497 words - fits in a single context window. You may not need a graph.

## Summary
- 1258 nodes · 1954 edges · 73 communities (43 shown, 30 thin omitted)
- Extraction: 99% EXTRACTED · 1% INFERRED · 0% AMBIGUOUS · INFERRED: 12 edges (avg confidence: 0.81)
- Token cost: 41,852 input · 0 output

## Community Hubs (Navigation)
- Modelos de Dados (Flutter)
- Cliente HTTP da API
- DbContext & Entidades (EF Core)
- AuthProvider (Estado de Login)
- Endpoints REST (Controllers)
- Controllers da API
- Tela de Competição
- Análise de Caixa (API)
- Estados de Telas (Flutter)
- Tela de Reserva Pública
- Endpoints CRUD (Controllers)
- Tela de Produtos/Vendas
- Endpoints com Patch (Controllers)
- Tela de Usuários
- Tela de Reservar Aula
- Endpoints Públicos (Controllers)
- Tela de Análise / Shell Aluno
- Tela de Bloqueios
- Arquitetura de Deploy (Docker/nginx)
- Tema Visual (theme.dart)
- Tela de Cupons
- Índice de Telas (screens)
- Tela de Alunos
- Tela de Caixa
- Endpoints CRUD (Controllers)
- Tela de Quadras
- Endpoints de Listagem
- Fluxo de Caixa (API)
- Endpoints CRUD (Controllers)
- Tela de Login
- Endpoints de Consulta
- Tela de Professores
- Configuração de Execução (.NET)
- Bootstrap do App (main.dart)
- Tela de Dashboard
- Manifesto Web (PWA)
- Migrações Iniciais (EF)
- Projeto & Dependências (.NET)
- Rotas & Shell do Aluno
- Migração InitialCreate
- Migração Competição
- Migração HorárioQuadra
- Migração Bloqueios
- Migração RemoveTipoQuadra
- Migração Cupons
- Migração AgendamentoCupom
- Migração ProfessorPrecoAula
- Snapshot do Modelo (EF)
- Designer Competição
- Designer HorárioQuadra
- Designer RemoveTipoQuadra
- Designer Cupons
- Designer AgendamentoCupom
- Designer ProfessorPrecoAula
- Rotas de Navegação
- Testes de Widget
- Exceções da API (Frontend)
- Config da URL da API
- Ícone do App 512
- Ícone Maskable 192
- Ícone Maskable 512
- Tipo Caixa
- Tipo Competidor
- Tipo Cupom
- Tipo DashboardResumo
- Tipo DateTime
- Tipo int?
- Tipo List
- Tipo Modalidade
- Tipo Produto
- Tipo Quadra
- Tipo String?
- Níveis de Acesso (RBAC)

## God Nodes (most connected - your core abstractions)
1. `ApiClient` - 35 edges
2. `QuadraApp.Api.Models` - 33 edges
3. `AppDbContext` - 32 edges
4. `AuthProvider` - 27 edges
5. `QuadraApp.Api.DTOs` - 25 edges
6. `QuadraApp.Api.Data` - 24 edges
7. `AgendamentosController` - 18 edges
8. `QuadraApp.Api.Data.Migrations` - 17 edges
9. `AuthController` - 16 edges
10. `CompeticaoController` - 15 edges

## Surprising Connections (you probably didn't know these)
- `Servico db (postgres:17-alpine) [prod]` --semantically_similar_to--> `Servico db quadra-db (dev)`  [INFERRED] [semantically similar]
  deploy/docker-compose.prod.yml → docker-compose.yml
- `http (cliente HTTP)` --references--> `Backend ASP.NET Core (.NET 10)`  [INFERRED]
  frontend/quadra_app/pubspec.yaml → README.md
- `quadra_app (Flutter package)` --implements--> `Frontend Flutter Web`  [INFERRED]
  frontend/quadra_app/pubspec.yaml → README.md
- `Servico db quadra-db (dev)` --implements--> `PostgreSQL Database`  [INFERRED]
  docker-compose.yml → README.md
- `shared_preferences (login persistente)` --conceptually_related_to--> `Autenticacao ASP.NET Identity + JWT`  [INFERRED]
  frontend/quadra_app/pubspec.yaml → README.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Stack de producao Docker Compose (db+api+web)** — deploy_docker_compose_prod_db, deploy_docker_compose_prod_api, deploy_docker_compose_prod_web [EXTRACTED 1.00]
- **Arquitetura tres camadas (Flutter + .NET + PostgreSQL)** — readme_frontend_flutter_web, readme_backend_aspnet, readme_postgresql [INFERRED 0.85]

## Communities (73 total, 30 thin omitted)

### Community 0 - "Modelos de Dados (Flutter)"
Cohesion: 0.02
Nodes (112): double?, aberto, abertoEm, Agendamento, agendamentosHoje, agendamentosPendentes, alunoId, alunoNome (+104 more)

### Community 1 - "Cliente HTTP da API"
Cohesion: 0.03
Nodes (70): config.dart, dart:convert, abrirCaixa, agendamentos, agendarPublico, alterarStatusAgendamento, alunos, analiseCaixa (+62 more)

### Community 2 - "DbContext & Entidades (EF Core)"
Cohesion: 0.06
Nodes (42): Guid, ModelBuilder, AppDbContext, DateTime, Guid, ApplicationUser, DateTime, Guid (+34 more)

### Community 3 - "AuthProvider (Estado de Login)"
Cohesion: 0.04
Nodes (43): bool get, api, _carregando, _kToken, logado, login, logout, tryRestore (+35 more)

### Community 4 - "Endpoints REST (Controllers)"
Cohesion: 0.11
Nodes (28): ActionResult, AllowAnonymous, Authorize, DateTime, Guid, HttpGet, HttpPatch, HttpPost (+20 more)

### Community 5 - "Controllers da API"
Cohesion: 0.10
Nodes (21): ActionResult, Guid, HttpGet, HttpPost, IEnumerable, Task, VendasController, Task (+13 more)

### Community 6 - "Tela de Competição"
Cohesion: 0.05
Nodes (40): classificacao_view.dart, _adicionar, _alunos, api, build, _carregando, _carregar, _carregarAlunos (+32 more)

### Community 7 - "Análise de Caixa (API)"
Cohesion: 0.07
Nodes (31): ActionResult, HttpGet, int, Task, AnaliseController, ActionResult, HttpGet, int (+23 more)

### Community 8 - "Estados de Telas (Flutter)"
Cohesion: 0.10
Nodes (35): ApiClient, AgendamentosScreen, _AgendamentosScreenState, AnaliseScreen, _AnaliseScreenState, CaixaScreen, _CaixaScreenState, ClassificacaoView (+27 more)

### Community 9 - "Tela de Reserva Pública"
Cohesion: 0.06
Nodes (34): api, _aplicarCupom, _bruto, _carregandoQuadras, _carregandoSlots, _carregarQuadras, _carregarSlots, _confirmar (+26 more)

### Community 10 - "Endpoints CRUD (Controllers)"
Cohesion: 0.15
Nodes (21): ActionResult, AllowAnonymous, Authorize, Guid, HttpDelete, HttpGet, HttpPost, HttpPut (+13 more)

### Community 11 - "Tela de Produtos/Vendas"
Cohesion: 0.06
Nodes (32): api, _ativo, _card, _carregando, _carregar, _carrinho, _cat, createState (+24 more)

### Community 12 - "Endpoints com Patch (Controllers)"
Cohesion: 0.15
Nodes (21): ActionResult, Authorize, Guid, HttpDelete, HttpGet, HttpPatch, HttpPost, HttpPut (+13 more)

### Community 13 - "Tela de Usuários"
Cohesion: 0.06
Nodes (31): api, _barraFiltro, build, _carregando, _carregar, createState, dispose, _email (+23 more)

### Community 14 - "Tela de Reservar Aula"
Cohesion: 0.07
Nodes (29): double get, Slot, api, build, _cabecalhoPreco, _carregando, _carregandoSlots, _carregarSlots (+21 more)

### Community 15 - "Endpoints Públicos (Controllers)"
Cohesion: 0.13
Nodes (19): ActionResult, AllowAnonymous, Authorize, Guid, HttpDelete, HttpGet, HttpPost, HttpPut (+11 more)

### Community 16 - "Tela de Análise / Shell Aluno"
Cohesion: 0.07
Nodes (28): Color, QuadraApp, AnaliseCaixa, AlunoShell, api, _barra, _blocoCategorias, _blocoFormas (+20 more)

### Community 17 - "Tela de Bloqueios"
Cohesion: 0.08
Nodes (27): api, _BloqueioDialog, _BloqueioDialogState, BloqueiosScreen, _BloqueiosScreenState, build, _card, _carregando (+19 more)

### Community 18 - "Arquitetura de Deploy (Docker/nginx)"
Cohesion: 0.11
Nodes (27): DbSeeder (migracoes automaticas), Reverse proxy nginx por subdominio, Deploy Stack (Docker Compose producao), Container web faz proxy de /api (sem CORS), Servico api (.NET) [prod], Servico db (postgres:17-alpine) [prod], Servico web (Flutter/nginx) [prod], Servico db quadra-db (dev) (+19 more)

### Community 19 - "Tema Visual (theme.dart)"
Cohesion: 0.08
Nodes (25): amber, appTheme, base, bg, body, border, Brand, _build (+17 more)

### Community 20 - "Tela de Cupons"
Cohesion: 0.08
Nodes (24): cupom, api, _ativo, _card, _carregando, _carregar, _codigo, createState (+16 more)

### Community 21 - "Índice de Telas (screens)"
Cohesion: 0.09
Nodes (23): agendamentos_screen.dart, alunos_screen.dart, analise_screen.dart, bloqueios_screen.dart, caixa_screen.dart, competicao/competicao_screen.dart, cupons_screen.dart, dashboard_screen.dart (+15 more)

### Community 22 - "Tela de Alunos"
Cohesion: 0.09
Nodes (22): _AlunoDialog, _AlunoDialogState, AlunosScreen, _AlunosScreenState, api, build, _carregando, _carregar (+14 more)

### Community 23 - "Tela de Caixa"
Cohesion: 0.09
Nodes (22): _abrir, api, build, _caixa, _carregando, _carregar, createState, _desc (+14 more)

### Community 24 - "Endpoints CRUD (Controllers)"
Cohesion: 0.17
Nodes (15): ActionResult, AllowAnonymous, Authorize, Guid, HttpDelete, HttpGet, HttpPost, HttpPut (+7 more)

### Community 25 - "Tela de Quadras"
Cohesion: 0.09
Nodes (21): _abertura, api, _ativa, _card, _carregando, _carregar, createState, dispose (+13 more)

### Community 26 - "Endpoints de Listagem"
Cohesion: 0.14
Nodes (14): ActionResult, Guid, HttpDelete, HttpGet, HttpPost, IActionResult, IEnumerable, Task (+6 more)

### Community 27 - "Fluxo de Caixa (API)"
Cohesion: 0.23
Nodes (12): ActionResult, Guid, HttpGet, HttpPost, IEnumerable, Task, CaixaController, AbrirCaixaRequest (+4 more)

### Community 28 - "Endpoints CRUD (Controllers)"
Cohesion: 0.17
Nodes (14): ActionResult, Authorize, Guid, HttpDelete, HttpGet, HttpPost, HttpPut, IActionResult (+6 more)

### Community 29 - "Tela de Login"
Cohesion: 0.11
Nodes (20): ChangeNotifier, FormState, AuthProvider, build, build, build, createState, dispose (+12 more)

### Community 30 - "Endpoints de Consulta"
Cohesion: 0.18
Nodes (14): ActionResult, Authorize, Guid, HttpGet, HttpPost, HttpPut, IEnumerable, Task (+6 more)

### Community 31 - "Tela de Professores"
Cohesion: 0.12
Nodes (17): Professor, api, build, _carregando, _carregar, createState, dispose, _editarPreco (+9 more)

### Community 32 - "Configuração de Execução (.NET)"
Cohesion: 0.13
Nodes (15): ASPNETCORE_ENVIRONMENT, applicationUrl, commandName, dotnetRunMessages, environmentVariables, launchBrowser, applicationUrl, commandName (+7 more)

### Community 33 - "Bootstrap do App (main.dart)"
Cohesion: 0.12
Nodes (15): api, auth, build, initializeDateFormatting, main, null, restaurado, rota (+7 more)

### Community 34 - "Tela de Dashboard"
Cohesion: 0.17
Nodes (11): ../api_client.dart, api, build, _carregando, _carregar, createState, _erro, initState (+3 more)

### Community 35 - "Manifesto Web (PWA)"
Cohesion: 0.18
Nodes (10): background_color, description, display, icons, name, orientation, prefer_related_applications, short_name (+2 more)

### Community 36 - "Migrações Iniciais (EF)"
Cohesion: 0.20
Nodes (5): ModelBuilder, InitialCreate, ModelBuilder, Bloqueios, QuadraApp.Api.Data.Migrations

### Community 37 - "Projeto & Dependências (.NET)"
Cohesion: 0.22
Nodes (7): net10.0, Microsoft.AspNetCore.Authentication.JwtBearer (10.0.0), Microsoft.AspNetCore.Identity.EntityFrameworkCore (10.0.0), Microsoft.EntityFrameworkCore.Design (10.0.0), Npgsql.EntityFrameworkCore.PostgreSQL (10.0.0), Swashbuckle.AspNetCore (7.2.0), Microsoft.NET.Sdk.Web

### Community 38 - "Rotas & Shell do Aluno"
Cohesion: 0.33
Nodes (5): ../auth_provider.dart, competicao/classificacao_view.dart, build, package:flutter/material.dart, package:provider/provider.dart

### Community 39 - "Migração InitialCreate"
Cohesion: 0.50
Nodes (3): MigrationBuilder, InitialCreate, Migration

### Community 47 - "Snapshot do Modelo (EF)"
Cohesion: 0.40
Nodes (3): ModelBuilder, AppDbContextModelSnapshot, ModelSnapshot

### Community 54 - "Rotas de Navegação"
Cohesion: 0.50
Nodes (4): build, build, Route /login, Route /ranking

### Community 55 - "Testes de Widget"
Cohesion: 0.50
Nodes (3): main, package:flutter_test/flutter_test.dart, package:quadra_app/api_client.dart

## Knowledge Gaps
- **588 isolated node(s):** `PeriodoResumo`, `FluxoDia`, `CategoriaResumo`, `FormaPagamentoResumo`, `MembroDto` (+583 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **30 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `QuadraApp.Api.Models` connect `Controllers da API` to `DbContext & Entidades (EF Core)`, `Endpoints REST (Controllers)`, `Endpoints CRUD (Controllers)`, `Endpoints Públicos (Controllers)`, `Endpoints de Listagem`, `Fluxo de Caixa (API)`?**
  _High betweenness centrality (0.241) - this node is a cross-community bridge._
- **Why does `AppDbContext` connect `DbContext & Entidades (EF Core)` to `Endpoints REST (Controllers)`, `Controllers da API`, `Análise de Caixa (API)`, `Endpoints CRUD (Controllers)`, `Endpoints com Patch (Controllers)`, `Endpoints Públicos (Controllers)`, `Endpoints CRUD (Controllers)`, `Endpoints de Listagem`, `Fluxo de Caixa (API)`, `Endpoints CRUD (Controllers)`?**
  _High betweenness centrality (0.134) - this node is a cross-community bridge._
- **Why does `ApiClient` connect `Estados de Telas (Flutter)` to `Cliente HTTP da API`, `Bootstrap do App (main.dart)`, `AuthProvider (Estado de Login)`, `Tela de Dashboard`, `Tela de Competição`, `Tela de Reserva Pública`, `Tela de Produtos/Vendas`, `Tela de Usuários`, `Tela de Reservar Aula`, `Tela de Análise / Shell Aluno`, `Tela de Bloqueios`, `Tela de Cupons`, `Tela de Alunos`, `Tela de Caixa`, `Tela de Quadras`, `Tela de Professores`?**
  _High betweenness centrality (0.107) - this node is a cross-community bridge._
- **What connects `PeriodoResumo`, `FluxoDia`, `CategoriaResumo` to the rest of the system?**
  _588 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Modelos de Dados (Flutter)` be split into smaller, more focused modules?**
  _Cohesion score 0.017699115044247787 - nodes in this community are weakly interconnected._
- **Should `Cliente HTTP da API` be split into smaller, more focused modules?**
  _Cohesion score 0.028169014084507043 - nodes in this community are weakly interconnected._
- **Should `DbContext & Entidades (EF Core)` be split into smaller, more focused modules?**
  _Cohesion score 0.05725490196078432 - nodes in this community are weakly interconnected._