"use client";

import { useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import { SubscriptionForm } from "../_components/SubscriptionForm";
import { useCreateUserSubscription } from "@/hooks/admin/use-user-subscriptions";
import { UserSubscriptionFormValues } from "@/lib/validations/user-subscription";

const orNull = (v?: string) => (v && v.length ? v : null);

export default function NewSubscriptionPage() {
  const router = useRouter();
  const createMutation = useCreateUserSubscription();

  const handleSubmit = (v: UserSubscriptionFormValues) => {
    createMutation.mutate(
      {
        userId:                 v.userId,
        subscriptionPlanId:     v.subscriptionPlanId,
        status:                 v.status as never,
        startedAt:              v.startedAt,
        expiredAt:              orNull(v.expiredAt),
        autoRenew:              v.autoRenew,
        nextBillingAt:          orNull(v.nextBillingAt),
        managedBy:              v.managedBy as never,
        externalSubscriptionId: orNull(v.externalSubscriptionId),
      },
      { onSuccess: () => router.push("/admin/subscriptions") },
    );
  };

  return (
    <div className="max-w-2xl mx-auto space-y-4">
      <Button variant="ghost" size="sm" onClick={() => router.back()}>
        <ArrowLeft className="w-4 h-4 mr-2" /> Quay lại
      </Button>
      <Card>
        <CardHeader><CardTitle>Tạo gói đăng ký</CardTitle></CardHeader>
        <CardContent>
          <SubscriptionForm mode="create" onSubmit={handleSubmit} loading={createMutation.isPending} submitLabel="Tạo gói đăng ký" />
        </CardContent>
      </Card>
    </div>
  );
}
