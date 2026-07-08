namespace Social.Application.DTOs;

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

public class ChallengeMapConfigDto
{
    public string Region { get; set; } = "ap-southeast-1";

    public string MapName { get; set; } = "sync-map";

    public string MapStyle { get; set; } = "Hybrid";

    public bool PlacesEnabled { get; set; }
}
