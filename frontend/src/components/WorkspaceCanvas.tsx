import { useMemo, useState } from "react";
import { useCurrency } from "@/contexts/CurrencyContext";
import { useFinance } from "@/contexts/FinanceContext";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

type WidgetKey = "budget-health" | "top-categories" | "today-snapshot" | "goal-progress";

const defaultWidgets: WidgetKey[] = ["today-snapshot", "budget-health", "top-categories", "goal-progress"];

export const WorkspaceCanvas = () => {
  const { formatFromUSD } = useCurrency();
  const { transactions, budgets, goals, manualSpentToday } = useFinance();

  const [widgets, setWidgets] = useState<WidgetKey[]>(defaultWidgets);
  const [dragging, setDragging] = useState<WidgetKey | null>(null);

  const expenseByCategory = useMemo(() => {
    return transactions
      .filter((tx) => tx.type === "expense")
      .reduce<Record<string, number>>((acc, tx) => {
        acc[tx.category] = (acc[tx.category] ?? 0) + tx.amount;
        return acc;
      }, {});
  }, [transactions]);

  const addWidget = (widget: WidgetKey) => {
    setWidgets((prev) => (prev.includes(widget) ? prev : [...prev, widget]));
  };

  const removeWidget = (widget: WidgetKey) => {
    setWidgets((prev) => prev.filter((item) => item !== widget));
  };

  const handleDrop = (target: WidgetKey) => {
    if (!dragging || dragging === target) return;

    setWidgets((prev) => {
      const sourceIndex = prev.indexOf(dragging);
      const targetIndex = prev.indexOf(target);
      if (sourceIndex < 0 || targetIndex < 0) return prev;

      const copy = [...prev];
      copy.splice(sourceIndex, 1);
      copy.splice(targetIndex, 0, dragging);
      return copy;
    });

    setDragging(null);
  };

  const renderWidget = (widget: WidgetKey) => {
    if (widget === "today-snapshot") {
      return (
        <Card className="rounded-2xl" key={widget} draggable onDragStart={() => setDragging(widget)} onDragOver={(e) => e.preventDefault()} onDrop={() => handleDrop(widget)}>
          <CardHeader>
            <CardTitle className="text-sm">Today Snapshot</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-sm text-muted-foreground">Spent today: {formatFromUSD(manualSpentToday ?? 0)}</p>
          </CardContent>
        </Card>
      );
    }

    if (widget === "budget-health") {
      return (
        <Card className="rounded-2xl" key={widget} draggable onDragStart={() => setDragging(widget)} onDragOver={(e) => e.preventDefault()} onDrop={() => handleDrop(widget)}>
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

    if (widget === "top-categories") {
      const sorted = Object.entries(expenseByCategory).sort((a, b) => b[1] - a[1]);
      return (
        <Card className="rounded-2xl" key={widget} draggable onDragStart={() => setDragging(widget)} onDragOver={(e) => e.preventDefault()} onDrop={() => handleDrop(widget)}>
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

    return (
      <Card className="rounded-2xl" key={widget} draggable onDragStart={() => setDragging(widget)} onDragOver={(e) => e.preventDefault()} onDrop={() => handleDrop(widget)}>
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
  };

  const available: WidgetKey[] = ["today-snapshot", "budget-health", "top-categories", "goal-progress"];

  return (
    <div className="space-y-5">
      <Card className="rounded-2xl">
        <CardHeader>
          <CardTitle className="text-base">Workspace Widgets</CardTitle>
          <p className="text-sm text-muted-foreground">Drag and drop widgets to build your own spending analysis workspace.</p>
        </CardHeader>
        <CardContent className="flex flex-wrap gap-2">
          {available.map((widget) => (
            <Button key={widget} type="button" variant="secondary" onClick={() => addWidget(widget)}>
              Add {widget.replace("-", " ")}
            </Button>
          ))}
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        {widgets.map((widget) => (
          <div key={widget} className="relative">
            <Button
              type="button"
              size="sm"
              variant="ghost"
              className="absolute right-2 top-2 z-10"
              onClick={() => removeWidget(widget)}
            >
              Remove
            </Button>
            {renderWidget(widget)}
          </div>
        ))}
      </div>
    </div>
  );
};
