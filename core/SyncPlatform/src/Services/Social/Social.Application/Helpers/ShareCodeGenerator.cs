using Social.Domain.Models;
using Social.Domain.Repositories;

namespace Social.Application.Helpers;

public static class ShareCodeGenerator
{
    private const string Alphabet = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
    private const int CodeLength = 8;
    private const int MaxAllocationAttempts = 12;

    public static string Generate()
    {
        Span<char> buffer = stackalloc char[CodeLength];
        for (var i = 0; i < CodeLength; i++)
            buffer[i] = Alphabet[Random.Shared.Next(Alphabet.Length)];
        return new string(buffer);
    }

    public static async Task AssignUniqueToPostAsync(
        IPostRepository posts,
        Post post,
        CancellationToken cancellationToken = default)
    {
        for (var attempt = 0; attempt < MaxAllocationAttempts; attempt++)
        {
            var code = Generate();
            if (!await posts.ShareCodeExistsAsync(code, cancellationToken))
            {
                post.ShareCode = code.ToUpperInvariant();
                return;
            }
        }

        throw new InvalidOperationException("Unable to allocate a unique share code for the post.");
    }
}
