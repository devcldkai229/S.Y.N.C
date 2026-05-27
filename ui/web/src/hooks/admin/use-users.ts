import { useQuery } from "@tanstack/react-query";

export interface AdminUserListItem {
  id:               string;
  fullName:         string;
  email:            string;
  role:             string;
  status:           string;
  subscriptionTier: string;
  lastActive:       string;
  createdAt:        string;
  avatarUrl?:       string;
}

const MOCK_USERS: AdminUserListItem[] = [
  { id: "1", fullName: "Nguyễn Văn An", email: "an.nguyen@email.com", role: "Member", status: "active", subscriptionTier: "Pro", lastActive: "2024-01-15", createdAt: "2024-01-01", avatarUrl: undefined },
  { id: "2", fullName: "Trần Thị Bình", email: "binh.tran@email.com", role: "Member", status: "active", subscriptionTier: "Free", lastActive: "2024-01-14", createdAt: "2024-01-03", avatarUrl: undefined },
  { id: "3", fullName: "Lê Minh Châu", email: "chau.le@email.com", role: "Staff", status: "active", subscriptionTier: "Premium", lastActive: "2024-01-15", createdAt: "2023-12-20", avatarUrl: undefined },
  { id: "4", fullName: "Phạm Quốc Dũng", email: "dung.pham@email.com", role: "Member", status: "banned", subscriptionTier: "Free", lastActive: "2023-12-30", createdAt: "2023-11-15", avatarUrl: undefined },
  { id: "5", fullName: "Hoàng Thị Em", email: "em.hoang@email.com", role: "Member", status: "active", subscriptionTier: "Basic", lastActive: "2024-01-13", createdAt: "2024-01-05", avatarUrl: undefined },
  { id: "6", fullName: "Vũ Đức Phúc", email: "phuc.vu@email.com", role: "Admin", status: "active", subscriptionTier: "Premium", lastActive: "2024-01-15", createdAt: "2023-06-01", avatarUrl: undefined },
  { id: "7", fullName: "Đặng Thị Giang", email: "giang.dang@email.com", role: "Member", status: "suspended", subscriptionTier: "Pro", lastActive: "2024-01-10", createdAt: "2023-10-20", avatarUrl: undefined },
];

export function useUsers() {
  return useQuery({
    queryKey: ["admin", "users"],
    queryFn:  () => Promise.resolve(MOCK_USERS),
    staleTime: Infinity,
  });
}

export function useUser(id: string) {
  return useQuery({
    queryKey: ["admin", "users", id],
    queryFn:  () => Promise.resolve(MOCK_USERS.find((u) => u.id === id) ?? null),
    enabled:  !!id,
  });
}
