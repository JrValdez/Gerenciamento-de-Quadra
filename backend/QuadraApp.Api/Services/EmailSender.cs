using MailKit.Net.Smtp;
using MailKit.Security;
using Microsoft.Extensions.Options;
using MimeKit;

namespace QuadraApp.Api.Services;

public interface IEmailSender
{
    Task EnviarAsync(string paraEmail, string assunto, string corpoHtml);
}

/// <summary>Configuração SMTP. Para Gmail: Host=smtp.gmail.com, Port=587,
/// User=seu-email, Password=senha de app (não a senha normal da conta).</summary>
public class SmtpOptions
{
    public string Host { get; set; } = string.Empty;
    public int Port { get; set; } = 587;
    public string User { get; set; } = string.Empty;
    public string Password { get; set; } = string.Empty;
    public string From { get; set; } = string.Empty;
    public string FromName { get; set; } = "Gerenciamento de Quadra";
}

/// <summary>
/// Envia e-mail via SMTP (MailKit). Se o SMTP não estiver configurado, NÃO falha:
/// registra o conteúdo no log (permite testar o fluxo em dev sem servidor de e-mail).
/// </summary>
public class SmtpEmailSender : IEmailSender
{
    private readonly SmtpOptions _opt;
    private readonly ILogger<SmtpEmailSender> _logger;

    public SmtpEmailSender(IOptions<SmtpOptions> opt, ILogger<SmtpEmailSender> logger)
    {
        _opt = opt.Value;
        _logger = logger;
    }

    public async Task EnviarAsync(string paraEmail, string assunto, string corpoHtml)
    {
        if (string.IsNullOrWhiteSpace(_opt.Host) || string.IsNullOrWhiteSpace(_opt.User))
        {
            _logger.LogWarning(
                "SMTP não configurado — e-mail para {Para} não enviado. Assunto: {Assunto}\n{Corpo}",
                paraEmail, assunto, corpoHtml);
            return;
        }

        var msg = new MimeMessage();
        msg.From.Add(new MailboxAddress(
            _opt.FromName, string.IsNullOrWhiteSpace(_opt.From) ? _opt.User : _opt.From));
        msg.To.Add(MailboxAddress.Parse(paraEmail));
        msg.Subject = assunto;
        msg.Body = new BodyBuilder { HtmlBody = corpoHtml }.ToMessageBody();

        using var client = new SmtpClient();
        var seguranca = _opt.Port == 465 ? SecureSocketOptions.SslOnConnect : SecureSocketOptions.StartTls;
        await client.ConnectAsync(_opt.Host, _opt.Port, seguranca);
        await client.AuthenticateAsync(_opt.User, _opt.Password);
        await client.SendAsync(msg);
        await client.DisconnectAsync(true);
        _logger.LogInformation("E-mail enviado para {Para} ({Assunto}).", paraEmail, assunto);
    }
}
