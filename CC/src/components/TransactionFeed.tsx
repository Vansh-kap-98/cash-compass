import { motion } from "framer-motion";
import { transactions } from "@/data/mockData";
import { useTheme } from "@/contexts/ThemeContext";

export const TransactionFeed = () => {
  const { theme } = useTheme();

  const formatAmount = (n: number) => {
    const formatted = new Intl.NumberFormat("en-US", { style: "currency", currency: "USD" }).format(Math.abs(n));
    return n < 0 ? `−${formatted}` : `+${formatted}`;
  };

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: 0.2, ease: [0.4, 0, 0.2, 1] }}
      whileHover={{ y: -4, transition: { duration: 0.2 } }}
      className={`bg-card text-card-foreground rounded-lg p-6 shadow-card ${theme === "cottage-sage" ? "organic-radius paper-texture relative overflow-hidden" : ""}`}
    >
      <h2 className="font-heading text-sm font-medium text-muted-foreground uppercase tracking-wider mb-5">
        Recent Transactions
      </h2>

      <div className="space-y-0">
        {transactions.map((tx, i) => (
          <motion.div
            key={tx.id}
            initial={{ opacity: 0, y: 8 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.25 + i * 0.05 }}
            className={`flex items-center justify-between py-3 ${
              i < transactions.length - 1
                ? "border-b border-border"
                : ""
            }`}
          >
            <div className="flex items-center gap-3">
              <span className="text-lg">{tx.icon}</span>
              <div>
                <p className="text-sm font-medium font-heading">{tx.name}</p>
                <p className="text-xs text-muted-foreground">{tx.category} · {tx.date}</p>
              </div>
            </div>
            <span
              className={`text-sm font-semibold tabular-nums ${
                tx.amount < 0 ? "text-destructive" : "text-primary"
              }`}
            >
              {formatAmount(tx.amount)}
            </span>
          </motion.div>
        ))}
      </div>
    </motion.div>
  );
};
