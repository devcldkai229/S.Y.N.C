namespace Iam.Application.Common;

public sealed class AppValidationException : Exception
{
    public AppValidationException(string message)
        : base(message)
    {
        Errors = new Dictionary<string, string[]>
        {
            [""] = [message]
        };
    }

    public AppValidationException(IDictionary<string, string[]> errors)
        : base("One or more validation errors occurred.")
    {
        Errors = errors;
    }

    public IDictionary<string, string[]> Errors { get; }
}
