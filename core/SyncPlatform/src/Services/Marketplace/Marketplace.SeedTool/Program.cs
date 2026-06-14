using Amazon.Extensions.NETCore.Setup;
using Amazon.S3;
using Marketplace.Infrastructure.Extensions;
using Marketplace.SeedTool.Configuration;
using Marketplace.SeedTool.Services;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using System.CommandLine;

static void AddConfigJson(IConfigurationBuilder config, string path)
{
    if (File.Exists(path))
        config.AddJsonFile(path, optional: false, reloadOnChange: false);
}

static IHost BuildHost(string[] args) =>
    Host.CreateDefaultBuilder(args)
        .ConfigureAppConfiguration((_, config) =>
        {
            config.Sources.Clear();

            var baseDir = AppContext.BaseDirectory;
            config.SetBasePath(baseDir);
            AddConfigJson(config, Path.Combine(baseDir, "appsettings.Seed.json"));
            AddConfigJson(config, Path.Combine(baseDir, "appsettings.json"));
            AddConfigJson(config, Path.Combine(baseDir, "appsettings.Shared.json"));

            var projectDir = Path.GetFullPath(Path.Combine(baseDir, "..", "..", ".."));
            AddConfigJson(config, Path.Combine(projectDir, "appsettings.Seed.json"));
            AddConfigJson(config, Path.Combine(projectDir, "..", "Marketplace.API", "appsettings.json"));

            config.AddEnvironmentVariables();
        })
        .ConfigureServices((ctx, services) =>
        {
            services.Configure<StorageOptions>(ctx.Configuration.GetSection(StorageOptions.SectionName));
            services.Configure<PexelsOptions>(ctx.Configuration.GetSection(PexelsOptions.SectionName));

            var awsOptions = ctx.Configuration.GetAWSOptions();
            services.AddDefaultAWSOptions(awsOptions);
            services.AddAWSService<IAmazonS3>();
            services.AddSingleton<IStorageService, S3StorageService>();

            services.AddMarketplaceInfrastructure(ctx.Configuration);
            services.AddHttpClient<PexelsClient>();

            services.AddSingleton<SeedReader>();
            services.AddSingleton<MarketplaceMapper>();
            services.AddSingleton<ImagePipeline>();
            services.AddScoped<MarketplaceUpserter>();
            services.AddScoped<SeedMarketplaceRunner>();
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

var limitOption = new Option<int?>("--limit", "Process only the first N kitchens.");
var seedFileOption = new Option<string?>("--seed-file", "Path to marketplace_seed_data.json.");

var seedCommand = new Command("seed-marketplace", "Seed Marketplace partners & menu from JSON + Pexels + S3.")
{
    limitOption,
    seedFileOption,
};

seedCommand.SetHandler(async (int? limit, string? seedFile) =>
{
    using var scope = BuildHost(args).Services.CreateScope();
    var report = await scope.ServiceProvider.GetRequiredService<SeedMarketplaceRunner>()
        .RunAsync(new SeedRunOptions { Limit = limit, SeedFilePath = seedFile });

    Environment.ExitCode = report.PartnersFailed + report.DishesFailed > 0 ? 1 : 0;
}, limitOption, seedFileOption);

var root = new RootCommand("SYNC Marketplace seed utilities");
root.AddCommand(seedCommand);
return await root.InvokeAsync(args);
