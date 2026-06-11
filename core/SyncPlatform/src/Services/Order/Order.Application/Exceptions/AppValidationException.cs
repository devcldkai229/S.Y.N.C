namespace Order.Application.Exceptions;

public class AppValidationException : AppException
{
    public Dictionary<string, string[]> Errors { get; }

    public AppValidationException() 
        : base("One or more validation failures have occurred.")
    {
        Errors = [];
    }

    public AppValidationException(Dictionary<string, string[]> errors) 
        : base("One or more validation failures have occurred.")
    {
        Errors = errors;
    }
}



