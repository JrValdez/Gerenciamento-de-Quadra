namespace QuadraApp.Api.Infra;

/// <summary>
/// Conversões de horário do estabelecimento. Os horários de funcionamento da quadra
/// (hora de abertura/fechamento) são montados no fuso configurado e convertidos para
/// UTC, independentemente do fuso do processo do servidor — evita depender do TZ do host.
/// </summary>
public static class Horario
{
    public static DateTime LocalParaUtc(int ano, int mes, int dia, int hora, TimeZoneInfo fuso)
    {
        var local = new DateTime(ano, mes, dia, hora, 0, 0, DateTimeKind.Unspecified);
        return TimeZoneInfo.ConvertTimeToUtc(local, fuso);
    }
}
