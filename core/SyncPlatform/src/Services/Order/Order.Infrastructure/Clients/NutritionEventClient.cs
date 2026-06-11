using System.Net.Http.Json;
using System.Text.Json;
using Contract.Events;
using Order.Application.Clients;

namespace Order.Infrastructure.Clients;

public class NutritionEventClient : INutritionEventClient
{
    private readonly HttpClient _httpClient;
    private static readonly JsonSerializerOptions JsonOpts = new() { PropertyNamingPolicy = JsonNamingPolicy.CamelCase };

    public NutritionEventClient(HttpClient httpClient) => _httpClient = httpClient;

    public async Task PublishOrderCompletedAsync(OrderCompletedEvent orderEvent, CancellationToken cancellationToken = default)
    {
        try
        {
            await _httpClient.PostAsJsonAsync("/api/internal/orders/completed", orderEvent, JsonOpts, cancellationToken);
        }
        catch
        {
            // best-effort; Nutrition can reconcile later
        }
    }
}
