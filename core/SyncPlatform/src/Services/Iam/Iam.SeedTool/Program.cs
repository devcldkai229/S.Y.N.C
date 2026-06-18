using Amazon.Extensions.NETCore.Setup;
using Iam.Application.Abstractions;
using Iam.Application.Services;
using Iam.Infrastructure.Extensions;
using Iam.SeedTool.Services;
using Libs.Seed.Extensions;
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
            var projectDir = Path.GetFullPath(Path.Combine(baseDir, "..", "..", ".."));
            AddConfigJson(config, Path.Combine(projectDir, "appsettings.Seed.json"));
            config.AddEnvironmentVariables();
        })
        .ConfigureServices((ctx, services) =>
        {
            services.AddSeedImagePipeline(ctx.Configuration);
            services.AddIamInfrastructure(ctx.Configuration);
            services.AddSingleton<IPasswordHasher, BcryptPasswordHasher>();
            services.AddSingleton<IamSeedReader>();
            services.AddScoped<IamUserSeedRunner>();
            services.AddScoped<IamAchievementSeedRunner>();
            services.AddScoped<IamDevSeedRunner>();
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

var limitOption = new Option<int?>("--limit", "Process only the first N records.");
var usersFileOption = new Option<string?>("--users-file", "Path to iam_users_seed_data.json.");
var achievementsFileOption = new Option<string?>("--achievements-file", "Path to iam_user_profile_seed_data.json.");

var usersCommand = new Command("seed-iam-users", "Seed IAM users + profiles from JSON with S3 avatars.")
{
    limitOption,
    usersFileOption,
};
usersCommand.SetHandler(async (int? limit, string? usersFile) =>
{
    using var scope = BuildHost(args).Services.CreateScope();
    var report = await scope.ServiceProvider.GetRequiredService<IamUserSeedRunner>()
        .RunAsync(new IamSeedRunOptions { Limit = limit, UsersFilePath = usersFile });
    Environment.ExitCode = report.UsersFailed > 0 ? 1 : 0;
}, limitOption, usersFileOption);

var achievementsCommand = new Command("seed-iam-achievements", "Seed IAM achievements with S3 icons.")
{
    limitOption,
    achievementsFileOption,
};
achievementsCommand.SetHandler(async (int? limit, string? achievementsFile) =>
{
    using var scope = BuildHost(args).Services.CreateScope();
    var report = await scope.ServiceProvider.GetRequiredService<IamAchievementSeedRunner>()
        .RunAsync(new IamSeedRunOptions { Limit = limit, AchievementsFilePath = achievementsFile });
    Environment.ExitCode = report.AchievementsFailed > 0 ? 1 : 0;
}, limitOption, achievementsFileOption);

var allCommand = new Command("seed-iam", "Seed IAM users then achievements.")
{
    limitOption,
    usersFileOption,
    achievementsFileOption,
};
allCommand.SetHandler(async (int? limit, string? usersFile, string? achievementsFile) =>
{
    using var scope = BuildHost(args).Services.CreateScope();
    var sp = scope.ServiceProvider;
    var achReport = await sp.GetRequiredService<IamAchievementSeedRunner>()
        .RunAsync(new IamSeedRunOptions { Limit = limit, AchievementsFilePath = achievementsFile });
    var userReport = await sp.GetRequiredService<IamUserSeedRunner>()
        .RunAsync(new IamSeedRunOptions { Limit = limit, UsersFilePath = usersFile });
    Environment.ExitCode = userReport.UsersFailed + achReport.AchievementsFailed > 0 ? 1 : 0;
}, limitOption, usersFileOption, achievementsFileOption);

var devCommand = new Command("seed-iam-dev", "Supplement IAM with IamSeedData dev users + achievements (stable cross-service IDs).");
devCommand.SetHandler(async () =>
{
    using var scope = BuildHost(args).Services.CreateScope();
    await scope.ServiceProvider.GetRequiredService<IamDevSeedRunner>().RunAsync();
    Environment.ExitCode = 0;
});

var root = new RootCommand("SYNC IAM seed utilities");
root.AddCommand(usersCommand);
root.AddCommand(achievementsCommand);
root.AddCommand(allCommand);
root.AddCommand(devCommand);
return await root.InvokeAsync(args);
