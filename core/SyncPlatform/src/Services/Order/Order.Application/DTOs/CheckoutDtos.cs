namespace Order.Application.DTOs;

public class AddressSuggestionDto
{
    public string Label { get; set; } = string.Empty;

    public double Lat { get; set; }

    public double Lng { get; set; }

    public string? PlaceId { get; set; }
}

public class ReverseGeocodeResultDto
{
    public string Label { get; set; } = string.Empty;

    public string? AddressLine { get; set; }

    public string? Ward { get; set; }

    public string? District { get; set; }

    public string? City { get; set; }

    public double Lat { get; set; }

    public double Lng { get; set; }
}

public class SaveDeliveryAddressDto
{
    public string Label { get; set; } = string.Empty;

    public double Lat { get; set; }

    public double Lng { get; set; }
}

public class DeliveryAddressDto
{
    public string Label { get; set; } = string.Empty;

    public double Lat { get; set; }

    public double Lng { get; set; }

    public DateTimeOffset SavedAt { get; set; }
}

public class CartItemDto
{
    public Guid FoodMenuItemId { get; set; }

    public string NameSnapshot { get; set; } = string.Empty;

    public string? ImageUrlSnapshot { get; set; }

    public decimal UnitPrice { get; set; }

    public int Quantity { get; set; }

    public string? Notes { get; set; }
}

public class CartDto
{
    public Guid? PartnerId { get; set; }

    public string? PartnerName { get; set; }

    public List<CartItemDto> Items { get; set; } = [];

    public decimal Subtotal { get; set; }

    /// <summary>Phí giao áp dụng khi đặt hàng (từ OrderSettings).</summary>
    public decimal DeliveryFee { get; set; }

    public int ItemCount => Items.Sum(i => i.Quantity);
}

public class CheckoutFeesDto
{
    public decimal DefaultDeliveryFee { get; set; }

    public string Currency { get; set; } = "VND";
}

public class AddCartItemDto
{
    public Guid PartnerId { get; set; }

    public Guid FoodMenuItemId { get; set; }

    public int Quantity { get; set; } = 1;

    public string? Notes { get; set; }
}

public class UpdateCartItemQuantityDto
{
    public int Quantity { get; set; }
}
