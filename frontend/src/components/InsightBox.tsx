import { motion } from "framer-motion";
import { useCurrency } from "@/contexts/CurrencyContext";
import { Lightbulb } from "lucide-react";
import { useFinance } from "@/contexts/FinanceContext";
import { useMemo } from "react";

export const InsightBox = () => {
  const { formatFromUSD } = useCurrency();
  const { transactions, budgets } = useFinance();

  const insights = useMemo(() => {
    const now = new Date();
    const expenseThisMonth = transactions.filter((tx) => {
      const date = new Date(tx.date);
      return tx.type === "expense" && date.getMonth() === now.getMonth() && date.getFullYear() === now.getFullYear();
    });

    const expenseByCategory = expenseThisMonth.reduce<Record<string, number>>((acc, tx) => {
      acc[tx.category] = (acc[tx.category] ?? 0) + tx.amount;
      return acc;
    }, {});

    const topExpense = Object.entries(expenseByCategory).sort((a, b) => b[1] - a[1])[0];

    const budgetAlerts = budgets
      .map((budget) => {
        const spent = expenseByCategory[budget.name] ?? 0;
        const ratio = budget.monthlyLimit > 0 ? spent / budget.monthlyLimit : 0;
        return { ...budget, spent, ratio };
      })
      .filter((item) => item.ratio >= 0.8)
      .sort((a, b) => b.ratio - a.ratio);

    const smartItems = [] as Array<{ id: string; title: string; description: string; savings: number; icon: string }>;

    if (topExpense) {
      const [category, amount] = topExpense;
      smartItems.push({
        id: "top-expense",
        title: `${category} Watchlist`,
        description: `Your largest expense category this month is ${category} at ${formatFromUSD(amount)}. Trimming 10% would noticeably improve your cash runway.`,
        savings: amount * 0.1,
        icon: "📊",
      });
    }

    if (budgetAlerts[0]) {
      const alert = budgetAlerts[0];
      smartItems.push({
        id: "budget-alert",
        title: `${alert.name} Budget Alert`,
        description: `${alert.name} is at ${(alert.ratio * 100).toFixed(0)}% of your monthly budget (${formatFromUSD(alert.spent)} of ${formatFromUSD(alert.monthlyLimit)}).`,
        savings: Math.max(0, alert.spent - alert.monthlyLimit),
        icon: "🚨",
      });
    }

    const subscriptions = expenseThisMonth.filter((tx) => /netflix|spotify|subscription|prime|youtube/i.test(tx.name));
    if (subscriptions.length > 0) {
      const total = subscriptions.reduce((sum, tx) => sum + tx.amount, 0);
      smartItems.push({
        id: "subscription-audit",
        title: "Subscription Audit",
        description: `You logged ${subscriptions.length} subscription-style payments this month. Rotating one plan could reduce recurring spend.`,
        savings: total * 0.25,
        icon: "📺",
      });
    }

    if (smartItems.length === 0) {
      smartItems.push({
        id: "starter",
        title: "Track For 7 Days",
        description: "Add a few daily transactions and budgets. Once enough data is available, this panel will generate tailored savings ideas.",
        savings: 0,
        icon: "🧭",
      });
    }

    return smartItems.slice(0, 3);
  }, [transactions, budgets, formatFromUSD]);

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: 0.15, ease: [0.4, 0, 0.2, 1] }}
      whileHover={{ y: -4, transition: { duration: 0.2 } }}
      className="bg-card text-card-foreground rounded-lg p-6 shadow-card"
    >
      <div className="flex items-center gap-2 mb-5">
        <Lightbulb className="w-4 h-4 text-primary" />
        <h2 className="font-heading text-sm font-medium text-muted-foreground uppercase tracking-wider">
          Smart Suggestions
        </h2>
      </div>

      <div className="space-y-4">
        {insights.map((insight, i) => (
          <motion.div
            key={insight.id}
            initial={{ opacity: 0, x: -8 }}
            animate={{ opacity: 1, x: 0 }}
            transition={{ delay: 0.3 + i * 0.12, duration: 0.5 }}
            className="flex gap-3"
          >
            <span className="text-xl mt-0.5 shrink-0">{insight.icon}</span>
            <div className="space-y-1">
              <p className="text-sm font-semibold font-heading">{insight.title}</p>
              <p className="text-xs text-muted-foreground leading-relaxed">
                {insight.description}
              </p>
              <p className="text-xs font-medium text-primary tabular-nums">
                Save ~{formatFromUSD(insight.savings, { maximumFractionDigits: 0 })}/mo
              </p>
            </div>
          </motion.div>
        ))}
      </div>
    </motion.div>
  );
};
