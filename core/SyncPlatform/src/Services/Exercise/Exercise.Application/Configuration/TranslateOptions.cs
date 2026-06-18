namespace Exercise.Application.Configuration;

public class TranslateOptions
{
    public const string SectionName = "Translate";

    /// <summary>aws | passthrough (keeps English)</summary>
    public string Provider { get; set; } = "passthrough";
}
