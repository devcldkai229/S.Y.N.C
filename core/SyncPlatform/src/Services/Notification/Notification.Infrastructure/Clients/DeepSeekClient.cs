using System.Net.Http.Json;
using System.Text.Json;
using Microsoft.Extensions.Configuration;
using Notification.Application.Clients;
using Notification.Application.DTOs.SmartPush;
using Notification.Application.Services.SmartPush;

namespace Notification.Infrastructure.Clients;

public class DeepSeekClient : IDeepSeekClient
{
    private readonly HttpClient _httpClient;
    private readonly string _apiKey;
    private readonly string _model;

    private record GeneratedAiTextDto(string Title, string Body);

    private static readonly JsonSerializerOptions JsonOpts = new()
    {
        PropertyNameCaseInsensitive = true
    };

    public DeepSeekClient(HttpClient httpClient, IConfiguration configuration)
    {
        _httpClient = httpClient;
        _apiKey = configuration["DeepSeek:ApiKey"] ?? string.Empty;
        _model = configuration["DeepSeek:Model"] ?? "deepseek-chat";
    }

    public async Task<GeneratedPushMessageDto> GenerateAsync(
        SmartPushContextDto context, 
        SmartPushDecision decision, 
        string deepLink, 
        CancellationToken cancellationToken)
    {
        if (string.IsNullOrWhiteSpace(_apiKey))
        {
            throw new InvalidOperationException("DeepSeek ApiKey is not configured.");
        }

        var personaTone = GetPersonaToneInstruction(context.AgentPersona);
        var systemPrompt = $"Bạn viết push notification tiếng Việt cho app fitness + nutrition. Trả JSON duy nhất: {{\"title\":\"\",\"body\":\"\"}}. Luật: - title <= 40 ký tự. - body <= 100 từ. - Không chê bai, không gây áp lực, không claim y tế. - {personaTone} - burnout cao: nhẹ nhàng, gợi ý 10-15 phút. - started=true và completed=false: khuyến khích quay lại tập tiếp. - streak>=7: nhắc giữ chuỗi như một thành tích đáng tự hào.";
        
        var compactContext = BuildCompactContext(context, decision);
        var contextJson = JsonSerializer.Serialize(compactContext, JsonOpts);

        var userPrompt = $@"Write a Vietnamese push notification for a fitness + nutrition mobile app based on the following context.
Return valid JSON only:
{{
  ""title"": ""..."",
  ""body"": ""...""
}}

Context:
{contextJson}";

        var payload = new ChatCompletionRequest
        {
            Model = _model,
            Messages =
            [
                new() { Role = "system", Content = systemPrompt },
                new() { Role = "user", Content = userPrompt }
            ],
            Temperature = 0.8,
            MaxTokens = 150,
            ResponseFormat = new ResponseFormat()
        };

        var request = new HttpRequestMessage(HttpMethod.Post, "/chat/completions")
        {
            Content = JsonContent.Create(payload)
        };
        request.Headers.Authorization = new System.Net.Http.Headers.AuthenticationHeaderValue("Bearer", _apiKey);

        var response = await _httpClient.SendAsync(request, cancellationToken);
        response.EnsureSuccessStatusCode();

        var result = await response.Content.ReadFromJsonAsync<ChatCompletionResponse>(JsonOpts, cancellationToken);
        var rawText = result?.Choices.FirstOrDefault()?.Message.Content;

        if (string.IsNullOrWhiteSpace(rawText))
        {
            throw new Exception("Received empty response from DeepSeek API.");
        }

        var cleanedJson = CleanJsonContent(rawText);
        GeneratedAiTextDto? parsed;
        try
        {
            parsed = JsonSerializer.Deserialize<GeneratedAiTextDto>(cleanedJson, JsonOpts);
        }
        catch (JsonException ex)
        {
            throw new Exception($"Failed to deserialize DeepSeek response: {cleanedJson}", ex);
        }

        if (parsed == null)
        {
            throw new Exception("Deserialized message was null.");
        }

        // Validate Title
        if (string.IsNullOrWhiteSpace(parsed.Title))
        {
            throw new Exception("Generated title was empty.");
        }
        if (parsed.Title.Length > 40)
        {
            throw new Exception($"Generated title exceeded 40 characters: '{parsed.Title}'");
        }

        // Validate Body
        if (string.IsNullOrWhiteSpace(parsed.Body))
        {
            throw new Exception("Generated body was empty.");
        }
        if (parsed.Body.Length > 500)
        {
            throw new Exception("Generated body exceeded 500 characters.");
        }

        return new GeneratedPushMessageDto(
            Title: parsed.Title,
            Body: parsed.Body,
            DeepLink: deepLink
        );
    }

