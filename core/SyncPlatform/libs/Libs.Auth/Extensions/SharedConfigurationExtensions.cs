using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Hosting;

namespace Libs.Auth.Extensions;

public static class SharedConfigurationExtensions
{
    private const string SharedFileName     = "appsettings.Shared.json";
    private const string SharedFileTemplate = "appsettings.Shared.{0}.json";

    /// <summary>
    /// Layers shared configuration on top of the per-service <c>appsettings.json</c> chain.
    /// Shared files are copied into the build output via MSBuild (<c>CopyToOutputDirectory</c>),
    /// so they are resolved from <see cref="AppContext.BaseDirectory"/> — not ContentRoot —
    /// which keeps <c>dotnet run</c> / IDE debugging working correctly.
    ///
    /// Final precedence (highest wins):
    /// <list type="number">
    ///   <item>Command-line arguments</item>
    ///   <item>Environment variables</item>
    ///   <item><c>appsettings.Shared.{Environment}.json</c> (added here)</item>
    ///   <item><c>appsettings.Shared.json</c> (added here)</item>
    ///   <item><c>appsettings.{Environment}.json</c> (added by host defaults)</item>
    ///   <item><c>appsettings.json</c> (added by host defaults)</item>
    /// </list>
    /// </summary>
    public static IConfigurationManager AddSharedConfiguration(
        this IConfigurationManager configuration,
        IHostEnvironment environment)
    {
        var baseDir = AppContext.BaseDirectory;

        var sharedPath = Path.Combine(baseDir, SharedFileName);
        if (!File.Exists(sharedPath))
        {
            throw new FileNotFoundException(
                $"Shared configuration file '{SharedFileName}' was not found in '{baseDir}'. " +
                "Ensure configs/appsettings.Shared.json exists (committed in repo) and rebuild the project. " +
                "See core/SyncPlatform/CONFIGURATION.md.",
                sharedPath);
        }

        configuration.AddJsonFile(sharedPath, optional: false, reloadOnChange: true);

        var sharedEnvPath = Path.Combine(baseDir, string.Format(SharedFileTemplate, environment.EnvironmentName));
        if (File.Exists(sharedEnvPath))
            configuration.AddJsonFile(sharedEnvPath, optional: true, reloadOnChange: true);

        return configuration;
    }
}
