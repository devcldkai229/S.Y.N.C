"use client";

import { useState } from "react";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Loader2, Send } from "lucide-react";
import {
  useSendNotification,
  useSendTemplatedNotification,
  NOTIFICATION_TYPES,
  NOTIFICATION_PRIORITIES,
  type NotificationType,
  type NotificationPriority,
} from "@/hooks/admin/use-notifications";
import { NOTIFICATION_CHANNELS, type NotificationChannel, useNotificationTemplates } from "@/hooks/admin/use-notification-templates";

const orNull = (v: string) => (v.length ? v : null);

function RawForm() {
  const send = useSendNotification();
  const [f, setF] = useState({
    userId: "", type: "SystemAlert" as NotificationType, channel: "Push" as NotificationChannel,
    priority: "Normal" as NotificationPriority, title: "", body: "", imageUrl: "", deepLink: "", scheduledFor: "",
  });
  const set = <K extends keyof typeof f>(k: K, v: (typeof f)[K]) => setF((p) => ({ ...p, [k]: v }));

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    send.mutate({
      userId: f.userId, type: f.type, channel: f.channel, priority: f.priority,
      title: f.title, body: f.body, imageUrl: orNull(f.imageUrl), deepLink: orNull(f.deepLink),
      scheduledFor: orNull(f.scheduledFor),
    });
  };

  return (
    <form onSubmit={submit} className="space-y-4">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="space-y-1 md:col-span-2">
          <Label>Mã người nhận *</Label>
          <Input value={f.userId} onChange={(e) => set("userId", e.target.value)} placeholder="GUID người nhận" required />
        </div>
        <div className="space-y-1">
          <Label>Loại</Label>
          <Select value={f.type} onValueChange={(v) => set("type", v as NotificationType)}>
            <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
            <SelectContent>{NOTIFICATION_TYPES.map((t) => <SelectItem key={t} value={t}>{t}</SelectItem>)}</SelectContent>
          </Select>
        </div>
        <div className="space-y-1">
          <Label>Kênh</Label>
          <Select value={f.channel} onValueChange={(v) => set("channel", v as NotificationChannel)}>
            <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
            <SelectContent>{NOTIFICATION_CHANNELS.map((c) => <SelectItem key={c} value={c}>{c}</SelectItem>)}</SelectContent>
          </Select>
        </div>
        <div className="space-y-1">
          <Label>Độ ưu tiên</Label>
          <Select value={f.priority} onValueChange={(v) => set("priority", v as NotificationPriority)}>
            <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
            <SelectContent>{NOTIFICATION_PRIORITIES.map((p) => <SelectItem key={p} value={p}>{p}</SelectItem>)}</SelectContent>
          </Select>
        </div>
        <div className="space-y-1">
          <Label>Hẹn giờ gửi (tùy chọn)</Label>
          <Input type="datetime-local" value={f.scheduledFor} onChange={(e) => set("scheduledFor", e.target.value)} />
        </div>
        <div className="space-y-1 md:col-span-2">
          <Label>Tiêu đề *</Label>
          <Input value={f.title} onChange={(e) => set("title", e.target.value)} required />
        </div>
        <div className="space-y-1 md:col-span-2">
          <Label>Nội dung *</Label>
          <Textarea value={f.body} onChange={(e) => set("body", e.target.value)} rows={4} required />
        </div>
        <div className="space-y-1">
          <Label>URL ảnh</Label>
          <Input value={f.imageUrl} onChange={(e) => set("imageUrl", e.target.value)} />
        </div>
        <div className="space-y-1">
          <Label>Deep Link</Label>
          <Input value={f.deepLink} onChange={(e) => set("deepLink", e.target.value)} placeholder="sync://..." />
        </div>
      </div>
      <div className="flex justify-end border-t border-border pt-3">
        <Button type="submit" disabled={send.isPending}>
          {send.isPending ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : <Send className="w-4 h-4 mr-2" />}
          Gửi thông báo
        </Button>
      </div>
    </form>
  );
}

