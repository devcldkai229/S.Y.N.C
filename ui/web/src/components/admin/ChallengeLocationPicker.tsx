"use client";

import { useCallback, useEffect, useRef, useState } from "react";
import maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Loader2, MapPin, Search } from "lucide-react";
import {
  AWS_MAP_DEFAULT_LAT,
  AWS_MAP_DEFAULT_LNG,
  AWS_MAP_DEFAULT_ZOOM,
  getAwsMapStyleDescriptorUrl,
  isAwsMapConfigured,
} from "@/lib/aws-map-config";
import {
  isAwsPlacesConfigured,
  reverseAwsPlaces,
  searchAwsPlaces,
  type AwsPlaceSuggestion,
  type AwsReverseGeocodeResult,
} from "@/lib/aws-places";
import {
  isCoordinateLabel,
  reverseChallengeLocation,
  searchChallengeLocation,
  type ChallengeLocationValue,
} from "@/hooks/admin/use-social";

async function searchPlaces(
  query: string,
  biasLat?: number,
  biasLng?: number,
): Promise<AwsPlaceSuggestion[]> {
  if (isAwsPlacesConfigured()) {
    try {
      return await searchAwsPlaces(query, biasLat, biasLng);
    } catch {
      // Map-only API keys return 403 for Places v2 — fall back to Social Place Index.
    }
  }

  const results = await searchChallengeLocation(query, biasLat, biasLng);
  return results.map((s) => ({
    label: s.label,
    lat: s.lat,
    lng: s.lng,
    placeId: s.placeId,
  }));
}

async function reversePlaces(lat: number, lng: number): Promise<AwsReverseGeocodeResult> {
  if (isAwsPlacesConfigured()) {
    try {
      return await reverseAwsPlaces(lat, lng);
    } catch {
      // fall through to backend Place Index
    }
  }

  const result = await reverseChallengeLocation(lat, lng);
  return {
    label: result.label,
    addressLine: result.addressLine ?? undefined,
    ward: result.ward ?? undefined,
    district: result.district ?? undefined,
    city: result.city ?? undefined,
    lat: result.lat,
    lng: result.lng,
  };
}

export interface ChallengeLocationPickerProps {
  value: ChallengeLocationValue | null;
  onChange: (value: ChallengeLocationValue | null) => void;
}

