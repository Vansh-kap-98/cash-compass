import { motion } from "framer-motion";
import { TrendingUp, ArrowUpRight, ArrowDownRight } from "lucide-react";
import { useCurrency } from "@/contexts/CurrencyContext";
import { useFinance } from "@/contexts/FinanceContext";

export const BalanceOverview = () => {
  const { formatFromUSD } = useCurrency();
  const { manualBalance, manualIncomeToDate, manualSpentToday } = useFinance();

  const totalBalance = manualBalance ?? 0;
  const income = manualIncomeToDate ?? 0;
  const spending = manualSpentToday ?? 0;
  const bufferAfterSpend = Math.max(0, totalBalance - spending);
  const monthlyChangeLabel = totalBalance >= spending ? "+manual" : "manual";

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
        {formatFromUSD(totalBalance)}
      </p>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-1">
          <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
            <ArrowUpRight className="w-3 h-3 text-primary" />
            Income to date
          </div>
          <p className="text-lg font-semibold tabular-nums font-heading">
            {formatFromUSD(income)}
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
          <span>Balance after today</span>
          <span className="font-semibold text-foreground">{formatFromUSD(bufferAfterSpend)}</span>
        </div>
      </div>
    </motion.div>
  );
};
