namespace Social.API.Options;

public class SocialMaintenanceOptions
{
    public const string SectionName = "Social:Maintenance";

    /// <summary>When true, POST /posts/maintenance/backfill-share-codes is allowed outside Development.</summary>
    public bool AllowShareCodeBackfillApi { get; set; }

    /// <summary>When true, runs share-code backfill once at application startup.</summary>
    public bool BackfillShareCodesOnStartup { get; set; }
}
