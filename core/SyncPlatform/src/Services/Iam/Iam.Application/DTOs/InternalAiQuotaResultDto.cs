namespace Iam.Application.DTOs;

/// <summary>Kết quả kiểm tra / trừ quota AI chat theo tháng.</summary>
public class InternalAiQuotaResultDto
{
    public bool Allowed { get; set; }
    public int Used { get; set; }
    /// <summary>0 = không giới hạn (Premium/Ultra).</summary>
    public int Limit { get; set; }
    public string PeriodKey { get; set; } = string.Empty;
    public string SubscriptionTier { get; set; } = "Free";
}
