namespace Exercise.ImportTool.Enrichment.Models;

public sealed class EnrichmentReport
{
    private int _enriched;
    private int _skipped;
    private int _failed;
    private int _needsReview;

    public int Enriched => _enriched;
    public int Skipped => _skipped;
    public int Failed => _failed;
    public int NeedsReview => _needsReview;
    public List<string> Failures { get; } = [];

    public void IncrementEnriched() => Interlocked.Increment(ref _enriched);
    public void IncrementSkipped() => Interlocked.Increment(ref _skipped);
    public void IncrementFailed() => Interlocked.Increment(ref _failed);
    public void IncrementNeedsReview() => Interlocked.Increment(ref _needsReview);

    public void PrintSummary()
    {
        Console.WriteLine();
        Console.WriteLine("========== ENRICHMENT SUMMARY ==========");
        Console.WriteLine($"  Enriched     : {Enriched}");
        Console.WriteLine($"  Needs review : {NeedsReview}");
        Console.WriteLine($"  Skipped      : {Skipped}");
        Console.WriteLine($"  Failed       : {Failed}");
        if (Failures.Count > 0)
        {
            Console.WriteLine("  Failures:");
            foreach (var f in Failures.Take(20))
            {
                Console.WriteLine($"    - {f}");
            }
        }
        Console.WriteLine("========================================");
    }
}
