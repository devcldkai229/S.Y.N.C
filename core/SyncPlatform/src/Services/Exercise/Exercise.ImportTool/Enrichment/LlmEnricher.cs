using System.Net.Http.Json;

using System.Text.Json;

using System.Text.Json.Serialization;

using Exercise.Application.Configuration;

using Exercise.Domain.Models;

using Exercise.ImportTool.Enrichment.Models;

using Microsoft.Extensions.Logging;

using Microsoft.Extensions.Options;



namespace Exercise.ImportTool.Enrichment;



public sealed class LlmEnricher

{

    public static readonly HashSet<string> AllowedGoals = new(StringComparer.OrdinalIgnoreCase)

    {

        "LoseFat", "BuildMuscle", "ImproveEndurance", "Strength", "Mobility", "GeneralHealth",

    };



    private static readonly JsonSerializerOptions JsonOptions = new()

    {

        PropertyNameCaseInsensitive = true,

        NumberHandling = JsonNumberHandling.AllowReadingFromString,

    };



    private readonly HttpClient _http;

    private readonly EnrichmentOptions _options;

    private readonly ILogger<LlmEnricher> _logger;



    public LlmEnricher(HttpClient http, IOptions<EnrichmentOptions> options, ILogger<LlmEnricher> logger)

    {

        _http = http;

        _options = options.Value;

        _logger = logger;

    }



    public async Task<LlmEnrichmentResult?> EnrichAsync(ExerciseCatalog exercise, CancellationToken cancellationToken = default)

    {

        var context = BuildGroundingContext(exercise);

        var result = await CallOllamaAsync(context, strict: false, cancellationToken);

        if (result != null) return result;



        _logger.LogWarning("Retrying LLM for {Code} with stricter JSON instructions", exercise.ExerciseCode);

        return await CallOllamaAsync(context, strict: true, cancellationToken);

    }



    private string BuildGroundingContext(ExerciseCatalog exercise)

    {

        var force = string.IsNullOrWhiteSpace(exercise.ForceType) ? "unknown" : exercise.ForceType;

        var mechanic = string.IsNullOrWhiteSpace(exercise.MechanicType)

            ? (exercise.IsCompound ? "compound" : "isolation")

            : exercise.MechanicType;



        return $"""

            Tên (EN): {exercise.NameEn}

            Category: {exercise.Category}

            Force: {force}

            Mechanic: {mechanic}

            Cơ chính: {string.Join(", ", exercise.PrimaryMuscles)}

            Cơ phụ: {string.Join(", ", exercise.SecondaryMuscles)}

            Dụng cụ: {string.Join(", ", exercise.EquipmentRequired)}

            Hướng dẫn thực hiện (EN):

            {string.Join("\n", exercise.AiCoachingCues.Select((c, i) => $"{i + 1}. {c}"))}

            """;

    }



    private async Task<LlmEnrichmentResult?> CallOllamaAsync(

        string exerciseContext,

        bool strict,

        CancellationToken cancellationToken)

    {

        var systemPrompt = """

            Bạn là HLV thể hình & sức mạnh có chứng chỉ. Dựa CHỈ trên dữ liệu bài tập được cung cấp, trả lời bằng tiếng Việt, chính xác, ngắn gọn.

            CHỈ xuất JSON đúng schema. Không bịa thông tin y khoa nguy hiểm. contraindications để bảo thủ, chỉ nêu khi thực sự liên quan.

            Dịch tên bài và hướng dẫn sang tiếng Việt tự nhiên; tên kỹ thuật khó có thể giữ nguyên phần riêng.

            """;



        var userPrompt = $"""

            {exerciseContext}



            Trả về JSON với đúng các key sau:

            - nameVi: tên bài tiếng Việt (dịch/Việt hoá tự nhiên)

            - instructionsVi: mảng cùng số dòng, dịch từng bước hướng dẫn sang tiếng Việt

            - commonMistakes: 3-5 mục (tiếng Việt)

            - contraindications: 0-4 mục (tiếng Việt, bảo thủ)

            - recommendedGoals: chỉ chọn từ LoseFat | BuildMuscle | ImproveEndurance | Strength | Mobility | GeneralHealth



            {(strict ? "CHỈ trả JSON hợp lệ, không markdown, không giải thích thêm." : "")}

            """;



        var url = $"{_options.OllamaBaseUrl.TrimEnd('/')}/v1/chat/completions";

        var payload = new

        {

            model = _options.Model,

            stream = false,

            temperature = _options.Temperature,

            response_format = new { type = "json_object" },

            messages = new object[]

            {

                new { role = "system", content = systemPrompt },

                new { role = "user", content = userPrompt },

            },

        };



        try

        {

            using var response = await _http.PostAsJsonAsync(url, payload, cancellationToken);

            if (!response.IsSuccessStatusCode)

            {

                var errorBody = await response.Content.ReadAsStringAsync(cancellationToken);

                if (response.StatusCode == System.Net.HttpStatusCode.NotFound)

                {

                    _logger.LogWarning(

                        "Ollama model '{Model}' not found (404). Run `ollama list` and set Enrichment:Model to an installed tag, or `ollama pull {Model}'. Response: {Body}",

                        _options.Model,

                        _options.Model,

                        errorBody);

                }

                else

                {

                    _logger.LogWarning(

                        "Ollama returned {Status} for model '{Model}': {Body}",

                        (int)response.StatusCode,

                        _options.Model,

                        errorBody);

                }



                return null;

            }



            var body = await response.Content.ReadFromJsonAsync<OllamaChatResponse>(JsonOptions, cancellationToken);

            var content = body?.Choices?.FirstOrDefault()?.Message?.Content;

            if (string.IsNullOrWhiteSpace(content)) return null;



            var parsed = JsonSerializer.Deserialize<LlmEnrichmentResult>(content, JsonOptions);

            return parsed == null ? null : ValidateAndNormalize(parsed);

        }

        catch (Exception ex)

        {

            _logger.LogWarning(ex, "Ollama call failed");

            return null;

        }

    }



    internal LlmEnrichmentResult? ValidateAndNormalize(LlmEnrichmentResult raw)

    {

        var mistakes = TrimStrings(raw.CommonMistakes, 5);

        if (mistakes.Count == 0) return null;



        return new LlmEnrichmentResult

        {

            NameVi = string.IsNullOrWhiteSpace(raw.NameVi) ? null : raw.NameVi.Trim(),

            InstructionsVi = TrimStrings(raw.InstructionsVi, 20),

            CommonMistakes = mistakes,

            Contraindications = TrimStrings(raw.Contraindications, 4),

            RecommendedGoals = raw.RecommendedGoals

                .Where(g => AllowedGoals.Contains(g.Trim()))

                .Select(g => AllowedGoals.First(a => a.Equals(g.Trim(), StringComparison.OrdinalIgnoreCase)))

                .Distinct(StringComparer.OrdinalIgnoreCase)

                .Take(4)

                .ToList(),

        };

    }



    private static List<string> TrimStrings(IEnumerable<string> items, int max)

    {

        return items

            .Where(s => !string.IsNullOrWhiteSpace(s))

            .Select(s => s.Trim())

            .Take(max)

            .ToList();

    }



    private sealed class OllamaChatResponse

    {

        [JsonPropertyName("choices")]

        public List<OllamaChoice>? Choices { get; set; }

    }



    private sealed class OllamaChoice

    {

        [JsonPropertyName("message")]

        public OllamaMessage? Message { get; set; }

    }



    private sealed class OllamaMessage

    {

        [JsonPropertyName("content")]

        public string? Content { get; set; }

    }

}


