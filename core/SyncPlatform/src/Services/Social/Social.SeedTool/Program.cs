using Libs.Seed.Extensions;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.DependencyInjection;
using Microsoft.Extensions.Hosting;
using Microsoft.Extensions.Logging;
using MongoDB.Bson;
using MongoDB.Bson.Serialization;
using MongoDB.Bson.Serialization.Serializers;
using Social.Infrastructure.Extensions;
using Social.SeedTool.Services;
using System.CommandLine;

BsonSerializer.RegisterSerializer(new GuidSerializer(GuidRepresentation.Standard));

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
            var projectDir = Path.GetFullPath(Path.Combine(baseDir, "..", "..", ".."));
            AddConfigJson(config, Path.Combine(projectDir, "appsettings.Seed.json"));
            config.AddEnvironmentVariables();
        })
        .ConfigureServices((ctx, services) =>
        {
            services.AddSeedImagePipeline(ctx.Configuration);
            services.AddSocialInfrastructure(ctx.Configuration);
            services.AddSingleton<SocialSeedReader>();
            services.AddScoped<SocialSeedRunner>();
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

var limitOption = new Option<int?>("--limit", "Process only the first N posts (and related subset).");
var seedFileOption = new Option<string?>("--seed-file", "Path to social_seed_data.json.");

var seedCommand = new Command("seed-social", "Seed Social posts/comments/interactions/follows from JSON.")
{
    limitOption,
    seedFileOption,
};
seedCommand.SetHandler(async (int? limit, string? seedFile) =>
{
    using var scope = BuildHost(args).Services.CreateScope();
    await scope.ServiceProvider.GetRequiredService<SocialSeedRunner>()
        .RunAsync(new SocialSeedRunOptions { Limit = limit, SeedFilePath = seedFile });
}, limitOption, seedFileOption);

var root = new RootCommand("SYNC Social seed utilities");
root.AddCommand(seedCommand);
return await root.InvokeAsync(args);