    private static object BuildCompactContext(SmartPushContextDto context, SmartPushDecision decision)
    {
        return decision.TriggerType switch
        {
            "RecoveryGentleReminder" => new
            {
                trigger = decision.TriggerType,
                name = context.FullName,
                burnout = context.BurnoutRiskScore,
                style = context.MotivationStyle,
                goal = context.FitnessGoal,
                agentPersona = context.AgentPersona
            },
            "FinishWorkoutReminder" => new
            {
                trigger = decision.TriggerType,
                name = context.FullName,
                completion = context.CompletionRate,
                duration = context.ActualDurationMinutes,
                energyBefore = context.EnergyLevelBefore,
                energyAfter = context.EnergyLevelAfter,
                style = context.MotivationStyle,
                agentPersona = context.AgentPersona
            },
            "StreakProtectionReminder" => new
            {
                trigger = decision.TriggerType,
                name = context.FullName,
                streak = context.CurrentStreak,
                longest = context.LongestStreak,
                style = context.MotivationStyle,
                goal = context.FitnessGoal,
                agentPersona = context.AgentPersona
            },
            _ => new
            {
                trigger = decision.TriggerType,
                name = context.FullName,
                style = context.MotivationStyle,
                agentPersona = context.AgentPersona
            }
        };
    }

    private static string GetPersonaToneInstruction(string agentPersona)
    {
        return agentPersona switch
        {
            "StrictCoach" => "Giọng văn nghiêm túc, dứt khoát như một huấn luyện viên chuyên nghiệp. Dùng mệnh lệnh ngắn gọn, thúc đẩy mạnh mẽ, không lan man. Ví dụ: 'Dậy tập đi!', 'Hôm nay không được lười.'",
            "FriendlyBuddy" => "Giọng văn thân thiện, vui vẻ như một người bạn đồng hành. Dùng emoji phù hợp, nói chuyện tự nhiên, thoải mái. Ví dụ: 'Ê, tập cùng mình không? 😄', 'Hôm nay mình tập nhẹ nhé!'",
            "CalmMentor" => "Giọng văn điềm tĩnh, sâu sắc như một người cố vấn. Lời khuyên nhẹ nhàng, khích lệ bằng lý trí. Ví dụ: 'Mỗi bước nhỏ đều có ý nghĩa.', 'Hãy lắng nghe cơ thể bạn hôm nay.'",
            "EnergeticTrainer" => "Giọng văn đầy năng lượng, hào hứng như một PT nhiệt huyết. Dùng nhiều dấu chấm than, từ ngữ sôi động. Ví dụ: 'LET'S GO! Hôm nay cháy hết mình! 🔥', 'Năng lượng đang chờ bạn rồi đó!'",
            _ => "Giọng tự nhiên, đúng motivation style."
        };
    }

    private static string CleanJsonContent(string content)
    {
        if (string.IsNullOrWhiteSpace(content))
            return string.Empty;

        var cleaned = content.Trim();
        if (cleaned.StartsWith("```json", StringComparison.OrdinalIgnoreCase))
        {
            cleaned = cleaned.Substring(7).Trim();
        }
        else if (cleaned.StartsWith("```", StringComparison.OrdinalIgnoreCase))
        {
            cleaned = cleaned.Substring(3).Trim();
        }

        if (cleaned.EndsWith("```"))
        {
            cleaned = cleaned.Substring(0, cleaned.Length - 3).Trim();
        }

        return cleaned;
    }
}

public class ChatCompletionRequest
{
    public string Model { get; set; } = string.Empty;
    public List<ChatMessage> Messages { get; set; } = [];
    public double Temperature { get; set; } = 0.8;
    public int MaxTokens { get; set; } = 250;
    public ResponseFormat? ResponseFormat { get; set; }
}

public class ChatMessage
{
    public string Role { get; set; } = string.Empty;
    public string Content { get; set; } = string.Empty;
}

public class ResponseFormat
{
    public string Type { get; set; } = "json_object";
}

public class ChatCompletionResponse
{
    public List<ChatChoice> Choices { get; set; } = [];
}

public class ChatChoice
{
    public ChatMessage Message { get; set; } = null!;
}
