import { useEffect, useMemo, useState } from "react";
import { useCurrency } from "@/contexts/CurrencyContext";
import { useFinance } from "@/contexts/FinanceContext";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

type WidgetType = "budget-health" | "top-categories" | "today-snapshot" | "goal-progress" | "media";
type WidgetSize = "sm" | "md" | "lg";

interface WorkspaceWidget {
  id: string;
  type: WidgetType;
  size: WidgetSize;
  title: string;
  mediaDataUrl?: string;
}

const STORAGE_KEY = "cash-compass-workspace-v2";

const typeLabel: Record<WidgetType, string> = {
  "today-snapshot": "Today Snapshot",
  "budget-health": "Budget Health",
  "top-categories": "Top Categories",
  "goal-progress": "Goal Progress",
  media: "Aesthetic Media",
};

const sizeClass: Record<WidgetSize, string> = {
  sm: "xl:col-span-3 md:col-span-6 col-span-12",
  md: "xl:col-span-6 col-span-12",
  lg: "col-span-12",
};

const sizeLabel: Record<WidgetSize, string> = {
  sm: "Small",
  md: "Medium",
  lg: "Large",
};

export const WorkspaceCanvas = () => {
  const { formatFromUSD } = useCurrency();
  const { transactions, budgets, goals, manualSpentToday } = useFinance();

  const [widgets, setWidgets] = useState<WorkspaceWidget[]>(() => {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    try {
      const parsed = JSON.parse(raw) as WorkspaceWidget[];
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  });
  const [draggingId, setDraggingId] = useState<string | null>(null);

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(widgets));
  }, [widgets]);

  const expenseByCategory = useMemo(() => {
    return transactions
      .filter((tx) => tx.type === "expense")
      .reduce<Record<string, number>>((acc, tx) => {
        acc[tx.category] = (acc[tx.category] ?? 0) + tx.amount;
        return acc;
      }, {});
  }, [transactions]);

  const addWidget = (type: WidgetType, size: WidgetSize = "md") => {
    setWidgets((prev) => [
      ...prev,
      {
        id: `widget-${Date.now()}-${Math.random().toString(36).slice(2, 7)}`,
        type,
        size,
        title: typeLabel[type],
      },
    ]);
  };

  const removeWidget = (id: string) => {
    setWidgets((prev) => prev.filter((item) => item.id !== id));
  };

  const updateWidget = (id: string, patch: Partial<WorkspaceWidget>) => {
    setWidgets((prev) => prev.map((item) => (item.id === id ? { ...item, ...patch } : item)));
  };

  const handleDrop = (targetId: string) => {
    if (!draggingId || draggingId === targetId) return;

    setWidgets((prev) => {
      const sourceIndex = prev.findIndex((item) => item.id === draggingId);
      const targetIndex = prev.findIndex((item) => item.id === targetId);
      if (sourceIndex < 0 || targetIndex < 0) return prev;

      const copy = [...prev];
      const [moved] = copy.splice(sourceIndex, 1);
      copy.splice(targetIndex, 0, moved);
      return copy;
    });

    setDraggingId(null);
  };

  const uploadMedia = (id: string, file: File | null) => {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      updateWidget(id, { mediaDataUrl: typeof reader.result === "string" ? reader.result : undefined });
    };
    reader.readAsDataURL(file);
  };

  const renderWidget = (widget: WorkspaceWidget) => {
    const dragProps = {
      draggable: true,
      onDragStart: () => setDraggingId(widget.id),
      onDragOver: (e: React.DragEvent<HTMLDivElement>) => e.preventDefault(),
      onDrop: () => handleDrop(widget.id),
    };

    if (widget.type === "today-snapshot") {
      return (
        <Card className="rounded-2xl" key={widget.id} {...dragProps}>
          <CardHeader>
            <CardTitle className="text-sm">Today Snapshot</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground">Spent today: {formatFromUSD(manualSpentToday ?? 0)}</p>
          </CardContent>
        </Card>
      );
    }

    if (widget.type === "budget-health") {
      return (
        <Card className="rounded-2xl" key={widget.id} {...dragProps}>
          <CardHeader>
            <CardTitle className="text-sm">Budget Health</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {budgets.slice(0, 3).map((budget) => {
              const spent = expenseByCategory[budget.name] ?? 0;
              const ratio = budget.monthlyLimit > 0 ? (spent / budget.monthlyLimit) * 100 : 0;
              return (
                <div key={budget.id} className="text-sm">
                  <div className="flex items-center justify-between">
                    <span>{budget.name}</span>
                    <Badge variant="secondary">{ratio.toFixed(0)}%</Badge>
                  </div>
                  <p className="text-xs text-muted-foreground">{formatFromUSD(spent)} of {formatFromUSD(budget.monthlyLimit)}</p>
                </div>
              );
            })}
          </CardContent>
        </Card>
      );
    }

    if (widget.type === "top-categories") {
      const sorted = Object.entries(expenseByCategory).sort((a, b) => b[1] - a[1]);
      return (
        <Card className="rounded-2xl" key={widget.id} {...dragProps}>
          <CardHeader>
            <CardTitle className="text-sm">Top Categories</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {sorted.slice(0, 3).map(([name, value]) => (
              <div key={name} className="flex items-center justify-between text-sm">
                <span>{name}</span>
                <span>{formatFromUSD(value)}</span>
              </div>
            ))}
          </CardContent>
        </Card>
      );
    }

    if (widget.type === "goal-progress") {
      return (
        <Card className="rounded-2xl" key={widget.id} {...dragProps}>
          <CardHeader>
            <CardTitle className="text-sm">Goal Progress</CardTitle>
          </CardHeader>
          <CardContent className="space-y-2">
            {goals.slice(0, 3).map((goal) => {
              const pct = Math.min(100, (goal.current / goal.target) * 100);
              return (
                <div key={goal.id} className="text-sm">
                  <div className="flex items-center justify-between">
                    <span>{goal.name}</span>
                    <span>{pct.toFixed(0)}%</span>
                  </div>
                  <div className="mt-1 h-2 rounded-full bg-secondary">
                    <div className="h-2 rounded-full bg-primary" style={{ width: `${pct}%` }} />
                  </div>
                </div>
              );
            })}
          </CardContent>
        </Card>
      );
    }

    return (
      <Card className="rounded-2xl" key={widget.id} {...dragProps}>
        <CardHeader>
          <CardTitle className="text-sm">Aesthetic Image / GIF</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          <Label htmlFor={`media-${widget.id}`}>Upload image or GIF</Label>
          <Input id={`media-${widget.id}`} type="file" accept="image/*,.gif" onChange={(e) => uploadMedia(widget.id, e.target.files?.[0] ?? null)} />
          {widget.mediaDataUrl ? (
            <div className="overflow-hidden rounded-xl border border-border">
              <img src={widget.mediaDataUrl} alt={widget.title || "Widget media"} className="h-52 w-full object-cover" />
            </div>
          ) : (
            <p className="text-sm text-muted-foreground">No media uploaded yet.</p>
          )}
        </CardContent>
      </Card>
    );
  };

  const available: WidgetType[] = ["today-snapshot", "budget-health", "top-categories", "goal-progress", "media"];

  return (
    <div className="space-y-5">
      <Card className="rounded-2xl">
        <CardHeader>
          <CardTitle className="text-base">Workspace Widgets</CardTitle>
          <p className="text-sm text-muted-foreground">Start with an empty canvas. Add widgets, duplicate them, resize them, and drag to build your own dashboard.</p>
        </CardHeader>
        <CardContent className="flex flex-wrap gap-2">
          {available.map((widget) => (
            <Button key={widget} type="button" variant="secondary" onClick={() => addWidget(widget, "md")}>
              Add {typeLabel[widget]}
            </Button>
          ))}
          <Button type="button" variant="outline" onClick={() => setWidgets([])}>
            Clear Workspace
          </Button>
        </CardContent>
      </Card>

      {widgets.length === 0 && (
        <Card className="rounded-2xl border-dashed">
          <CardContent className="py-10 text-center text-sm text-muted-foreground">
            Your workspace is empty. Add widgets above to start building your custom dashboard.
          </CardContent>
        </Card>
      )}

      <div className="grid grid-cols-12 gap-4">
        {widgets.map((widget) => (
          <div key={widget.id} className={`relative ${sizeClass[widget.size]}`}>
            <div className="absolute right-2 top-2 z-10 flex items-center gap-2">
              <Select value={widget.size} onValueChange={(value) => updateWidget(widget.id, { size: value as WidgetSize })}>
                <SelectTrigger className="h-8 w-[96px] bg-background/95">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {Object.entries(sizeLabel).map(([value, label]) => (
                    <SelectItem key={value} value={value}>{label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
              <Button type="button" size="sm" variant="ghost" onClick={() => removeWidget(widget.id)}>
                Remove
              </Button>
            </div>
            {renderWidget(widget)}
          </div>
        ))}
      </div>
    </div>
  );
};
