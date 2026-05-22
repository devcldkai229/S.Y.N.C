using Iam.Application.Common;
using Iam.Application.Dtos;
using Iam.Application.Services;

namespace Iam.API.Endpoints;

public static class MeEndpoints
{
    public static IEndpointRouteBuilder MapMeEndpoints(this IEndpointRouteBuilder app)
    {
        var group = app.MapGroup("/api/me")
            .WithTags("Me")
            .RequireAuthorization();

        group.MapGet("/profile-settings", GetProfileSettings)
            .WithName("GetMyProfileSettings")
            .WithSummary("View account profile, fitness profile, and AI preferences.");

        group.MapGet("/inventory", GetInventory)
            .WithName("GetMyInventory")
            .WithSummary("View vouchers and unlocked achievements inventory.");

        group.MapPut("/basic-profile", UpdateBasicProfile)
            .WithName("UpdateMyBasicProfile")
            .WithSummary("Update display account fields (name, avatar, language, timezone).");

        group.MapPut("/fitness-profile", UpdateFitnessProfile)
            .WithName("UpdateMyFitnessProfile")
            .WithSummary("Create or update biometric / fitness profile.");

        group.MapPut("/account-preferences", UpdateAccountPreferences)
            .WithName("UpdateMyAccountPreferences")
            .WithSummary("Configure AI agent persona, motivation, nutrition prefs, and consents.");

        return app;
    }

    private static async Task<IResult> GetProfileSettings(
        UserMeService service,
        CancellationToken cancellationToken)
    {
        var result = await service.GetProfileSettingsAsync(cancellationToken);
        return Results.Ok(result);
    }

    private static async Task<IResult> GetInventory(
        UserMeService service,
        CancellationToken cancellationToken)
    {
        var result = await service.GetInventoryAsync(cancellationToken);
        return Results.Ok(result);
    }

    private static async Task<IResult> UpdateBasicProfile(
        UpdateBasicProfileRequest request,
        UserMeService service,
        CancellationToken cancellationToken)
    {
        var result = await service.UpdateBasicProfileAsync(request, cancellationToken);
        return Results.Ok(result);
    }

    private static async Task<IResult> UpdateFitnessProfile(
        UpdateFitnessProfileRequest request,
        UserMeService service,
        CancellationToken cancellationToken)
    {
        var result = await service.UpdateFitnessProfileAsync(request, cancellationToken);
        return Results.Ok(result);
    }

    private static async Task<IResult> UpdateAccountPreferences(
        UpdateAccountPreferencesRequest request,
        UserMeService service,
        CancellationToken cancellationToken)
    {
        var result = await service.UpdateAccountPreferencesAsync(request, cancellationToken);
        return Results.Ok(result);
    }
}
