import React, { createContext, useContext, useState, useCallback, useEffect } from "react";

export type ThemeName = "soft-bloom" | "retro-pixel" | "modern-academic" | "kawaii-pastel" | "cyber-terminal";

const themeOrder: ThemeName[] = ["soft-bloom", "retro-pixel", "modern-academic", "kawaii-pastel", "cyber-terminal"];

interface ThemeContextType {
  theme: ThemeName;
  setTheme: (theme: ThemeName) => void;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export const themeLabels: Record<ThemeName, string> = {
  "soft-bloom": "Soft Bloom",
  "retro-pixel": "Retro Pixel",
  "modern-academic": "Modern Academic",
  "kawaii-pastel": "Kawaii Pastel",
  "cyber-terminal": "Cyber Terminal",
};

const isThemeName = (value: string | null): value is ThemeName => {
  if (!value) return false;
  return value in themeLabels;
};

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [theme, setThemeState] = useState<ThemeName>(() => {
    const storedTheme = localStorage.getItem("dashboard-theme");
    if (storedTheme === "cottage-sage" || storedTheme === "editorial-grid") return "soft-bloom";
    return isThemeName(storedTheme) ? storedTheme : "soft-bloom";
  });

  const setTheme = useCallback((t: ThemeName) => {
    setThemeState(t);
    localStorage.setItem("dashboard-theme", t);
  }, []);

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", theme);
  }, [theme]);

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.code !== "AltRight" || event.repeat) return;
      if (event.ctrlKey || event.metaKey || event.shiftKey) return;

      const target = event.target as HTMLElement | null;
      if (target?.isContentEditable) return;
      const tagName = target?.tagName;
      if (tagName === "INPUT" || tagName === "TEXTAREA" || tagName === "SELECT") return;

      const currentIndex = themeOrder.indexOf(theme);
      const nextTheme = themeOrder[(currentIndex + 1) % themeOrder.length];
      setThemeState(nextTheme);
      localStorage.setItem("dashboard-theme", nextTheme);
    };

    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [theme]);

  return (
    <ThemeContext.Provider value={{ theme, setTheme }}>
      {children}
    </ThemeContext.Provider>
  );
};

export const useTheme = () => {
  const ctx = useContext(ThemeContext);
  if (!ctx) throw new Error("useTheme must be used within ThemeProvider");
  return ctx;
};
