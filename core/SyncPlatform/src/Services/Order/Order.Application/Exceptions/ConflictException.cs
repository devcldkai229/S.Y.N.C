namespace Order.Application.Exceptions;

public class ConflictException : AppException
{
    public ConflictException(string message, object? details = null) : base(message)
    {
        Details = details;
    }

    public object? Details { get; }
}



