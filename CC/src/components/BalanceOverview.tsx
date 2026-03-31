import { motion } from "framer-motion";
import { balanceData } from "@/data/mockData";
import { TrendingUp, ArrowUpRight, ArrowDownRight } from "lucide-react";
import { useCurrency } from "@/contexts/CurrencyContext";

export const BalanceOverview = () => {
  const { formatFromUSD } = useCurrency();

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
          Total Balance
        </h2>
        <div className="flex items-center gap-1 text-xs font-mono text-primary">
          <TrendingUp className="w-3.5 h-3.5" />
          +{balanceData.monthlyChange}%
        </div>
      </div>

      <p className="font-heading text-3xl font-bold tabular-nums mb-6">
        {formatFromUSD(balanceData.totalBalance)}
      </p>

      <div className="grid grid-cols-2 gap-4">
        <div className="space-y-1">
          <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
            <ArrowUpRight className="w-3 h-3 text-primary" />
            Savings
          </div>
          <p className="text-lg font-semibold tabular-nums font-heading">
            {formatFromUSD(balanceData.savings)}
          </p>
        </div>
        <div className="space-y-1">
          <div className="flex items-center gap-1.5 text-xs text-muted-foreground">
            <ArrowDownRight className="w-3 h-3 text-destructive" />
            Spending
          </div>
          <p className="text-lg font-semibold tabular-nums font-heading">
            {formatFromUSD(balanceData.spending)}
          </p>
        </div>
      </div>
    </motion.div>
  );
};