function TemplatedForm() {
  const send = useSendTemplatedNotification();
  const { data: templates } = useNotificationTemplates();
  const [f, setF] = useState({
    userId: "", templateCode: "", priority: "Normal" as NotificationPriority, deepLink: "", scheduledFor: "", variablesJson: "{}",
  });
  const set = <K extends keyof typeof f>(k: K, v: (typeof f)[K]) => setF((p) => ({ ...p, [k]: v }));

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    let variables: Record<string, string> = {};
    try { variables = JSON.parse(f.variablesJson || "{}"); }
    catch { return; }
    send.mutate({
      userId: f.userId, templateCode: f.templateCode, variables, priority: f.priority,
      deepLink: orNull(f.deepLink), scheduledFor: orNull(f.scheduledFor),
    });
  };

  return (
    <form onSubmit={submit} className="space-y-4">
      <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
        <div className="space-y-1">
          <Label>Mã người nhận *</Label>
          <Input value={f.userId} onChange={(e) => set("userId", e.target.value)} placeholder="GUID người nhận" required />
        </div>
        <div className="space-y-1">
          <Label>Mẫu *</Label>
          <Select value={f.templateCode} onValueChange={(v) => set("templateCode", v ?? "")}>
            <SelectTrigger className="w-full"><SelectValue placeholder="Chọn template..." /></SelectTrigger>
            <SelectContent>
              {(templates ?? []).map((t) => <SelectItem key={t.id} value={t.templateCode}>{t.name} ({t.templateCode})</SelectItem>)}
            </SelectContent>
          </Select>
        </div>
        <div className="space-y-1">
          <Label>Độ ưu tiên</Label>
          <Select value={f.priority} onValueChange={(v) => set("priority", v as NotificationPriority)}>
            <SelectTrigger className="w-full"><SelectValue /></SelectTrigger>
            <SelectContent>{NOTIFICATION_PRIORITIES.map((p) => <SelectItem key={p} value={p}>{p}</SelectItem>)}</SelectContent>
          </Select>
        </div>
        <div className="space-y-1">
          <Label>Hẹn giờ gửi (tùy chọn)</Label>
          <Input type="datetime-local" value={f.scheduledFor} onChange={(e) => set("scheduledFor", e.target.value)} />
        </div>
        <div className="space-y-1 md:col-span-2">
          <Label>Biến (JSON)</Label>
          <Textarea value={f.variablesJson} onChange={(e) => set("variablesJson", e.target.value)} rows={4} className="font-mono text-xs" placeholder='{"name":"An","workoutName":"Push day"}' />
        </div>
        <div className="space-y-1 md:col-span-2">
          <Label>Deep Link</Label>
          <Input value={f.deepLink} onChange={(e) => set("deepLink", e.target.value)} placeholder="sync://..." />
        </div>
      </div>
      <div className="flex justify-end border-t border-border pt-3">
        <Button type="submit" disabled={send.isPending}>
          {send.isPending ? <Loader2 className="w-4 h-4 mr-2 animate-spin" /> : <Send className="w-4 h-4 mr-2" />}
          Gửi theo mẫu
        </Button>
      </div>
    </form>
  );
}

export default function SendNotificationPage() {
  return (
    <div className="max-w-2xl mx-auto">
      <Card>
        <CardHeader><CardTitle className="text-sm font-semibold">Gửi thông báo</CardTitle></CardHeader>
        <CardContent>
          <Tabs defaultValue="raw">
            <TabsList>
              <TabsTrigger value="raw">Tùy chỉnh</TabsTrigger>
              <TabsTrigger value="templated">Theo mẫu</TabsTrigger>
            </TabsList>
            <TabsContent value="raw" className="mt-4"><RawForm /></TabsContent>
            <TabsContent value="templated" className="mt-4"><TemplatedForm /></TabsContent>
          </Tabs>
        </CardContent>
      </Card>
    </div>
  );
}
