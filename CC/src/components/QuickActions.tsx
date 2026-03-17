import { motion } from "framer-motion";
import { Plus, Target } from "lucide-react";

export const QuickActions = () => {
  return (
    <div className="fixed bottom-6 right-6 flex flex-col gap-3 z-50">
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95, transition: { type: "spring", stiffness: 400, damping: 10 } }}
        className="flex items-center gap-2 bg-primary text-primary-foreground px-4 py-2.5 rounded-lg shadow-card-hover text-sm font-medium font-heading"
      >
        <Plus className="w-4 h-4" />
        Add Expense
      </motion.button>
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95, transition: { type: "spring", stiffness: 400, damping: 10 } }}
        className="flex items-center gap-2 bg-secondary text-secondary-foreground px-4 py-2.5 rounded-lg shadow-card text-sm font-medium font-heading"
      >
        <Target className="w-4 h-4" />
        Set Goal
      </motion.button>
    </div>
  );
};
