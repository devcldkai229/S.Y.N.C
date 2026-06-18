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
  participantCount: number;
  status:           string;
}

export interface CreateChallengeDto {
  title:            string;
  description:      string;
  startDate:        string;
  endDate:          string;
  goalType:         ChallengeGoalType;
  targetValue:      number;
  authorSnapshot:   AuthorSnapshotDto;
  feedAnnouncement?: string | null;
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

export function useActiveChallenges() {
  return useQuery({
    queryKey: ["admin", "social", "challenges"],
    queryFn:  () => api.get<CommunityChallengeDto[]>("/api/v1/social/challenges/active"),
  });
}

export function useCreateChallenge() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (dto: CreateChallengeDto) => api.post("/api/v1/social/challenges", dto),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "social", "challenges"] });
      toast.success("Đã tạo thử thách");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}
