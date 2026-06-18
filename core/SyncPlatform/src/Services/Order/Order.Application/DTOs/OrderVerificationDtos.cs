namespace Order.Application.DTOs;

public class OrderVerificationResultDto
{
    public bool IsVerified { get; set; }

    public Guid? OrderId { get; set; }
}
