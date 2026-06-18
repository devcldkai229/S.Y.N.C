using Exercise.Domain.Repositories;

using Exercise.ImportTool.Enrichment;

using Exercise.ImportTool.Services;

using Exercise.Infrastructure.Extensions;

using Microsoft.Extensions.Configuration;

using Microsoft.Extensions.DependencyInjection;

using Microsoft.Extensions.Hosting;

using Microsoft.Extensions.Logging;

using System.CommandLine;



static void AddConfigJson(IConfigurationBuilder config, string path)

{

    if (File.Exists(path))

    {

        config.AddJsonFile(path, optional: false, reloadOnChange: false);

    }

}



static IHost BuildHost(string[] args) =>

    Host.CreateDefaultBuilder(args)

        .ConfigureAppConfiguration((_, config) =>

        {

            config.Sources.Clear();



            var baseDir = AppContext.BaseDirectory;

            config.SetBasePath(baseDir);

            AddConfigJson(config, Path.Combine(baseDir, "appsettings.Import.json"));

            AddConfigJson(config, Path.Combine(baseDir, "appsettings.json"));

            AddConfigJson(config, Path.Combine(baseDir, "appsettings.Shared.json"));



            var projectDir = Path.GetFullPath(Path.Combine(baseDir, "..", "..", ".."));

            AddConfigJson(config, Path.Combine(projectDir, "appsettings.Import.json"));

            AddConfigJson(config, Path.Combine(projectDir, "..", "Exercise.API", "appsettings.json"));

            AddConfigJson(config, Path.Combine(projectDir, "..", "Exercise.API", "appsettings.Development.json"));



            config.AddEnvironmentVariables();

        })

        .ConfigureServices((ctx, services) =>

        {

            services.AddExerciseInfrastructure(ctx.Configuration);

            services.AddHttpClient<FreeExerciseDbFetcher>();

            services.AddHttpClient<LlmEnricher>();



            services.AddSingleton<FreeExerciseDbMapper>();

            services.AddSingleton<ExerciseMediaPipeline>();

            services.AddScoped<ExerciseCatalogUpserter>();

            services.AddScoped<ImportFreeExerciseDbRunner>();

            services.AddScoped<CleanExistingRunner>();

            services.AddScoped<ExerciseEnrichmentUpserter>();

            services.AddScoped<EnrichExercisesRunner>();

        })

        .ConfigureLogging(logging =>

        {

            logging.ClearProviders();

            logging.AddSimpleConsole(o =>

            {

                o.SingleLine = true;

                o.TimestampFormat = "HH:mm:ss ";

            });

        })

        .Build();



var limitOption = new Option<int?>("--limit", "Process only the first N exercises.");

var forceOption = new Option<bool>("--force", () => false, "Re-process exercises already enriched.");

var skipExistingOption = new Option<bool>("--skip-existing", () => false, "Skip exercises that already exist.");

var skipMediaOption = new Option<bool>("--skip-media", () => false, "Skip image upload.");



var importCommand = new Command("import-free-exercise-db", "Import Free Exercise DB into ExerciseCatalog + S3.")

{

    limitOption, skipExistingOption, skipMediaOption,

};



importCommand.SetHandler(async (int? limit, bool skipExisting, bool skipMedia) =>

{

    using var scope = BuildHost(args).Services.CreateScope();

    var report = await scope.ServiceProvider.GetRequiredService<ImportFreeExerciseDbRunner>()

        .RunAsync(new ImportOptions { Limit = limit, SkipExisting = skipExisting, SkipMedia = skipMedia });

    Environment.ExitCode = report.Failed > 0 ? 1 : 0;

}, limitOption, skipExistingOption, skipMediaOption);



var enrichCommand = new Command("enrich-exercises", "AI-enrich ExerciseCatalog via local Ollama/Qwen.")

{

    limitOption, forceOption,

};



enrichCommand.SetHandler(async (int? limit, bool force) =>

{

    using var scope = BuildHost(args).Services.CreateScope();

    var report = await scope.ServiceProvider.GetRequiredService<EnrichExercisesRunner>()

        .RunAsync(new EnrichmentRunOptions { Limit = limit, Force = force });

    Environment.ExitCode = report.Failed > 0 ? 1 : 0;

}, limitOption, forceOption);



var cleanCommand = new Command("clean-existing", "Sanitize stored ExerciseCatalog data and recompute tags/patterns.")

{

    limitOption,

};



cleanCommand.SetHandler(async (int? limit) =>

{

    using var scope = BuildHost(args).Services.CreateScope();

    var report = await scope.ServiceProvider.GetRequiredService<CleanExistingRunner>()

        .RunAsync(limit);

    Environment.ExitCode = report.Failed > 0 ? 1 : 0;

}, limitOption);



var approveCommand = new Command("approve-enrichment", "Set NeedsReview=false (publish contraindications).")

{

    limitOption,

};



approveCommand.SetHandler(async (int? limit) =>

{

    using var scope = BuildHost(args).Services.CreateScope();

    var repo = scope.ServiceProvider.GetRequiredService<IExerciseCatalogRepository>();

    var count = await repo.ApproveEnrichmentAsync(limit);

    Console.WriteLine($"Approved {count} exercise(s).");

}, limitOption);



var root = new RootCommand("SYNC Exercise import & enrichment utilities");

root.AddCommand(importCommand);

root.AddCommand(enrichCommand);

root.AddCommand(cleanCommand);

root.AddCommand(approveCommand);

return await root.InvokeAsync(args);


