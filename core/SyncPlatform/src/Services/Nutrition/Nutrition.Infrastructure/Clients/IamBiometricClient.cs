using System.Net.Http.Json;
using System.Text.Json;
using Nutrition.Application.Clients;
using Nutrition.Application.Common;
using Nutrition.Application.DTOs;

namespace Nutrition.Infrastructure.Clients;

public class IamBiometricClient : IIamBiometricClient
{
    private readonly HttpClient _httpClient;
    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNamingPolicy = JsonNamingPolicy.CamelCase,
    };

    public IamBiometricClient(HttpClient httpClient)
    {
        _httpClient = httpClient;
    }

    public async Task<NutritionTargetsDto?> GetNutritionTargetsAsync(
        Guid userId,
        CancellationToken cancellationToken = default)
    {
        var response = await _httpClient.GetAsync($"/api/internal/biometrics/{userId}/nutrition-targets", cancellationToken);
        if (response.StatusCode == System.Net.HttpStatusCode.NotFound)
            return null;

        response.EnsureSuccessStatusCode();
        var apiResponse = await response.Content.ReadFromJsonAsync<ApiResponse<IamNutritionTargetsPayload>>(JsonOpts, cancellationToken);
        if (apiResponse?.Data == null)
            return null;

        return new NutritionTargetsDto
        {
            TargetCalories = apiResponse.Data.TargetCalories,
            TargetProteinGram = apiResponse.Data.TargetProteinGram,
            TargetCarbGram = apiResponse.Data.TargetCarbGram,
            TargetFatGram = apiResponse.Data.TargetFatGram,
        };
    }

    private sealed class IamNutritionTargetsPayload
    {
        public int TargetCalories { get; set; }
        public int? TargetProteinGram { get; set; }
        public int? TargetCarbGram { get; set; }
        public int? TargetFatGram { get; set; }
    }
}
