namespace Payment.Application.Exceptions;

public class UnauthorizedException : AppException
{
    public UnauthorizedException(string message) : base(message) { }
}
