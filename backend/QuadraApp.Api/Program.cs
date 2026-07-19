using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.AspNetCore.HttpLogging;
using Microsoft.AspNetCore.Identity;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using Microsoft.OpenApi.Models;
using QuadraApp.Api.Data;
using QuadraApp.Api.Infra;
using QuadraApp.Api.Models;
using QuadraApp.Api.Services;

var builder = WebApplication.CreateBuilder(args);

// ----- Banco de dados (PostgreSQL) -----
builder.Services.AddDbContext<AppDbContext>(opt =>
    opt.UseNpgsql(builder.Configuration.GetConnectionString("Default")));

// ----- Identity -----
builder.Services
    .AddIdentity<ApplicationUser, IdentityRole<Guid>>(opt =>
    {
        opt.Password.RequireNonAlphanumeric = false;
        opt.Password.RequireUppercase = false;
        opt.Password.RequireLowercase = false;
        opt.Password.RequireDigit = false;
        opt.Password.RequiredLength = 6;
        opt.User.RequireUniqueEmail = true;
    })
    .AddEntityFrameworkStores<AppDbContext>()
    .AddDefaultTokenProviders();

// ----- JWT -----
var jwtSection = builder.Configuration.GetSection("Jwt");
builder.Services.Configure<JwtOptions>(jwtSection);
var jwt = jwtSection.Get<JwtOptions>()!;

// Fail-fast: nunca subir com uma chave de assinatura ausente, curta ou de exemplo.
const string JwtKeyExemplo = "troque-esta-chave-super-secreta-com-no-minimo-32-caracteres!!";
if (string.IsNullOrWhiteSpace(jwt.Key) || jwt.Key.Length < 32)
    throw new InvalidOperationException(
        "Jwt:Key ausente ou curta demais. Defina Jwt__Key com uma chave aleatória de no mínimo 32 caracteres.");
if (builder.Environment.IsProduction() && jwt.Key == JwtKeyExemplo)
    throw new InvalidOperationException(
        "Jwt:Key está usando o valor de exemplo em produção. Gere uma chave real (ex.: openssl rand -base64 48) e defina em Jwt__Key.");

builder.Services.AddSingleton<TokenService>();

builder.Services
    .AddAuthentication(opt =>
    {
        opt.DefaultAuthenticateScheme = JwtBearerDefaults.AuthenticationScheme;
        opt.DefaultChallengeScheme = JwtBearerDefaults.AuthenticationScheme;
    })
    .AddJwtBearer(opt =>
    {
        opt.TokenValidationParameters = new TokenValidationParameters
        {
            ValidateIssuer = true,
            ValidateAudience = true,
            ValidateLifetime = true,
            ValidateIssuerSigningKey = true,
            ValidIssuer = jwt.Issuer,
            ValidAudience = jwt.Audience,
            IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwt.Key)),
            ClockSkew = TimeSpan.FromMinutes(1),
        };

        // Revogação server-side: a cada requisição confere se o usuário ainda existe,
        // está ativo e se o security stamp do token bate com o atual. Assim, inativar
        // um usuário ou trocar a senha invalida imediatamente os tokens já emitidos
        // (que, de outra forma, seguiriam válidos até expirar).
        opt.Events = new JwtBearerEvents
        {
            OnTokenValidated = async ctx =>
            {
                var userManager = ctx.HttpContext.RequestServices
                    .GetRequiredService<UserManager<ApplicationUser>>();
                var userId = ctx.Principal?.FindFirstValue(ClaimTypes.NameIdentifier);
                var user = userId is null ? null : await userManager.FindByIdAsync(userId);

                if (user is null || !user.Ativo)
                {
                    ctx.Fail("Usuário inválido ou inativo.");
                    return;
                }

                if (userManager.SupportsUserSecurityStamp)
                {
                    var stampToken = ctx.Principal?.FindFirstValue("sstamp");
                    var stampAtual = await userManager.GetSecurityStampAsync(user);
                    if (!string.Equals(stampToken, stampAtual, StringComparison.Ordinal))
                        ctx.Fail("Sessão expirada. Faça login novamente.");
                }
            }
        };
    });

builder.Services.AddAuthorization();

