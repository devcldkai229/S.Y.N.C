import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/services/api";
import { toast } from "sonner";

export interface AuthorSnapshotDto {
  fullName:   string;
  avatarUrl?: string | null;
}

export interface PostMetricsDto {
  likeCount:    number;
  commentCount: number;
  shareCount:   number;
}

export interface PostDto {
  id:             string;
  createdAt:      string;
  authorId:       string;
  authorSnapshot: AuthorSnapshotDto;
  postType:       string;
  content:        string;
  mediaUrls:      string[];
  metrics:        PostMetricsDto;
  isPublic:       boolean;
  shareCode:      string;
}

export type ChallengeGoalType = "TotalDistance" | "TotalWorkouts" | "TotalCaloriesBurned";
export const CHALLENGE_GOAL_TYPES: ChallengeGoalType[] = ["TotalDistance", "TotalWorkouts", "TotalCaloriesBurned"];

export interface CommunityChallengeDto {
  id:               string;
  creatorId:        string;
  title:            string;
  description:      string;
  startDate:        string;
  endDate:          string;
  goalType:         ChallengeGoalType;
  targetValue:      number;
  pointRewards?:    number | null;
  gifts:            string[];
  participantCount: number;
  status:           string;
  address?:         string | null;
}

export interface ChallengeLocationValue {
  address:   string;
  latitude:  number;
  longitude: number;
}

export interface AddressSuggestionDto {
  label:   string;
  lat:     number;
  lng:     number;
  placeId?: string | null;
}

export interface ReverseGeocodeResultDto {
  label:       string;
  addressLine?: string | null;
  ward?:       string | null;
  district?:   string | null;
  city?:       string | null;
  lat:         number;
  lng:         number;
}

function pickString(obj: Record<string, unknown>, ...keys: string[]): string {
  for (const key of keys) {
    const v = obj[key];
    if (typeof v === "string" && v.trim()) return v.trim();
  }
  return "";
}

function pickNumber(obj: Record<string, unknown>, ...keys: string[]): number {
  for (const key of keys) {
    const v = obj[key];
    if (typeof v === "number" && Number.isFinite(v)) return v;
  }
  return 0;
}

function normalizeSuggestion(raw: AddressSuggestionDto | Record<string, unknown>): AddressSuggestionDto {
  const o = raw as Record<string, unknown>;
  return {
    label:   pickString(o, "label", "Label"),
    lat:     pickNumber(o, "lat", "Lat"),
    lng:     pickNumber(o, "lng", "Lng"),
    placeId: (o.placeId ?? o.PlaceId ?? null) as string | null | undefined,
  };
}

function normalizeReverse(raw: ReverseGeocodeResultDto | Record<string, unknown>): ReverseGeocodeResultDto {
  const o = raw as Record<string, unknown>;
  const addressLine = pickString(o, "addressLine", "AddressLine") || undefined;
  const ward = pickString(o, "ward", "Ward") || undefined;
  const district = pickString(o, "district", "District") || undefined;
  const city = pickString(o, "city", "City") || undefined;
  const label =
    pickString(o, "label", "Label") ||
    [addressLine, ward, district, city].filter(Boolean).join(", ");

  return {
    label,
    addressLine,
    ward,
    district,
    city,
    lat: pickNumber(o, "lat", "Lat"),
    lng: pickNumber(o, "lng", "Lng"),
  };
}

export function isCoordinateLabel(text: string): boolean {
  return /^-?\d+(\.\d+)?\s*,\s*-?\d+(\.\d+)?$/.test(text.trim());
}

export interface CreateChallengeDto {
  title:                string;
  description:          string;
  registrationDeadline: string;
  startDate:            string;
  endDate:              string;
  goalType:             ChallengeGoalType;
  targetValue:          number;
  pointRewards?:        number | null;
  gifts?:               string[];
  address:              string;
  latitude:             number;
  longitude:            number;
}

export async function searchChallengeLocation(
  q: string,
  lat?: number,
  lng?: number,
): Promise<AddressSuggestionDto[]> {
  const params = new URLSearchParams({ q });
  if (lat != null) params.set("lat", String(lat));
  if (lng != null) params.set("lng", String(lng));
  return (await api.get<AddressSuggestionDto[]>(
    `/api/v1/admin/challenges/location/search?${params}`,
  ))
    .map(normalizeSuggestion)
    .filter((s) => s.label && s.lat !== 0 && s.lng !== 0);
}

export async function reverseChallengeLocation(
  lat: number,
  lng: number,
): Promise<ReverseGeocodeResultDto> {
  const params = new URLSearchParams({
    lat: String(lat),
    lng: String(lng),
  });
  return normalizeReverse(
    await api.get<ReverseGeocodeResultDto>(
      `/api/v1/admin/challenges/location/reverse?${params}`,
    ),
  );
}

export function useFeed(limit = 50) {
  return useQuery({
    queryKey: ["admin", "social", "feed", limit],
    queryFn:  () => api.get<PostDto[]>(`/api/v1/social/posts/feed?limit=${limit}`),
  });
}

export function useDeletePost() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(`/api/v1/social/posts/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "social", "feed"] });
      toast.success("Đã gỡ bài viết");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useAllChallenges(params: { status?: string; pageNumber?: number; pageSize?: number } = {}) {
  const qs = new URLSearchParams();
  if (params.status) qs.set("status", params.status);
  qs.set("pageNumber", String(params.pageNumber ?? 1));
  qs.set("pageSize",   String(params.pageSize   ?? 50));

  return useQuery({
    queryKey: ["admin", "social", "challenges", params],
    queryFn:  () => api.getPaged<CommunityChallengeDto>(`/api/v1/admin/challenges?${qs}`),
  });
}

export function useCreateChallenge() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (dto: CreateChallengeDto) => api.post<CommunityChallengeDto>("/api/v1/admin/challenges", dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "social", "challenges"] });
      toast.success("Đã tạo thử thách");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useUpdateChallenge() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, dto }: { id: string; dto: Partial<CreateChallengeDto> }) =>
      api.put<CommunityChallengeDto>(`/api/v1/admin/challenges/${id}`, dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "social", "challenges"] });
      toast.success("Cập nhật thành công");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useDeleteChallenge() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => api.delete(`/api/v1/admin/challenges/${id}`),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "social", "challenges"] });
      toast.success("Đã xóa thử thách");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useUpdateChallengeStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, action }: { id: string; action: "activate" | "complete" }) =>
      api.patch<CommunityChallengeDto>(`/api/v1/admin/challenges/${id}/${action}`, {}),
    onSuccess: (_, { action }) => {
      qc.invalidateQueries({ queryKey: ["admin", "social", "challenges"] });
      toast.success(action === "activate" ? "Đã kích hoạt" : "Đã hoàn thành");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}
