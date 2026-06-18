import { useMutation, useQuery, useQueryClient } from "@tanstack/react-query";
import { api } from "@/services/api";
import { toast } from "sonner";

export type UserRole = "User" | "Partner" | "SystemAdmin";
export type UserStatus = "Onboarding" | "Active" | "Suspended" | "PendingVerification" | "Deleted";

export const USER_ROLES: UserRole[] = ["User", "Partner", "SystemAdmin"];
export const USER_STATUSES: UserStatus[] = ["Onboarding", "Active", "Suspended", "PendingVerification", "Deleted"];

export interface AdminUserListItem {
  id:               string;
  email:            string;
  fullName:         string;
  avatarUrl?:       string | null;
  role:             UserRole;
  status:           UserStatus;
  subscriptionTier: string;
  emailVerified:    boolean;
  lastActiveAt?:    string | null;
  lastLoginAt?:     string | null;
  createdAt:        string;
}

interface UserListParams {
  search?: string;
  role?:   UserRole;
  status?: UserStatus;
}

export function useUsers(params: UserListParams = {}) {
  const qs = new URLSearchParams();
  if (params.search) qs.set("search", params.search);
  if (params.role)   qs.set("role", params.role);
  if (params.status) qs.set("status", params.status);

  return useQuery({
    queryKey: ["admin", "users", params],
    queryFn:  () => api.get<AdminUserListItem[]>(`/api/v1/iam/users?${qs}`),
  });
}

export function useUser(id: string) {
  return useQuery({
    queryKey: ["admin", "users", id],
    queryFn:  () => api.get<AdminUserListItem>(`/api/v1/iam/users/${id}`),
    enabled:  !!id,
  });
}

export function useUpdateUserStatus() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, status }: { id: string; status: UserStatus }) =>
      api.put<AdminUserListItem>(`/api/v1/iam/users/${id}/status`, { status }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "users"] });
      toast.success("Đã cập nhật trạng thái người dùng");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}

export function useUpdateUserRole() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, role }: { id: string; role: UserRole }) =>
      api.put<AdminUserListItem>(`/api/v1/iam/users/${id}/role`, { role }),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ["admin", "users"] });
      toast.success("Đã cập nhật vai trò người dùng");
    },
    onError: (e: Error) => toast.error(e.message),
  });
}
