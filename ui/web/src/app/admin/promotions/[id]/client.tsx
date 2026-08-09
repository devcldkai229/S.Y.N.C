"use client";

import { useParams, useRouter } from "next/navigation";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { ArrowLeft } from "lucide-react";
import { PromotionForm } from "../_components/PromotionForm";
import { usePromotionCampaign, useUpdatePromotionCampaign } from "@/hooks/admin/use-promotions";
import { PromotionFormValues } from "@/lib/validations/promotion";
import { Skeleton } from "@/components/ui/skeleton";

export default function EditPromotionPage() {
  const params   = useParams<{ id: string }>();
  const id       = params?.id ?? "";
  const router   = useRouter();
  const { data, isLoading } = usePromotionCampaign(id);
  const updateMutation = useUpdatePromotionCampaign();

  const handleSubmit = (values: PromotionFormValues) => {
    updateMutation.mutate(
      { id, dto: { ...values, startsAt: new Date(values.startsAt).toISOString(), endsAt: new Date(values.endsAt).toISOString() } },
      { onSuccess: () => router.push("/admin/promotions") }
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

  if (!data) return <p className="text-muted-foreground">Không tìm thấy chiến dịch.</p>;

  return (
    <div className="max-w-2xl mx-auto space-y-4">
      <Button variant="ghost" size="sm" onClick={() => router.back()}>
        <ArrowLeft className="w-4 h-4 mr-2" /> Quay lại
      </Button>
      <Card>
        <CardHeader><CardTitle>Sửa chiến dịch — {data.name}</CardTitle></CardHeader>
        <CardContent>
          <PromotionForm
            defaultValues={data}
            onSubmit={handleSubmit}
            loading={updateMutation.isPending}
            submitLabel="Cập nhật chiến dịch"
          />
        </CardContent>
      </Card>
    </div>
  );
}
