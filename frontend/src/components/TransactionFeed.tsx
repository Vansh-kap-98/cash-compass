import { motion } from "framer-motion";
import { useCurrency } from "@/contexts/CurrencyContext";
import { useFinance } from "@/contexts/FinanceContext";
import { formatDistanceToNowStrict } from "date-fns";

export const TransactionFeed = () => {
  const { formatFromUSD } = useCurrency();
  const { transactions } = useFinance();

  const sortedTransactions = [...transactions].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime());

  const formatAmount = (n: number) => {
    const formatted = formatFromUSD(Math.abs(n));
    return n < 0 ? `−${formatted}` : `+${formatted}`;
  };

  const formatDate = (isoDate: string) => {
    const date = new Date(isoDate);
    if (Number.isNaN(date.getTime())) return "Unknown date";

    const distance = formatDistanceToNowStrict(date, { addSuffix: true });
    return distance.replace("about ", "");
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: 0.2, ease: [0.4, 0, 0.2, 1] }}
      whileHover={{ y: -4, transition: { duration: 0.2 } }}
      className="bg-card text-card-foreground rounded-lg p-6 shadow-card"
    >
      <h2 className="font-heading text-sm font-medium text-muted-foreground uppercase tracking-wider mb-5">
        Recent Transactions
      </h2>

      <div className="space-y-0">
        {sortedTransactions.map((tx, i) => (
          <motion.div
            key={tx.id}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.25 + i * 0.05 }}
            className={`flex items-center justify-between py-3 ${
              i < sortedTransactions.length - 1
                ? "border-b border-border"
                : ""
            }`}
          >
            <div className="flex items-center gap-3">
              <span className="text-lg">{tx.icon ?? (tx.type === "income" ? "💰" : "💸")}</span>
              <div>
                <p className="text-sm font-medium font-heading">{tx.name}</p>
                <p className="text-xs text-muted-foreground">{tx.category} · {formatDate(tx.date)}</p>
              </div>
            </div>
            <span
              className={`text-sm font-semibold tabular-nums ${
                tx.type === "expense" ? "text-destructive" : "text-primary"
              }`}
            >
              {formatAmount(tx.type === "expense" ? -tx.amount : tx.amount)}
            </span>
          </motion.div>
        ))}
      </div>
    </motion.div>
  );
};
