import { useMemo, useState } from "react";
import { useFinance } from "@/contexts/FinanceContext";
import { goalPercent } from "@/lib/goals";
import { useCurrency } from "@/contexts/CurrencyContext";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { FinancialCharts } from "@/components/FinancialCharts";
import { Trash2 } from "lucide-react";

const BUDGET_PLANS_KEY = "cash-compass-budget-plans-v1";

interface FinalizedBudgetPlan {
  id: string;
  title: string;
  planType: string;
  dateFrom: string;
  dateTo?: string;
  people: number;
  items: Array<{ id: string; name: string; estimate: number }>;
  total: number;
  perPerson: number;
  createdAt: string;
  settledWith?: string[];
}

export const GoalsInsights = () => {
  const { transactions, goals, contributeToGoal } = useFinance();
  const { formatFromUSD, convertFromUSD } = useCurrency();

  const [budgetPlans, setBudgetPlans] = useState<FinalizedBudgetPlan[]>(() => {
    const raw = localStorage.getItem(BUDGET_PLANS_KEY);
    if (!raw) return [];
    try {
      const parsed = JSON.parse(raw) as FinalizedBudgetPlan[];
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  });

  const removeBudgetPlan = (planId: string) => {
    const next = budgetPlans.filter((p) => p.id !== planId);
    setBudgetPlans(next);
    localStorage.setItem(BUDGET_PLANS_KEY, JSON.stringify(next));
  };

  const summary = useMemo(() => {
    const expenseByCategory = transactions
      .filter((tx) => tx.type === "expense")
      .reduce<Record<string, number>>((acc, tx) => {
        acc[tx.category] = (acc[tx.category] ?? 0) + tx.amount;
        return acc;
      }, {});

    const sorted = Object.entries(expenseByCategory).sort((a, b) => b[1] - a[1]);
    const biggest = sorted[0];
    const second = sorted[1];
    const totalExpense = sorted.reduce((sum, [, amount]) => sum + amount, 0);

    return { biggest, second, totalExpense };
  }, [transactions]);

  const personalizedTips = useMemo(() => {
    const tips: string[] = [];

    if (summary.biggest) {
      tips.push(`Your biggest category is ${summary.biggest[0]} at ${formatFromUSD(summary.biggest[1])}. Set a weekly cap and review it every Sunday.`);
    }

    if (summary.second && summary.biggest) {
      const combined = summary.biggest[1] + summary.second[1];
      const ratio = summary.totalExpense > 0 ? (combined / summary.totalExpense) * 100 : 0;
      tips.push(`Top two categories consume ${ratio.toFixed(0)}% of all spending. Focus habit changes there first for fastest impact.`);
    }

    tips.push("Create two spending modes: Essentials Day and Flex Day. Alternate to lower fatigue and improve consistency.");
    tips.push("When a category exceeds plan, lower the next two days by 15% instead of attempting one aggressive cut.");

    return tips.slice(0, 4);
  }, [formatFromUSD, summary.biggest, summary.second, summary.totalExpense]);

  // Contribution amount in display currency — convert 100 display units to USD
  const contributionUSD = useMemo(() => {
    // We want a clean "+100" in display currency, so we convert 100 display-currency to USD
    // But contributeToGoal takes USD, so we need to know how much USD 100 display-units is
    return 100 / (convertFromUSD(1) || 1);
  }, [convertFromUSD]);

  const planTypeLabels: Record<string, string> = {
    trip: "Trip",
    outing: "Outing",
    event: "Event",
  };

  return (
    <div className="space-y-6">
      {/* ── Savings Goals with Progress ── */}
      {goals.length > 0 && (
        <Card className="rounded-2xl">
          <CardHeader>
            <CardTitle className="text-base">Savings Goals</CardTitle>
            <p className="text-sm text-muted-foreground">Track progress toward your savings targets and contribute quickly.</p>
          </CardHeader>
          <CardContent className="space-y-5">
            {goals.map((goal) => {
              const pct = goalPercent(goal);
              const isComplete = goal.current >= goal.target;
              return (
                <div key={goal.id} className="space-y-2">
                  <div className="flex items-center justify-between">
                    <div className="flex items-center gap-2">
                      <span className="text-lg">{goal.icon}</span>
                      <span className="text-sm font-medium">{goal.name}</span>
                    </div>
                    <span className="text-xs tabular-nums text-muted-foreground">
                      {formatFromUSD(goal.current, { maximumFractionDigits: 0 })} / {formatFromUSD(goal.target, { maximumFractionDigits: 0 })}
                    </span>
                  </div>
                  {/* Progress ring (simplified as a bar — matching SavingsProgress component) */}
                  <div className="relative h-2 rounded-full bg-secondary overflow-hidden">
                    <div
                      className="absolute inset-y-0 left-0 rounded-full bg-primary transition-all duration-700"
                      style={{ width: `${pct}%` }}
                    />
                  </div>
                  <div className="flex items-center justify-between">
                    <p className="text-xs tabular-nums text-muted-foreground">
                      {pct}%{isComplete && " ✓ Complete"}
                    </p>
                    {!isComplete && (
                      <Button
                        variant="outline"
                        size="sm"
                        className="h-7 px-2 text-[11px]"
                        onClick={() => contributeToGoal(goal.id, contributionUSD)}
                      >
                        +100
                      </Button>
                    )}
                  </div>
                </div>
              );
            })}
          </CardContent>
        </Card>
      )}

      {/* ── Budget Receipts (Finalized Plans) ── */}
      {budgetPlans.length > 0 && (
        <Card className="rounded-2xl">
          <CardHeader>
            <CardTitle className="text-base">Budget Receipts</CardTitle>
            <p className="text-sm text-muted-foreground">Finalized trip, outing, and event budgets with per-person splits.</p>
          </CardHeader>
          <CardContent className="space-y-3">
            {budgetPlans.map((plan) => (
              <div key={plan.id} className="rounded-xl border border-border p-3 space-y-2">
                <div className="flex items-center justify-between">
                  <div className="flex items-center gap-2">
                    <span className="text-sm font-medium">{plan.title}</span>
                    <Badge variant="secondary" className="text-[10px]">
                      {planTypeLabels[plan.planType] ?? plan.planType}
                    </Badge>
                  </div>
                  <Button
                    variant="ghost"
                    size="sm"
                    className="h-7 w-7 p-0 text-muted-foreground hover:text-destructive"
                    onClick={() => removeBudgetPlan(plan.id)}
                  >
                    <Trash2 className="h-3.5 w-3.5" />
                  </Button>
                </div>
                <p className="text-xs text-muted-foreground">
                  {plan.dateFrom}{plan.dateTo ? ` → ${plan.dateTo}` : ""}
                </p>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-muted-foreground">Total</span>
                  <span className="font-semibold">{formatFromUSD(plan.total)}</span>
                </div>
                {plan.people > 1 && (
                  <div className="flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">Per person ({plan.people})</span>
                    <span className="font-medium">{formatFromUSD(plan.perPerson)}</span>
                  </div>
                )}
              </div>
            ))}
          </CardContent>
        </Card>
      )}

      {/* ── Financial Charts (Donut + Monthly Bars) ── */}
      <Card className="rounded-2xl">
        <CardHeader>
          <CardTitle className="text-base">General Spending Trend</CardTitle>
          <p className="text-sm text-muted-foreground">See where your money goes and how your spending behavior evolves over time.</p>
        </CardHeader>
        <CardContent>
          <FinancialCharts />
        </CardContent>
      </Card>

      {/* ── Personalized Tips ── */}
      <Card className="rounded-2xl">
        <CardHeader>
          <CardTitle className="text-base">Goals Guidance</CardTitle>
          <p className="text-sm text-muted-foreground">Habit-level suggestions based on your overall spending profile.</p>
        </CardHeader>
        <CardContent className="space-y-3">
          {personalizedTips.map((tip) => (
            <div key={tip} className="rounded-xl border border-border p-3 text-sm text-muted-foreground">
              {tip}
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  );
};
