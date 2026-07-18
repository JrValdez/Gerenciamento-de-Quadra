# Gerenciamento de Quadra

Sistema de reserva de quadras com controle de caixa e produtos.

- **Backend:** ASP.NET Core (.NET 10) + Entity Framework Core + PostgreSQL, autenticação ASP.NET Identity + JWT.
- **Frontend:** Flutter Web.
- **Banco:** PostgreSQL (via Docker Compose).

## Recursos

- **Reserva pública sem login** — o cliente escolhe quadra, dia e horário e informa apenas **nome, telefone e e-mail**.
- **Níveis de acesso:** Admin, Atendente e Cliente.
- **Agendamentos** com verificação de conflito de horário e cálculo automático do valor (preço/hora × duração).
- **Quadras** — cadastro/edição, ativação/inativação.
- **Produtos** (água, refrigerante, etc.) — cadastro, estoque e **venda rápida** (carrinho) que baixa estoque e lança entrada no caixa.
- **Controle de caixa** — abertura/fechamento, suprimento, sangria e histórico de movimentações com saldo esperado.
- **Dashboard** — resumo do dia (reservas, faturamento, saldo de caixa, baixo estoque, próximos agendamentos).
- **Gestão de usuários** (Admin) — cadastrar atendentes/admins e ativar/inativar acesso.
- **Login persistente** — a sessão do funcionário sobrevive ao refresh do navegador.

## Como rodar

### 1. Banco de dados (PostgreSQL)

```bash
docker compose up -d
```

### 2. Backend (.NET 10)

```bash
cd backend/QuadraApp.Api
dotnet run
```

- API em `http://localhost:5080`
- Swagger em `http://localhost:5080/swagger`
- A migração e o *seed* (roles, usuários e dados de exemplo) rodam automaticamente na primeira execução.

**Usuários criados no seed:**

| Papel      | E-mail                    | Senha           |
|------------|---------------------------|-----------------|
| Admin      | `admin@quadra.local`      | `Admin@123`     |
| Atendente  | `atendente@quadra.local`  | `Atendente@123` |

### 3. Frontend (Flutter Web)

```bash
cd frontend/quadra_app
flutter run -d chrome
```

Para apontar para outra URL de API:

```bash
flutter run -d chrome --dart-define=API_URL=http://localhost:5080/api
```

## Estrutura

```
Gerenciamento de Quadra/
├─ docker-compose.yml         # PostgreSQL
├─ backend/QuadraApp.Api/     # API .NET 10
│  ├─ Models/                 # Entidades de domínio
│  ├─ DTOs/                   # Contratos da API
│  ├─ Data/                   # DbContext, migrations, seeder
│  ├─ Controllers/            # Auth, Quadras, Agendamentos, Produtos, Caixa, Vendas
│  └─ Services/               # TokenService (JWT)
└─ frontend/quadra_app/       # App Flutter Web
   └─ lib/
      ├─ screens/             # Reserva pública, login, painel interno
      ├─ api_client.dart      # Cliente HTTP
      ├─ auth_provider.dart   # Estado de autenticação
      └─ models.dart          # Modelos
```

## Principais endpoints

| Método | Rota                                   | Acesso            |
|--------|----------------------------------------|-------------------|
| POST   | `/api/auth/login`                      | público           |
| POST   | `/api/auth/register`                   | Admin             |
| GET    | `/api/quadras`                         | público (ativas)  |
| POST   | `/api/agendamentos/publico`            | público           |
| GET    | `/api/agendamentos/disponibilidade`    | público           |
| GET/POST | `/api/agendamentos`                  | Admin/Atendente   |
| CRUD   | `/api/produtos`                        | Admin/Atendente   |
| POST   | `/api/vendas`                          | Admin/Atendente   |
| POST   | `/api/caixa/abrir` · `/fechar`         | Admin/Atendente   |

## Deploy

A stack completa (PostgreSQL + API + Flutter Web) roda em containers isolados via
Docker Compose, pensada para conviver com outros sites do mesmo servidor. Passo a passo,
Dockerfiles, `docker-compose.prod.yml` e exemplo de reverse proxy por subdomínio em
[`deploy/DEPLOY.md`](deploy/DEPLOY.md).

> **Produção:** troque `Jwt:Key` e a senha do banco por valores seguros (variáveis de ambiente / `deploy/.env`).
