import React, { createContext, useContext, useState, useCallback, useEffect } from "react";

export type ThemeName = "soft-bloom" | "noir" | "cottage-sage" | "modern-academic" | "kawaii-pastel" | "cyber-terminal" | "classic-linen";

interface ThemeContextType {
  theme: ThemeName;
  setTheme: (theme: ThemeName) => void;
}

const ThemeContext = createContext<ThemeContextType | undefined>(undefined);

export const themeLabels: Record<ThemeName, string> = {
  "soft-bloom": "Soft Bloom",
  "noir": "Noir Monochrome",
  "cottage-sage": "Cottage Sage",
  "modern-academic": "Modern Academic",
  "kawaii-pastel": "Kawaii Pastel",
  "cyber-terminal": "Cyber Terminal",
  "classic-linen": "Classic Linen",
};

export const ThemeProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [theme, setThemeState] = useState<ThemeName>(() => {
    return (localStorage.getItem("dashboard-theme") as ThemeName) || "soft-bloom";
  });

  const setTheme = useCallback((t: ThemeName) => {
    setThemeState(t);
    localStorage.setItem("dashboard-theme", t);
  }, []);

  useEffect(() => {
    document.documentElement.setAttribute("data-theme", theme);
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
