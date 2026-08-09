"use client";

import { useParams, useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import { SubscriptionForm } from "../_components/SubscriptionForm";
import { useUserSubscription, useUpdateUserSubscription } from "@/hooks/admin/use-user-subscriptions";
import { UserSubscriptionFormValues } from "@/lib/validations/user-subscription";
import { Skeleton } from "@/components/ui/skeleton";

const orNull = (v?: string) => (v && v.length ? v : null);

export default function EditSubscriptionPage() {
  const params = useParams<{ id: string }>();
  const id     = params?.id ?? "";
  const router = useRouter();
  const { data, isLoading } = useUserSubscription(id);
  const updateMutation = useUpdateUserSubscription();

  const handleSubmit = (v: UserSubscriptionFormValues) => {
    updateMutation.mutate(
      {
        id,
        dto: {
          status:                 v.status as never,
          expiredAt:              orNull(v.expiredAt),
          autoRenew:              v.autoRenew,
          nextBillingAt:          orNull(v.nextBillingAt),
          cancellationReason:     orNull(v.cancellationReason),
          managedBy:              v.managedBy as never,
          externalSubscriptionId: orNull(v.externalSubscriptionId),
        },
      },
      { onSuccess: () => router.push("/admin/subscriptions") },
    );
  };

  if (isLoading) {
    return (
      <div className="max-w-2xl mx-auto space-y-4">
        <Skeleton className="h-8 w-24" />
        <Skeleton className="h-96 rounded-xl" />
      </div>
    );
  }

  if (!data) return <p className="text-muted-foreground">Không tìm thấy gói đăng ký.</p>;

  return (
    <div className="max-w-2xl mx-auto space-y-4">
      <Button variant="ghost" size="sm" onClick={() => router.back()}>
        <ArrowLeft className="w-4 h-4 mr-2" /> Quay lại
      </Button>
      <Card>
        <CardHeader><CardTitle>Sửa gói đăng ký — {data.subscriptionPlanName}</CardTitle></CardHeader>
        <CardContent>
          <SubscriptionForm
            mode="edit"
            defaultValues={{
              userId:                 data.userId,
              subscriptionPlanId:     data.subscriptionPlanId,
              status:                 data.status,
              startedAt:              data.startedAt,
              expiredAt:              data.expiredAt ?? undefined,
              autoRenew:              data.autoRenew,
              nextBillingAt:          data.nextBillingAt ?? undefined,
              cancellationReason:     data.cancellationReason ?? undefined,
              managedBy:              data.managedBy,
              externalSubscriptionId: data.externalSubscriptionId ?? undefined,
            }}
            onSubmit={handleSubmit}
            loading={updateMutation.isPending}
            submitLabel="Cập nhật gói đăng ký"
          />
        </CardContent>
      </Card>
    </div>
  );
}
