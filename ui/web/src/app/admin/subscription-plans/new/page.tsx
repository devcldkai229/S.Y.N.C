"use client";

import { useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import { PlanForm } from "../_components/PlanForm";
import { useCreateSubscriptionPlan } from "@/hooks/admin/use-subscription-plans";
import { SubscriptionPlanFormValues } from "@/lib/validations/subscription-plan";

export default function NewPlanPage() {
  const router = useRouter();
  const createMutation = useCreateSubscriptionPlan();

  const handleSubmit = (values: SubscriptionPlanFormValues) => {
    createMutation.mutate(values, {
      onSuccess: () => router.push("/admin/subscription-plans"),
    });
  };

  return (
    <div className="max-w-2xl mx-auto space-y-4">
      <Button variant="ghost" size="sm" onClick={() => router.back()}>
        <ArrowLeft className="w-4 h-4 mr-2" /> Back
      </Button>
      <Card>
        <CardHeader><CardTitle>New Subscription Plan</CardTitle></CardHeader>
        <CardContent>
          <PlanForm onSubmit={handleSubmit} loading={createMutation.isPending} submitLabel="Create Plan" />
        </CardContent>
      </Card>
    </div>
  );
}
