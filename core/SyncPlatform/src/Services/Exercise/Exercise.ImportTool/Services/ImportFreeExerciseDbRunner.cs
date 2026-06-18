using Exercise.Domain.Repositories;

using Exercise.ImportTool.Models;

using Microsoft.Extensions.Logging;



namespace Exercise.ImportTool.Services;



public sealed class ImportFreeExerciseDbRunner

{

    private const int MaxParallelism = 6;



    private readonly FreeExerciseDbFetcher _fetcher;

    private readonly FreeExerciseDbMapper _mapper;

    private readonly ExerciseMediaPipeline _media;

    private readonly ExerciseCatalogUpserter _upserter;

    private readonly IExerciseCatalogRepository _catalogRepository;

    private readonly ILogger<ImportFreeExerciseDbRunner> _logger;



    public ImportFreeExerciseDbRunner(

        FreeExerciseDbFetcher fetcher,

        FreeExerciseDbMapper mapper,

        ExerciseMediaPipeline media,

        ExerciseCatalogUpserter upserter,

        IExerciseCatalogRepository catalogRepository,

        ILogger<ImportFreeExerciseDbRunner> logger)

    {

        _fetcher = fetcher;

        _mapper = mapper;

        _media = media;

        _upserter = upserter;

        _catalogRepository = catalogRepository;

        _logger = logger;

    }



    public async Task<ImportReport> RunAsync(ImportOptions options, CancellationToken cancellationToken = default)

    {

        var report = new ImportReport();

        var catalog = await _fetcher.FetchCatalogAsync(cancellationToken);

        var entries = options.Limit.HasValue ? catalog.Take(options.Limit.Value).ToList() : catalog.ToList();



        _logger.LogInformation("Processing {Count} exercises (parallelism={Parallelism})", entries.Count, MaxParallelism);



        var gate = new SemaphoreSlim(MaxParallelism);

        var tasks = new List<Task>();

        var processed = 0;



        foreach (var entry in entries)

        {

            await gate.WaitAsync(cancellationToken);

            var task = ProcessOneAsync(entry, options, report, () =>

            {

                var done = Interlocked.Increment(ref processed);

                if (done % 25 == 0 || done == entries.Count)

                {

                    _logger.LogInformation("Progress {Done}/{Total} (imported={Imported}, updated={Updated}, skipped={Skipped}, failed={Failed})",

                        done, entries.Count, report.Imported, report.Updated, report.Skipped, report.Failed);

                }

                gate.Release();

            }, cancellationToken);

            tasks.Add(task);

        }



        await Task.WhenAll(tasks);

        report.PrintSummary();

        return report;

    }



    private async Task ProcessOneAsync(

        FreeExerciseDbEntry entry,

        ImportOptions options,

        ImportReport report,

        Action onComplete,

        CancellationToken cancellationToken)

    {

        try

        {

            entry = FreeExerciseDbEntrySanitizer.Sanitize(entry);



            if (string.IsNullOrWhiteSpace(entry.Id) || string.IsNullOrWhiteSpace(entry.Name))

            {

                report.IncrementSkipped();

                return;

            }



            var existing = await _catalogRepository.GetByCodeAsync(entry.Id, cancellationToken);

            if (options.SkipExisting && existing != null)

            {

                report.IncrementSkipped();

                return;

            }



            var catalog = _mapper.MapCatalog(entry);



            IReadOnlyList<ExerciseMediaPipeline.UploadedImage> images = [];

            if (!options.SkipMedia && entry.Images.Count > 0)

            {

                var slug = FreeExerciseDbMapper.Slugify(entry.Id);

                images = await _media.ProcessAndUploadAsync(slug, entry.Images, cancellationToken);

            }



            var created = await _upserter.UpsertAsync(catalog, images, cancellationToken);

            if (created) report.IncrementImported();

            else report.IncrementUpdated();

        }

        catch (Exception ex)

        {

            report.IncrementFailed();

            lock (report.Failures)

            {

                report.Failures.Add($"{entry.Id}: {ex.Message}");

            }

            _logger.LogError(ex, "Failed to import {ExerciseCode}", entry.Id);

        }

        finally

        {

            onComplete();

        }

    }

}



public sealed class ImportOptions

{

    public int? Limit { get; init; }

    public bool SkipExisting { get; init; }

    public bool SkipMedia { get; init; }

}


