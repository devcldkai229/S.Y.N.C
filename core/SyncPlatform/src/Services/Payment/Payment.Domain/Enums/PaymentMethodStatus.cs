namespace Payment.Domain.Enums;

public enum PaymentMethodStatus
{
    Active = 0,
    Expired = 1,
    Revoked = 2,
    PendingVerification = 3
}