export function ChallengeLocationPicker({ value, onChange }: ChallengeLocationPickerProps) {
  const mapContainerRef = useRef<HTMLDivElement>(null);
  const searchWrapRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const markerRef = useRef<maplibregl.Marker | null>(null);
  const reverseTimerRef = useRef<ReturnType<typeof setTimeout> | null>(null);
  const skipSearchRef = useRef(false);

  const [searchText, setSearchText] = useState("");
  const [suggestions, setSuggestions] = useState<AwsPlaceSuggestion[]>([]);
  const [searching, setSearching] = useState(false);
  const [reversing, setReversing] = useState(false);
  const [showSuggestions, setShowSuggestions] = useState(false);
  const [hasSearched, setHasSearched] = useState(false);
  const [searchError, setSearchError] = useState<string | null>(null);

  const styleUrl = getAwsMapStyleDescriptorUrl();
  const mapAvailable = isAwsMapConfigured() && !!styleUrl;

  const placeMarker = useCallback((lat: number, lng: number) => {
    if (!mapRef.current) return;
    if (markerRef.current) {
      markerRef.current.setLngLat([lng, lat]);
    } else {
      markerRef.current = new maplibregl.Marker({ color: "#e11d48" })
        .setLngLat([lng, lat])
        .addTo(mapRef.current);
    }
  }, []);

  const applyLocation = useCallback(
    (loc: ChallengeLocationValue, displayAddress?: string) => {
      const addressText = displayAddress ?? loc.address;
      onChange(loc);
      skipSearchRef.current = true;
      setSearchText(isCoordinateLabel(addressText) ? loc.address : addressText);
      setSuggestions([]);
      setShowSuggestions(false);
      setHasSearched(false);
      setSearchError(null);
      if (mapRef.current) {
        mapRef.current.flyTo({ center: [loc.longitude, loc.latitude], zoom: 15 });
        placeMarker(loc.latitude, loc.longitude);
      }
    },
    [onChange, placeMarker],
  );

  const reverseAt = useCallback(
    async (lat: number, lng: number) => {
      setReversing(true);
      try {
        const result = await reversePlaces(lat, lng);
        const label =
          result.label && !isCoordinateLabel(result.label)
            ? result.label
            : [result.addressLine, result.ward, result.district, result.city]
                .filter(Boolean)
                .join(", ");

        applyLocation(
          {
            address: label || result.label || "Địa chỉ đã chọn",
            latitude: result.lat || lat,
            longitude: result.lng || lng,
          },
          label || undefined,
        );
      } catch {
        onChange({ address: "Địa chỉ đã chọn trên bản đồ", latitude: lat, longitude: lng });
        skipSearchRef.current = true;
        setSearchText("Địa chỉ đã chọn trên bản đồ");
      } finally {
        setReversing(false);
      }
    },
    [applyLocation, onChange],
  );

  useEffect(() => {
    if (value === null) {
      setSearchText("");
      return;
    }
    if (!isCoordinateLabel(value.address)) {
      skipSearchRef.current = true;
      setSearchText(value.address);
    }
  }, [value]);

  useEffect(() => {
    if (!mapAvailable || !mapContainerRef.current || mapRef.current) return;

    const map = new maplibregl.Map({
      container: mapContainerRef.current,
      style: styleUrl!,
      center: value
        ? [value.longitude, value.latitude]
        : [AWS_MAP_DEFAULT_LNG, AWS_MAP_DEFAULT_LAT],
      zoom: value ? 15 : AWS_MAP_DEFAULT_ZOOM,
    });

    map.addControl(new maplibregl.NavigationControl({ showCompass: false }), "top-right");

    map.on("click", (e) => {
      const { lat, lng } = e.lngLat;
      placeMarker(lat, lng);
      if (reverseTimerRef.current) clearTimeout(reverseTimerRef.current);
      reverseTimerRef.current = setTimeout(() => reverseAt(lat, lng), 200);
    });

    mapRef.current = map;
    if (value) placeMarker(value.latitude, value.longitude);

    return () => {
      markerRef.current?.remove();
      markerRef.current = null;
      map.remove();
      mapRef.current = null;
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [mapAvailable, styleUrl]);

  useEffect(() => {
    const onDocClick = (e: MouseEvent) => {
      if (!searchWrapRef.current?.contains(e.target as Node)) {
        setShowSuggestions(false);
      }
    };
    document.addEventListener("mousedown", onDocClick);
    return () => document.removeEventListener("mousedown", onDocClick);
  }, []);

  useEffect(() => {
    if (skipSearchRef.current) {
      skipSearchRef.current = false;
      return;
    }

    const q = searchText.trim();
    if (q.length < 2) {
      setSuggestions([]);
      setHasSearched(false);
      setShowSuggestions(false);
      setSearchError(null);
      return;
    }

    const timer = setTimeout(async () => {
      setSearching(true);
      setShowSuggestions(true);
      setSearchError(null);
      try {
        const biasLat = value?.latitude ?? mapRef.current?.getCenter().lat ?? AWS_MAP_DEFAULT_LAT;
        const biasLng = value?.longitude ?? mapRef.current?.getCenter().lng ?? AWS_MAP_DEFAULT_LNG;
        const results = await searchPlaces(q, biasLat, biasLng);
        setSuggestions(results);
        setHasSearched(true);
        setShowSuggestions(true);
      } catch (err) {
        setSuggestions([]);
        setHasSearched(true);
        setSearchError(
          err instanceof Error
            ? err.message
            : "Không tìm được địa chỉ. Kiểm tra AWS Places API key hoặc Social Place Index.",
        );
      } finally {
        setSearching(false);
      }
    }, 300);

    return () => clearTimeout(timer);
  }, [searchText, value?.latitude, value?.longitude]);

  const selectSuggestion = (s: AwsPlaceSuggestion) => {
    applyLocation({
      address: s.label,
      latitude: s.lat,
      longitude: s.lng,
    });
  };

  const onSearchChange = (text: string) => {
    setSearchText(text);
    if (value && text !== value.address) {
      onChange(null);
    }
  };

  const showDropdown =
    showSuggestions &&
    searchText.trim().length >= 2 &&
    (searching || suggestions.length > 0 || hasSearched);

  return (
    <div className="space-y-2">
      <Label>Địa chỉ tổ chức *</Label>

      <div className="relative rounded-md border overflow-hidden">
        {mapAvailable ? (
          <div
            ref={mapContainerRef}
            className="h-56 w-full"
            aria-label="Bản đồ chọn địa chỉ"
          />
        ) : (
          <div className="flex h-56 items-center justify-center bg-muted/40 px-4 text-center text-xs text-muted-foreground">
            Cấu hình <code className="mx-1">NEXT_PUBLIC_AWS_MAP_API_KEY</code> để hiển thị bản đồ
            và tìm địa chỉ bằng AWS Places.
          </div>
        )}

        <div ref={searchWrapRef} className="absolute top-2 left-2 right-10 z-10">
          <div className="relative shadow-md rounded-md bg-background">
            <Search className="absolute left-2.5 top-2.5 h-4 w-4 text-muted-foreground pointer-events-none" />
            <Input
              value={searchText}
              onChange={(e) => onSearchChange(e.target.value)}
              onFocus={() => {
                if (searchText.trim().length >= 2) setShowSuggestions(true);
              }}
              placeholder="Tìm địa chỉ..."
              autoComplete="off"
              className="pl-8 pr-8 bg-background/95 backdrop-blur-sm"
            />
            {(searching || reversing) && (
              <Loader2 className="absolute right-2.5 top-2.5 w-4 h-4 animate-spin text-muted-foreground" />
            )}

            {showDropdown && (
              <ul className="absolute z-20 mt-1 w-full rounded-md border bg-popover shadow-lg max-h-52 overflow-y-auto">
                {searching && suggestions.length === 0 && !searchError && (
                  <li className="px-3 py-2 text-sm text-muted-foreground">Đang tìm...</li>
                )}
                {!searching && searchError && (
                  <li className="px-3 py-2 text-sm text-destructive">{searchError}</li>
                )}
                {!searching && !searchError && hasSearched && suggestions.length === 0 && (
                  <li className="px-3 py-2 text-sm text-muted-foreground">Không có kết quả</li>
                )}
                {suggestions.map((s, i) => (
                  <li key={`${s.placeId ?? s.label}-${i}`}>
                    <button
                      type="button"
                      className="w-full px-3 py-2.5 text-left text-sm hover:bg-muted flex items-start gap-2"
                      onMouseDown={(e) => e.preventDefault()}
                      onClick={() => selectSuggestion(s)}
                    >
                      <MapPin className="w-3.5 h-3.5 mt-0.5 shrink-0 text-rose-500" />
                      <span className="line-clamp-2">{s.label}</span>
                    </button>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </div>
      </div>

      {value && !isCoordinateLabel(searchText) && (
        <p className="flex items-start gap-1.5 text-xs text-muted-foreground">
          <MapPin className="w-3.5 h-3.5 mt-0.5 shrink-0 text-rose-500" />
          <span className="line-clamp-2">{searchText || value.address}</span>
        </p>
      )}
    </div>
  );
}
