namespace Order.Application.Clients;

public class ValidatedMenuItem
{
    public Guid FoodMenuItemId { get; set; }

    public Guid PartnerId { get; set; }

    public string NameVi { get; set; } = string.Empty;

    public string? ImageUrl { get; set; }

    public decimal Price { get; set; }

    public string Currency { get; set; } = "VND";

    public int Calories { get; set; }

    public decimal ProteinGram { get; set; }

    public decimal CarbGram { get; set; }

    public decimal FatGram { get; set; }

    public bool IsAvailable { get; set; }
}

public class ValidateOrderItemsRequest
{
    public Guid PartnerId { get; set; }

    public List<Guid> FoodMenuItemIds { get; set; } = [];
}

public class ValidateOrderItemsResult
{
    public bool IsValid { get; set; }

    public string? ErrorMessage { get; set; }

    public decimal PartnerCommissionRate { get; set; }

    public List<ValidatedMenuItem> Items { get; set; } = [];
}

public class PartnerInternalDto
{
    public Guid Id { get; set; }

    public Guid OwnerUserId { get; set; }

    public string Name { get; set; } = string.Empty;

    public string Status { get; set; } = string.Empty;

    public decimal CommissionRate { get; set; }

    public string? Address { get; set; }

    public double? Latitude { get; set; }

    public double? Longitude { get; set; }
}

public interface IMarketplaceClient
{
    Task<ValidateOrderItemsResult> ValidateOrderItemsAsync(
        ValidateOrderItemsRequest request,
        CancellationToken cancellationToken = default);

    Task<PartnerInternalDto?> GetPartnerAsync(Guid partnerId, CancellationToken cancellationToken = default);
}
