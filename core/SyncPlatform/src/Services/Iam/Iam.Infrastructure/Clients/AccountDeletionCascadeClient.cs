using Iam.Application.Abstractions;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Logging;

namespace Iam.Infrastructure.Clients;

public sealed class AccountDeletionCascadeClient : IAccountDeletionCascadeClient
{
    private readonly HttpClient _http;
    private readonly IConfiguration _config;
    private readonly ILogger<AccountDeletionCascadeClient> _logger;

    public AccountDeletionCascadeClient(
        HttpClient http,
        IConfiguration config,
        ILogger<AccountDeletionCascadeClient> logger)
    {
        _http = http;
        _config = config;
        _logger = logger;
    }

    public async Task NotifyDeletedAsync(Guid userId, CancellationToken cancellationToken = default)
    {
        var paymentBase = (_config["PaymentService:BaseUrl"] ?? "http://localhost:5084").TrimEnd('/');
        var socialBase = (_config["SocialService:BaseUrl"] ?? "http://localhost:5120").TrimEnd('/');

        await PostBestEffortAsync(
            $"{paymentBase}/api/internal/payment/users/{userId}/expire-subscriptions",
            "Payment expire-subscriptions",
            userId,
            cancellationToken);

        await PostBestEffortAsync(
            $"{socialBase}/api/internal/social/users/{userId}/anonymize",
            "Social anonymize",
            userId,
            cancellationToken);
    }

    private async Task PostBestEffortAsync(
        string url,
        string label,
        Guid userId,
        CancellationToken cancellationToken)
    {
        try
        {
            using var response = await _http.PostAsync(url, content: null, cancellationToken);
            if (!response.IsSuccessStatusCode)
            {
                _logger.LogWarning(
                    "Account deletion cascade {Label} returned {StatusCode} for UserId={UserId}.",
                    label,
                    (int)response.StatusCode,
                    userId);
            }
        }
        catch (Exception ex) when (ex is not OperationCanceledException)
        {
            _logger.LogWarning(
                ex,
                "Account deletion cascade {Label} failed for UserId={UserId}.",
                label,
                userId);
        }
    }
}
