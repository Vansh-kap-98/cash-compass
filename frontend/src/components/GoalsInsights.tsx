import { useMemo } from "react";
import { useFinance } from "@/contexts/FinanceContext";
import { useCurrency } from "@/contexts/CurrencyContext";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { FinancialCharts } from "@/components/FinancialCharts";

export const GoalsInsights = () => {
  const { transactions } = useFinance();
  const { formatFromUSD } = useCurrency();

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

  return (
    <div className="space-y-6">
      <Card className="rounded-2xl">
        <CardHeader>
          <CardTitle className="text-base">General Spending Trend</CardTitle>
          <p className="text-sm text-muted-foreground">See where your money goes and how your spending behavior evolves over time.</p>
        </CardHeader>
        <CardContent>
          <FinancialCharts />
        </CardContent>
      </Card>

      <Card className="rounded-2xl">
        <CardHeader>
          <CardTitle className="text-base">Personalized AI Suggestions</CardTitle>
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
