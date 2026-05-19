import { useQuery, useMutation, useQueryClient } from "@tanstack/react-query";
import { api } from "@/services/api";

interface ExampleItem {
  id: string;
  name: string;
}

const QUERY_KEY = ["examples"] as const;

export function useExamples() {
  return useQuery({
    queryKey: QUERY_KEY,
    queryFn: () => api.get<ExampleItem[]>("/api/examples"),
  });
}

export function useCreateExample() {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: (data: Omit<ExampleItem, "id">) =>
      api.post<ExampleItem>("/api/examples", data),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: QUERY_KEY });
    },
  });
}
