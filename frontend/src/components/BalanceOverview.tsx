import { motion } from "framer-motion";
import { TrendingUp, ArrowUpRight, ArrowDownRight } from "lucide-react";
import { useCurrency } from "@/contexts/CurrencyContext";
import { useFinance } from "@/contexts/FinanceContext";

export const BalanceOverview = () => {
  const { formatFromUSD } = useCurrency();
  const { manualBalance, transactions } = useFinance();

  const today = new Date().toISOString().slice(0, 10);

  const totalBalance = manualBalance ?? 0;
  const spending = transactions
    .filter((tx) => tx.type === "expense" && tx.date === today)
    .reduce((sum, tx) => sum + tx.amount, 0);
  const totalSpent = transactions
    .filter((tx) => tx.type === "expense")
    .reduce((sum, tx) => sum + tx.amount, 0);
  const availableBalance = Math.max(0, totalBalance - totalSpent);
  const monthlyChangeLabel = availableBalance >= spending ? "+expense-flow" : "expense-flow";

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, ease: [0.4, 0, 0.2, 1] }}
      whileHover={{ y: -4, transition: { duration: 0.2 } }}
      className="bg-card text-card-foreground rounded-lg p-6 shadow-card"
    >
      <div className="flex items-center justify-between mb-4">
        <h2 className="font-heading text-sm font-medium text-muted-foreground uppercase tracking-wider">
          Manual Snapshot
        </h2>
        <div className="flex items-center gap-1 text-xs font-mono text-primary">
          <TrendingUp className="w-3.5 h-3.5" />
          {monthlyChangeLabel}
        </div>
      </div>

      <p className="font-heading text-3xl font-bold tabular-nums mb-6">
        {formatFromUSD(availableBalance)}
      </p>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-1">
          <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
            <ArrowUpRight className="w-3 h-3 text-primary" />
            Total balance
          </div>
          <p className="text-lg font-semibold tabular-nums font-heading">
            {formatFromUSD(totalBalance)}
          </p>
        </div>
        <div className="space-y-1">
          <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
            <ArrowDownRight className="w-3 h-3 text-destructive" />
            Spent today
          </div>
          <p className="text-lg font-semibold tabular-nums font-heading">
            {formatFromUSD(spending)}
          </p>
        </div>
      </div>

      <div className="mt-4 rounded-2xl border border-border bg-secondary/30 p-3">
        <div className="flex items-center justify-between text-xs text-muted-foreground">
          <span>Total spent from entries</span>
          <span className="font-semibold text-foreground">{formatFromUSD(totalSpent)}</span>
        </div>
      </div>
    </motion.div>
  );
};
