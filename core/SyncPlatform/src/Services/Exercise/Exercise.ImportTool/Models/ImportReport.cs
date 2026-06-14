namespace Exercise.ImportTool.Models;

public sealed class ImportReport
{
    private int _imported;
    private int _updated;
    private int _skipped;
    private int _failed;

    public int Imported => _imported;
    public int Updated => _updated;
    public int Skipped => _skipped;
    public int Failed => _failed;

    public List<string> Failures { get; } = [];

    public void IncrementImported() => Interlocked.Increment(ref _imported);
    public void IncrementUpdated() => Interlocked.Increment(ref _updated);
    public void IncrementSkipped() => Interlocked.Increment(ref _skipped);
    public void IncrementFailed() => Interlocked.Increment(ref _failed);

    public void PrintSummary()
    {
        Console.WriteLine();
        Console.WriteLine("========== IMPORT SUMMARY ==========");
        Console.WriteLine($"  Created : {Imported}");
        Console.WriteLine($"  Updated : {Updated}");
        Console.WriteLine($"  Skipped : {Skipped}");
        Console.WriteLine($"  Failed  : {Failed}");
        if (Failures.Count > 0)
        {
            Console.WriteLine("  Failures:");
            foreach (var f in Failures.Take(20))
            {
                Console.WriteLine($"    - {f}");
            }
            if (Failures.Count > 20)
            {
                Console.WriteLine($"    ... and {Failures.Count - 20} more");
            }
        }
        Console.WriteLine("====================================");
    }
}
