using Exercise.Application.Configuration;
using Exercise.Domain.Repositories;
using Exercise.ImportTool.Enrichment.Models;
using Microsoft.Extensions.Logging;
using Microsoft.Extensions.Options;

namespace Exercise.ImportTool.Enrichment;

public sealed class EnrichExercisesRunner
{
    private readonly IExerciseCatalogRepository _catalogRepository;
    private readonly LlmEnricher _llm;
    private readonly ExerciseEnrichmentUpserter _upserter;
    private readonly EnrichmentOptions _options;
    private readonly ILogger<EnrichExercisesRunner> _logger;

    public EnrichExercisesRunner(
        IExerciseCatalogRepository catalogRepository,
        LlmEnricher llm,
        ExerciseEnrichmentUpserter upserter,
        IOptions<EnrichmentOptions> options,
        ILogger<EnrichExercisesRunner> logger)
    {
        _catalogRepository = catalogRepository;
        _llm = llm;
        _upserter = upserter;
        _options = options.Value;
        _logger = logger;
    }

    public async Task<EnrichmentReport> RunAsync(EnrichmentRunOptions args, CancellationToken cancellationToken = default)
    {
        var report = new EnrichmentReport();
        var exercises = await _catalogRepository.GetForEnrichmentAsync(args.Force, args.Limit, cancellationToken);

        if (exercises.Count == 0)
        {
            _logger.LogWarning(
                "No exercises to enrich. Import first (import-free-exercise-db), or use --force to re-enrich. " +
                "Without --force, only exercises with AiEnrichedAt unset are processed.");
            report.PrintSummary();
            return report;
        }

        _logger.LogInformation(
            "Enriching {Count} exercises (concurrency={Concurrency}, force={Force})",
            exercises.Count,
            _options.Concurrency,
            args.Force);

        var gate = new SemaphoreSlim(Math.Max(1, _options.Concurrency));
        var tasks = exercises.Select(exercise => ProcessOneAsync(exercise, gate, report, cancellationToken)).ToList();
        await Task.WhenAll(tasks);

        report.PrintSummary();
        return report;
    }

    private async Task ProcessOneAsync(
        Domain.Models.ExerciseCatalog exercise,
        SemaphoreSlim gate,
        EnrichmentReport report,
        CancellationToken cancellationToken)
    {
        await gate.WaitAsync(cancellationToken);
        try
        {
            var llm = await _llm.EnrichAsync(exercise, cancellationToken);
            if (llm == null)
            {
                report.IncrementFailed();
                lock (report.Failures)
                {
                    report.Failures.Add($"{exercise.ExerciseCode}: LLM parse/validation failed");
                }
                return;
            }

            await _upserter.ApplyAsync(exercise, llm, cancellationToken);
            report.IncrementEnriched();
            report.IncrementNeedsReview();
            _logger.LogDebug("Enriched {Code}", exercise.ExerciseCode);
        }
        catch (Exception ex)
        {
            report.IncrementFailed();
            lock (report.Failures)
            {
                report.Failures.Add($"{exercise.ExerciseCode}: {ex.Message}");
            }
            _logger.LogError(ex, "Enrichment failed for {Code}", exercise.ExerciseCode);
        }
        finally
        {
            gate.Release();
        }
    }
}

public sealed class EnrichmentRunOptions
{
    public int? Limit { get; init; }
    public bool Force { get; init; }
}
