import { motion } from "framer-motion";
import { insights } from "@/data/mockData";
import { useCurrency } from "@/contexts/CurrencyContext";
import { useTheme } from "@/contexts/ThemeContext";
import { Lightbulb } from "lucide-react";

export const InsightBox = () => {
  const { theme } = useTheme();
  const { formatFromUSD } = useCurrency();

  const replaceDollarAmounts = (text: string) =>
    text.replace(/(~?)\$(\d+(?:\.\d+)?)/g, (_, approx: string, amountText: string) => {
      const amount = Number(amountText);
      const decimals = amountText.includes(".") ? 2 : 0;
      return `${approx}${formatFromUSD(amount, { maximumFractionDigits: decimals, minimumFractionDigits: decimals })}`;
    });

  return (
    <motion.div
      initial={{ opacity: 0, y: 12 }}
      animate={{ opacity: 1, y: 0 }}
      transition={{ duration: 0.4, delay: 0.15, ease: [0.4, 0, 0.2, 1] }}
      whileHover={{ y: -4, transition: { duration: 0.2 } }}
      className={`bg-card text-card-foreground rounded-lg p-6 shadow-card ${theme === "cottage-sage" ? "organic-radius paper-texture relative overflow-hidden" : ""}`}
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
                {replaceDollarAmounts(insight.description)}
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
