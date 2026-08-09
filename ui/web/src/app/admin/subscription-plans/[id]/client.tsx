"use client";

import { useParams, useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import { PlanForm } from "../_components/PlanForm";
import { useSubscriptionPlan, useUpdateSubscriptionPlan } from "@/hooks/admin/use-subscription-plans";
import { SubscriptionPlanFormValues } from "@/lib/validations/subscription-plan";
import { Skeleton } from "@/components/ui/skeleton";

export default function EditPlanPage() {
  const params   = useParams<{ id: string }>();
  const id       = params?.id ?? "";
  const router   = useRouter();
  const { data, isLoading } = useSubscriptionPlan(id);
  const updateMutation = useUpdateSubscriptionPlan();

  const handleSubmit = (values: SubscriptionPlanFormValues) => {
    updateMutation.mutate({ id, dto: values }, {
      onSuccess: () => router.push("/admin/subscription-plans"),
    });
  };

  if (isLoading) {
    return (
      <div className="max-w-2xl mx-auto space-y-4">
        <Skeleton className="h-8 w-24" />
        <Skeleton className="h-96 rounded-xl" />
      </div>
    );
  }

  if (!data) return <p className="text-muted-foreground">Không tìm thấy gói dịch vụ.</p>;

  return (
    <div className="max-w-2xl mx-auto space-y-4">
      <Button variant="ghost" size="sm" onClick={() => router.back()}>
        <ArrowLeft className="w-4 h-4 mr-2" /> Quay lại
      </Button>
      <Card>
        <CardHeader><CardTitle>Sửa gói dịch vụ — {data.name}</CardTitle></CardHeader>
        <CardContent>
          <PlanForm
            defaultValues={data}
            onSubmit={handleSubmit}
            loading={updateMutation.isPending}
            submitLabel="Cập nhật gói"
          />
        </CardContent>
      </Card>
    </div>
  );
}
