namespace Marketplace.Application.DTOs;

public class ValidateOrderItemsRequestDto
{
    public Guid PartnerId { get; set; }

    public List<Guid> FoodMenuItemIds { get; set; } = [];
}

public class ValidatedMenuItemDto
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

public class ValidateOrderItemsResultDto
{
    public bool IsValid { get; set; }

    public string? ErrorMessage { get; set; }

    public decimal PartnerCommissionRate { get; set; }

    public List<ValidatedMenuItemDto> Items { get; set; } = [];
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
