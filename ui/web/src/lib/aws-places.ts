/**
 * AWS Location Places API v2 (client-side, API key auth).
 * Docs: SearchText + ReverseGeocode at places.geo.{region}.amazonaws.com/v2
 */

import {
  AWS_MAP_DEFAULT_LAT,
  AWS_MAP_DEFAULT_LNG,
} from "@/lib/aws-map-config";

const region = process.env.NEXT_PUBLIC_AWS_MAP_REGION ?? "ap-southeast-1";
const apiKey = process.env.NEXT_PUBLIC_AWS_MAP_API_KEY ?? "";

export function isAwsPlacesConfigured(): boolean {
  return apiKey.length > 0;
}

export interface AwsPlaceSuggestion {
  label: string;
  lat: number;
  lng: number;
  placeId?: string | null;
}

export interface AwsReverseGeocodeResult {
  label: string;
  addressLine?: string;
  ward?: string;
  district?: string;
  city?: string;
  lat: number;
  lng: number;
}

interface PlacesAddress {
  Label?: string;
  AddressNumber?: string;
  Street?: string;
  District?: string;
  Locality?: string;
  SubDistrict?: string;
  SubRegion?: { Name?: string };
  Region?: { Name?: string };
}

interface PlacesResultItem {
  PlaceId?: string;
  Title?: string;
  Position?: number[];
  Address?: PlacesAddress;
}

function placesBaseUrl(): string {
  return `https://places.geo.${region}.amazonaws.com/v2`;
}

function formatAddressLine(address?: PlacesAddress): string | undefined {
  if (!address) return undefined;
  if (address.AddressNumber && address.Street) {
    return `${address.AddressNumber} ${address.Street}`;
  }
  return address.Street || undefined;
}

function buildLabel(item: PlacesResultItem): string {
  const fromAddress = item.Address?.Label?.trim();
  if (fromAddress) return fromAddress;

  const title = item.Title?.trim();
  if (title) return title;

  const parts = [
    formatAddressLine(item.Address),
    item.Address?.SubDistrict,
    item.Address?.District,
    item.Address?.Locality,
    item.Address?.SubRegion?.Name,
    item.Address?.Region?.Name,
  ].filter((p): p is string => !!p && p.trim().length > 0);

  return parts.join(", ");
}

async function placesPost<T>(path: string, body: Record<string, unknown>): Promise<T> {
  if (!isAwsPlacesConfigured()) {
    throw new Error("NEXT_PUBLIC_AWS_MAP_API_KEY is not configured for AWS Places.");
  }

  const url = `${placesBaseUrl()}${path}?key=${encodeURIComponent(apiKey)}`;
  const response = await fetch(url, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(body),
  });

  if (!response.ok) {
    const text = await response.text().catch(() => "");
    throw new Error(text || `AWS Places ${path} failed: ${response.status}`);
  }

  return response.json() as Promise<T>;
}

/**
 * Typeahead / keyword place search via Places SearchText.
 * Prefer BiasPosition near map center (HCMC default).
 */
export async function searchAwsPlaces(
  query: string,
  biasLat?: number,
  biasLng?: number,
): Promise<AwsPlaceSuggestion[]> {
  const q = query.trim();
  if (q.length < 2 || !isAwsPlacesConfigured()) return [];

  const lat = biasLat ?? AWS_MAP_DEFAULT_LAT;
  const lng = biasLng ?? AWS_MAP_DEFAULT_LNG;

  const data = await placesPost<{ ResultItems?: PlacesResultItem[] }>("/search-text", {
    QueryText: q,
    MaxResults: 8,
    Language: "vi",
    IntendedUse: "SingleUse",
    BiasPosition: [lng, lat],
    Filter: {
      IncludeCountries: ["VNM"],
    },
  });

  const suggestions: AwsPlaceSuggestion[] = [];
  for (const item of data.ResultItems ?? []) {
    const position = item.Position;
    const itemLng = position?.[0];
    const itemLat = position?.[1];
    const label = buildLabel(item);
    if (
      !label ||
      itemLat == null ||
      itemLng == null ||
      !Number.isFinite(itemLat) ||
      !Number.isFinite(itemLng)
    ) {
      continue;
    }

    suggestions.push({
      label,
      lat: itemLat,
      lng: itemLng,
      placeId: item.PlaceId ?? null,
    });
  }
  return suggestions;
}

/** Reverse geocode map click via Places ReverseGeocode. */
export async function reverseAwsPlaces(
  lat: number,
  lng: number,
): Promise<AwsReverseGeocodeResult> {
  if (!isAwsPlacesConfigured()) {
    return {
      label: "Địa chỉ đã chọn trên bản đồ",
      lat,
      lng,
    };
  }

  const data = await placesPost<{ ResultItems?: PlacesResultItem[] }>("/reverse-geocode", {
    QueryPosition: [lng, lat],
    MaxResults: 1,
    Language: "vi",
    IntendedUse: "SingleUse",
  });

  const item = data.ResultItems?.[0];
  if (!item) {
    return {
      label: "Địa chỉ đã chọn trên bản đồ",
      lat,
      lng,
    };
  }

  const label = buildLabel(item) || "Địa chỉ đã chọn trên bản đồ";
  const address = item.Address;

  return {
    label,
    addressLine: formatAddressLine(address),
    ward: address?.SubDistrict || address?.District,
    district: address?.Locality || address?.SubRegion?.Name,
    city: address?.Region?.Name,
    lat: item.Position?.[1] ?? lat,
    lng: item.Position?.[0] ?? lng,
  };
}
