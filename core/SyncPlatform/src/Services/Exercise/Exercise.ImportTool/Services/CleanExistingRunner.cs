using Exercise.Domain.Repositories;
using Microsoft.Extensions.Logging;

namespace Exercise.ImportTool.Services;

public sealed class CleanExistingRunner
{
    private readonly IExerciseCatalogRepository _catalogRepository;
    private readonly FreeExerciseDbFetcher _fetcher;
    private readonly ILogger<CleanExistingRunner> _logger;

    public CleanExistingRunner(
        IExerciseCatalogRepository catalogRepository,
        FreeExerciseDbFetcher fetcher,
        ILogger<CleanExistingRunner> logger)
    {
        _catalogRepository = catalogRepository;
        _fetcher = fetcher;
        _logger = logger;
    }

    public async Task<CleanExistingReport> RunAsync(int? limit, CancellationToken cancellationToken = default)
    {
        var report = new CleanExistingReport();
        var sourceByCode = (await _fetcher.FetchCatalogAsync(cancellationToken))
            .Select(FreeExerciseDbEntrySanitizer.Sanitize)
            .ToDictionary(e => e.Id, StringComparer.OrdinalIgnoreCase);

        var exercises = await _catalogRepository.GetAllActiveAsync(limit, cancellationToken);
        _logger.LogInformation("Cleaning {Count} exercise(s)", exercises.Count);

        foreach (var exercise in exercises)
        {
            try
            {
                StringSanitizer.SanitizeCatalog(exercise);

                if (sourceByCode.TryGetValue(exercise.ExerciseCode, out var source))
                {
                    if (string.IsNullOrWhiteSpace(exercise.ForceType) && !string.IsNullOrWhiteSpace(source.Force))
                        exercise.ForceType = source.Force.ToLowerInvariant();
                    if (string.IsNullOrWhiteSpace(exercise.MechanicType) && !string.IsNullOrWhiteSpace(source.Mechanic))
                        exercise.MechanicType = source.Mechanic.ToLowerInvariant();
                }
                else
                {
                    RecoverForceAndMechanicFromTags(exercise);
                }

                exercise.IsCompound = string.Equals(exercise.MechanicType, "compound", StringComparison.OrdinalIgnoreCase);
                exercise.MovementPattern = MovementPatternInferer.InferFromCatalog(exercise);
                exercise.MovementTags = MovementTagBuilder.Build(exercise);
                exercise.UpdatedAt = DateTimeOffset.UtcNow;

                await _catalogRepository.UpdateAsync(exercise.Id, exercise, cancellationToken);
                report.IncrementUpdated();
            }
            catch (Exception ex)
            {
                report.IncrementFailed();
                lock (report.Failures)
                {
                    report.Failures.Add($"{exercise.ExerciseCode}: {ex.Message}");
                }
                _logger.LogError(ex, "Failed to clean {Code}", exercise.ExerciseCode);
            }
        }

        report.PrintSummary();
        return report;
    }

    private static void RecoverForceAndMechanicFromTags(Exercise.Domain.Models.ExerciseCatalog exercise)
    {
        if (string.IsNullOrWhiteSpace(exercise.ForceType))
        {
            exercise.ForceType = exercise.MovementTags.FirstOrDefault(t =>
                t.Equals("push", StringComparison.OrdinalIgnoreCase) ||
                t.Equals("pull", StringComparison.OrdinalIgnoreCase) ||
                t.Equals("static", StringComparison.OrdinalIgnoreCase)) ?? string.Empty;
        }

        if (string.IsNullOrWhiteSpace(exercise.MechanicType))
        {
            exercise.MechanicType = exercise.MovementTags.FirstOrDefault(t =>
                t.Equals("compound", StringComparison.OrdinalIgnoreCase) ||
                t.Equals("isolation", StringComparison.OrdinalIgnoreCase)) ?? string.Empty;
        }
    }
}

public sealed class CleanExistingReport
{
    private int _updated;
    private int _failed;

    public int Updated => _updated;
    public int Failed => _failed;
    public List<string> Failures { get; } = [];

    public void IncrementUpdated() => Interlocked.Increment(ref _updated);
    public void IncrementFailed() => Interlocked.Increment(ref _failed);

    public void PrintSummary()
    {
        Console.WriteLine();
        Console.WriteLine("========== CLEAN EXISTING SUMMARY ==========");
        Console.WriteLine($"  Updated : {Updated}");
        Console.WriteLine($"  Failed  : {Failed}");
        if (Failures.Count > 0)
        {
            Console.WriteLine("  Failures:");
            foreach (var failure in Failures)
                Console.WriteLine($"    - {failure}");
        }
        Console.WriteLine("============================================");
    }
}
