using Libs.Storage.Services;
using Social.Application.DTOs;
using Social.Domain.Models;

namespace Social.Application.Helpers;

internal static class SocialMediaPresentation
{
    public static AuthorSnapshotDto ToAuthorDto(AuthorSnapshot snapshot, IMediaUrlResolver media) =>
        new()
        {
            FullName = snapshot.FullName,
            AvatarUrl = media.ResolveForDisplay(snapshot.AvatarUrl),
        };

    public static IReadOnlyList<string> ResolveMediaUrls(IReadOnlyList<string>? urls, IMediaUrlResolver media) =>
        urls?.Select(u => media.ResolveForDisplay(u) ?? u).ToList() ?? [];
}
