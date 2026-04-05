import { motion } from "framer-motion";
import { useCurrency } from "@/contexts/CurrencyContext";
import { useTheme } from "@/contexts/ThemeContext";
import { useFinance } from "@/contexts/FinanceContext";
import { Button } from "@/components/ui/button";

export const SavingsProgress = () => {
  const { theme } = useTheme();
  const { formatFromUSD } = useCurrency();
  const { goals, contributeToGoal } = useFinance();

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: 0.1, ease: [0.4, 0, 0.2, 1] }}
      whileHover={{ y: -4, transition: { duration: 0.2 } }}
      className="bg-card text-card-foreground rounded-lg p-6 shadow-card"
    >
      <h2 className="font-heading text-sm font-medium text-muted-foreground uppercase tracking-wider mb-5">
        Savings Goals
      </h2>

      <div className="space-y-5">
        {goals.map((goal, i) => {
          const pct = Math.round((goal.current / goal.target) * 100);
          return (
            <motion.div
              key={goal.id}
              initial={{ opacity: 0, x: -10 }}
              animate={{ opacity: 1, x: 0 }}
              transition={{ delay: 0.15 + i * 0.08 }}
            >
              <div className="flex items-center justify-between mb-1.5">
                <div className="flex items-center gap-2">
                  <span className="text-base">{goal.icon}</span>
                  <span className="text-sm font-medium font-heading">{goal.name}</span>
                </div>
                <span className="text-xs tabular-nums text-muted-foreground">
                  {formatFromUSD(goal.current, { maximumFractionDigits: 0 })} / {formatFromUSD(goal.target, { maximumFractionDigits: 0 })}
                </span>
              </div>

              <div className="relative h-2 rounded-full bg-secondary overflow-hidden">
                <motion.div
                  className={`absolute inset-y-0 left-0 rounded-full ${
                    theme === "modern-academic"
                      ? "bg-primary h-[2px] top-auto bottom-0"
                      : "bg-primary"
                  }`}
                  initial={{ width: 0 }}
                  animate={{ width: `${pct}%` }}
                  transition={{ duration: 1.5, delay: 0.3 + i * 0.1, ease: [0.25, 0.1, 0.25, 1] }}
                />
              </div>

              <div className="mt-1 flex items-center justify-between">
                <p className="text-right text-xs tabular-nums text-muted-foreground">{pct}%</p>
                <Button
                  variant="outline"
                  size="sm"
                  className="h-7 px-2 text-[11px]"
                  onClick={() => contributeToGoal(goal.id, 100)}
                >
                  +100
                </Button>
              </div>
            </motion.div>
          );
        })}
      </div>
    </motion.div>
  );
};
