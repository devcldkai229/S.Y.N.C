using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Options;
using Notification.Application.Clients;
using Notification.Application.DTOs.SmartPush;
using Notification.Application.Options;
using Notification.Application.Services.SmartPush;

namespace Notification.Infrastructure.Clients;

public class OpenAiClient : IOpenAiClient
{
    private readonly HttpClient _httpClient;
    private readonly OpenAiOptions _options;
    private readonly SmartPushOptions _smartPush;

    private record GeneratedAiTextDto(string Title, string Body);

    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public OpenAiClient(HttpClient httpClient, IOptions<OpenAiOptions> options, IOptions<SmartPushOptions> smartPush)
    {
        _httpClient = httpClient;
        _options = options.Value;
        _smartPush = smartPush.Value;
    }

    public async Task<GeneratedPushMessageDto> GenerateAsync(
        SmartPushContextDto context,
        SmartPushDecision decision,
        string deepLink,
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_options.ApiKey))
            throw new InvalidOperationException("OpenAI ApiKey is not configured.");

        var model = string.IsNullOrWhiteSpace(_smartPush.Model) ? _options.Model : _smartPush.Model;
        var personaTone = GetPersonaToneInstruction(context.AgentPersona);
        var systemPrompt =
            "Bạn viết push notification tiếng Việt cho app fitness + nutrition. " +
            "Trả JSON duy nhất: {\"title\":\"\",\"body\":\"\"}. " +
            "Luật: title <= 40 ký tự; body <= 140 ký tự; không markdown; " +
            "không chê bai cơ thể, không claim y tế. " +
            personaTone;

        var compactContext = BuildCompactContext(context, decision);
        var userPrompt =
            "Viết push notification tiếng Việt dựa trên context (đã ẩn danh). Chỉ JSON.\n" +
            JsonSerializer.Serialize(compactContext, JsonOpts);

        var payload = new ChatCompletionRequest
        {
            Model = model,
            Messages =
            [
                new() { Role = "system", Content = systemPrompt },
                new() { Role = "user", Content = userPrompt }
            ],
            Temperature = 0.8,
            MaxTokens = 180,
            ResponseFormat = new ResponseFormat()
        };

        var request = new HttpRequestMessage(HttpMethod.Post, "chat/completions")
        {
            Content = JsonContent.Create(payload)
        };
        request.Headers.Authorization =
            new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", _options.ApiKey);

        var response = await _httpClient.SendAsync(request, cancellationToken);
        response.EnsureSuccessStatusCode();

        var result = await response.Content.ReadFromJsonAsync<ChatCompletionResponse>(JsonOpts, cancellationToken);
        var rawText = result?.Choices.FirstOrDefault()?.Message.Content;
        if (string.IsNullOrWhiteSpace(rawText))
            throw new InvalidOperationException("Received empty response from OpenAI.");

        var cleanedJson = CleanJsonContent(rawText);
        var parsed = JsonSerializer.Deserialize<GeneratedAiTextDto>(cleanedJson, JsonOpts)
            ?? throw new InvalidOperationException("Deserialized OpenAI message was null.");

        if (string.IsNullOrWhiteSpace(parsed.Title) || parsed.Title.Length > 40)
            throw new InvalidOperationException($"Invalid title from OpenAI: '{parsed.Title}'");
        if (string.IsNullOrWhiteSpace(parsed.Body) || parsed.Body.Length > 140)
            throw new InvalidOperationException("Invalid body from OpenAI (empty or >140 chars).");

        return new GeneratedPushMessageDto(parsed.Title.Trim(), parsed.Body.Trim(), deepLink);
    }

    private static object BuildCompactContext(SmartPushContextDto context, SmartPushDecision decision) => new
    {
        trigger = decision.TriggerType,
        firstName = FirstName(context.FullName),
        motivationStyle = context.MotivationStyle,
        agentPersona = context.AgentPersona,
        goal = context.FitnessGoal,
        streak = context.CurrentStreak,
        longest = context.LongestStreak,
        burnout = context.BurnoutRiskScore,
        recovery = context.RecoveryScore,
        completionRate = context.CompletionRate,
        hasWorkoutToday = context.HasWorkoutScheduledToday,
        workoutSource = context.WorkoutSource,
        todayWorkoutTitle = context.TodayWorkoutName,
        todayWorkoutType = context.TodayWorkoutType,
        scheduledLocalTime = context.ScheduledLocalTime,
        completedToday = context.CompletedWorkoutToday,
        missedRecentCount = context.MissedRecentCount,
        mealsLoggedToday = context.MealsLoggedToday,
        remainingCaloriesPct = context.RemainingCaloriesPct,
        waterPct = context.WaterPct
    };

    private static string? FirstName(string? fullName)
    {
        if (string.IsNullOrWhiteSpace(fullName)) return null;
        var parts = fullName.Trim().Split(' ', StringSplitOptions.RemoveEmptyEntries);
        return parts.Length == 0 ? null : parts[^1]; // Vietnamese given name often last
    }

    private static string GetPersonaToneInstruction(string agentPersona) => agentPersona switch
    {
        "StrictCoach" => "Giọng nghiêm túc, dứt khoát như HLV chuyên nghiệp.",
        "FriendlyBuddy" => "Giọng thân thiện, vui vẻ như bạn đồng hành.",
        "CalmMentor" => "Giọng điềm tĩnh, khích lệ nhẹ nhàng.",
        "EnergeticTrainer" => "Giọng năng lượng, hào hứng.",
        _ => "Giọng tự nhiên, đúng motivation style."
    };

    private static string CleanJsonContent(string content)
    {
        var cleaned = content.Trim();
        if (cleaned.StartsWith("```json", StringComparison.OrdinalIgnoreCase))
            cleaned = cleaned[7..].Trim();
        else if (cleaned.StartsWith("```", StringComparison.OrdinalIgnoreCase))
            cleaned = cleaned[3..].Trim();
        if (cleaned.EndsWith("```"))
            cleaned = cleaned[..^3].Trim();
        return cleaned;
    }
}

internal class ChatCompletionRequest
{
    public string Model { get; set; } = string.Empty;
    public List<ChatMessage> Messages { get; set; } = [];
    public double Temperature { get; set; } = 0.8;
    [System.Text.Json.Serialization.JsonPropertyName("max_tokens")]
    public int MaxTokens { get; set; } = 180;
    [System.Text.Json.Serialization.JsonPropertyName("response_format")]
    public ResponseFormat? ResponseFormat { get; set; }
}

internal class ChatMessage
{
    public string Role { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
}

internal class ResponseFormat
{
    public string Type { get; set; } = "json_object";
}

internal class ChatCompletionResponse
{
    public List<ChatChoice> Choices { get; set; } = [];
}

internal class ChatChoice
{
    public ChatMessage Message { get; set; } = null!;
}
