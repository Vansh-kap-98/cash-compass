import { motion, AnimatePresence } from "framer-motion";
import { useTheme, ThemeName, themeLabels } from "@/contexts/ThemeContext";
import { Flower2, Gamepad2, Cpu, Heart, Terminal } from "lucide-react";

const themeIcons: Record<ThemeName, React.ReactNode> = {
  "soft-bloom": <Flower2 className="w-5 h-5" />,
  "retro-pixel": <Gamepad2 className="w-5 h-5" />,
  "modern-academic": <Cpu className="w-5 h-5" />,
  "kawaii-pastel": <Heart className="w-5 h-5" />,
  "cyber-terminal": <Terminal className="w-5 h-5" />,
};

const themes: ThemeName[] = ["soft-bloom", "retro-pixel", "modern-academic", "kawaii-pastel", "cyber-terminal"];

export const ThemeToggle = () => {
  const { theme, setTheme } = useTheme();

  const cycleTheme = () => {
    const currentIndex = themes.indexOf(theme);
    const nextIndex = (currentIndex + 1) % themes.length;
    setTheme(themes[nextIndex]);
  };

  return (
    <div data-tour="theme-toggle" className="fixed top-6 right-6 z-[100]">
      <motion.button
        onClick={cycleTheme}
        whileHover={{ scale: 1.1 }}
        whileTap={{ scale: 0.9 }}
        className="relative w-12 h-12 rounded-full bg-primary text-primary-foreground flex items-center justify-center shadow-lg hover:shadow-xl transition-shadow group overflow-hidden"
        title={`Current: ${themeLabels[theme]}. Click to cycle or press Right Alt.`}
      >
        <AnimatePresence mode="wait">
          <motion.div
            key={theme}
            initial={{ y: 20, opacity: 0, rotate: -45 }}
            animate={{ y: 0, opacity: 1, rotate: 0 }}
            exit={{ y: -20, opacity: 0, rotate: 45 }}
            transition={{ duration: 0.2 }}
            className="relative z-10"
          >
            {themeIcons[theme]}
          </motion.div>
        </AnimatePresence>
        
        {}
        <motion.div
          className="absolute inset-0 bg-primary-foreground/10"
          animate={{
            scale: [1, 1.2, 1],
            opacity: [0.1, 0.2, 0.1],
          }}
          transition={{
            duration: 2,
            repeat: Infinity,
            ease: "easeInOut",
          }}
        />
      </motion.button>
    </div>
  );
};