// ----- CORS (Flutter web) -----
// Dev: liberado (a porta do `flutter run` varia a cada execução). Produção: apenas
// as origens listadas em Cors:AllowedOrigins. No deploy padrão o front é servido
// pelo mesmo host via nginx (proxy de /api), então a lista pode ficar vazia — ou
// seja, nenhuma origem externa é aceita.
const string CorsPolicy = "frontend";
builder.Services.AddCors(opt =>
    opt.AddPolicy(CorsPolicy, p =>
    {
        if (builder.Environment.IsDevelopment())
        {
            p.AllowAnyOrigin().AllowAnyHeader().AllowAnyMethod();
        }
        else
        {
            var origins = builder.Configuration
                .GetSection("Cors:AllowedOrigins").Get<string[]>() ?? Array.Empty<string>();
            p.WithOrigins(origins).AllowAnyHeader().AllowAnyMethod();
        }
    }));

// ----- Fuso do estabelecimento (montagem de horários) -----
var tzId = builder.Configuration["App:TimeZone"] ?? "America/Sao_Paulo";
builder.Services.AddSingleton(TimeZoneInfo.FindSystemTimeZoneById(tzId));

// ----- Regras de domínio (camada de aplicação) -----
builder.Services.AddScoped<AgendamentoService>();

// ----- Erros, saúde e observabilidade -----
builder.Services.AddProblemDetails();
builder.Services.AddExceptionHandler<GlobalExceptionHandler>();

builder.Services.AddHealthChecks()
    .AddCheck<DbHealthCheck>("db");

// Log de acesso enxuto: método, rota, status e duração. NÃO registra corpo nem
// cabeçalhos (evita vazar senha no login e o token no Authorization).
builder.Services.AddHttpLogging(o =>
{
    o.LoggingFields = HttpLoggingFields.RequestMethod
        | HttpLoggingFields.RequestPath
        | HttpLoggingFields.ResponseStatusCode
        | HttpLoggingFields.Duration;
    o.CombineLogs = true;
});

// ----- MVC / Swagger -----
builder.Services.AddControllers();

// Respostas de validação (400) no mesmo formato { erro } que os controllers usam,
// para o cliente exibir a mensagem em vez de um "Erro 400" genérico.
builder.Services.Configure<ApiBehaviorOptions>(opt =>
{
    opt.InvalidModelStateResponseFactory = ctx =>
    {
        var msg = ctx.ModelState.Values
            .SelectMany(v => v.Errors)
            .Select(e => e.ErrorMessage)
            .FirstOrDefault(m => !string.IsNullOrWhiteSpace(m)) ?? "Dados inválidos.";
        return new BadRequestObjectResult(new { erro = msg });
    };
});

builder.Services.AddEndpointsApiExplorer();
builder.Services.AddSwaggerGen(c =>
{
    c.SwaggerDoc("v1", new OpenApiInfo { Title = "QuadraApp API", Version = "v1" });
    var scheme = new OpenApiSecurityScheme
    {
        Name = "Authorization",
        Type = SecuritySchemeType.Http,
        Scheme = "bearer",
        BearerFormat = "JWT",
        In = ParameterLocation.Header,
        Reference = new OpenApiReference { Type = ReferenceType.SecurityScheme, Id = "Bearer" }
    };
    c.AddSecurityDefinition("Bearer", scheme);
    c.AddSecurityRequirement(new OpenApiSecurityRequirement { [scheme] = Array.Empty<string>() });
});

var app = builder.Build();

// Converte qualquer exceção não tratada num JSON consistente (sem stack trace em prod).
app.UseExceptionHandler();

app.UseHttpLogging();

// Swagger apenas fora de produção — não expor a superfície da API publicamente.
if (!app.Environment.IsProduction())
{
    app.UseSwagger();
    app.UseSwaggerUI();
}

app.UseCors(CorsPolicy);
app.UseAuthentication();
app.UseAuthorization();
app.MapControllers();

// Liveness/readiness para orquestração (Docker healthcheck, reverse proxy). Anônimo.
app.MapHealthChecks("/health");

// ----- Migração + seed automáticos -----
await DbSeeder.SeedAsync(app.Services);

app.Run();
