namespace Notification.Application.Clients;

public interface IAdaptiveAiClient
{
    /// <summary>POST /ai/internal/adaptive/weekly-recalc with Premium user ids.</summary>
    Task TriggerWeeklyRecalcAsync(IReadOnlyList<Guid> userIds, CancellationToken cancellationToken = default);
}
