import { motion } from "framer-motion";
import { useTheme, ThemeName, themeLabels } from "@/contexts/ThemeContext";
import { Flower2, Gamepad2, Leaf, Cpu, Heart, Terminal } from "lucide-react";

const themeIcons: Record<ThemeName, React.ReactNode> = {
  "soft-bloom": <Flower2 className="w-4 h-4" />,
  "retro-pixel": <Gamepad2 className="w-4 h-4" />,
  "cottage-sage": <Leaf className="w-4 h-4" />,
  "modern-academic": <Cpu className="w-4 h-4" />,
  "kawaii-pastel": <Heart className="w-4 h-4" />,
  "cyber-terminal": <Terminal className="w-4 h-4" />,
};

const themes: ThemeName[] = ["soft-bloom", "retro-pixel", "cottage-sage", "modern-academic", "kawaii-pastel", "cyber-terminal"];

export const ThemeSwitcher = () => {
  const { theme, setTheme } = useTheme();

  return (
    <div className="flex items-center gap-1 rounded-lg bg-secondary p-1">
      {themes.map((t) => (
        <motion.button
          key={t}
          onClick={() => setTheme(t)}
          whileTap={{ scale: 0.95 }}
          className={`relative flex items-center gap-1.5 px-3 py-1.5 text-xs font-medium transition-colors ${
            theme === t ? "text-primary-foreground" : "text-muted-foreground hover:text-foreground"
          }`}
          title={themeLabels[t]}
        >
          {theme === t && (
            <motion.div
              layoutId="theme-pill"
              className="absolute inset-0 bg-primary rounded-md"
              transition={{ type: "tween", duration: 0.3, ease: [0.4, 0, 0.2, 1] }}
            />
          )}
          <span className="relative z-10 flex items-center gap-1.5">
            {themeIcons[t]}
            <span className="hidden sm:inline">{themeLabels[t]}</span>
          </span>
        </motion.button>
      ))}
    </div>
  );
};
