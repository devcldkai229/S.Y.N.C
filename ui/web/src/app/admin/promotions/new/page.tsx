"use client";

import { useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import { PromotionForm } from "../_components/PromotionForm";
import { useCreatePromotionCampaign } from "@/hooks/admin/use-promotions";
import { PromotionFormValues } from "@/lib/validations/promotion";

export default function NewPromotionPage() {
  const router = useRouter();
  const createMutation = useCreatePromotionCampaign();

  const handleSubmit = (values: PromotionFormValues) => {
    createMutation.mutate(
      { ...values, startsAt: new Date(values.startsAt).toISOString(), endsAt: new Date(values.endsAt).toISOString() },
      { onSuccess: () => router.push("/admin/promotions") }
    );
  };

  return (
    <div className="max-w-2xl mx-auto space-y-4">
      <Button variant="ghost" size="sm" onClick={() => router.back()}>
        <ArrowLeft className="w-4 h-4 mr-2" /> Quay lại
      </Button>
      <Card>
        <CardHeader><CardTitle>Tạo chiến dịch khuyến mãi</CardTitle></CardHeader>
        <CardContent>
          <PromotionForm onSubmit={handleSubmit} loading={createMutation.isPending} submitLabel="Tạo chiến dịch" />
        </CardContent>
      </Card>
    </div>
  );
}
