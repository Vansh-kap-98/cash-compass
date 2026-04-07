import { useEffect, useMemo, useState } from "react";
import { useTheme, type ThemeName, themeLabels } from "@/contexts/ThemeContext";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Slider } from "@/components/ui/slider";
import { useCurrency, type CurrencyCode } from "@/contexts/CurrencyContext";

const STORAGE_KEY = "cash-compass-ui-settings-v1";

type FontPack = "default" | "editorial" | "mono";
type ColorScheme = "bloom" | "mint" | "sunset" | "ocean" | "forest" | "coral" | "slate";

interface ColorPair {
  label: string;
  primary: string;
  accent: string;
  primarySoft: string;
  primaryDeep: string;
  accentSoft: string;
  accentDeep: string;
  secondary: string;
  ring: string;
}

interface UiSettings {
  fontScale: number;
  fontPack: FontPack;
  colorScheme: ColorScheme;
}

const themeKeys: ThemeName[] = ["soft-bloom", "retro-pixel", "modern-academic", "kawaii-pastel", "cyber-terminal"];

const defaultSettings: UiSettings = {
  fontScale: 100,
  fontPack: "default",
  colorScheme: "bloom",
};

const colorMap: Record<ColorScheme, ColorPair> = {
  bloom: {
    label: "Bloom (Lavender + Peach)",
    primary: "270 20% 72%",
    accent: "24 85% 67%",
    primarySoft: "270 42% 91%",
    primaryDeep: "272 34% 52%",
    accentSoft: "24 100% 91%",
    accentDeep: "20 86% 54%",
    secondary: "270 16% 87%",
    ring: "270 20% 72%",
  },
  mint: {
    label: "Mint (Mint + Teal)",
    primary: "165 30% 48%",
    accent: "188 74% 42%",
    primarySoft: "160 42% 88%",
    primaryDeep: "164 44% 34%",
    accentSoft: "189 70% 87%",
    accentDeep: "188 88% 32%",
    secondary: "165 26% 88%",
    ring: "165 30% 48%",
  },
  sunset: {
    label: "Sunset (Orange + Rose)",
    primary: "22 78% 58%",
    accent: "342 75% 58%",
    primarySoft: "22 96% 88%",
    primaryDeep: "18 84% 48%",
    accentSoft: "342 82% 89%",
    accentDeep: "341 70% 44%",
    secondary: "20 70% 90%",
    ring: "22 78% 58%",
  },
  ocean: {
    label: "Ocean (Blue + Cyan)",
    primary: "204 75% 48%",
    accent: "188 83% 48%",
    primarySoft: "204 90% 87%",
    primaryDeep: "209 74% 39%",
    accentSoft: "188 88% 86%",
    accentDeep: "188 84% 36%",
    secondary: "202 72% 90%",
    ring: "204 75% 48%",
  },
  forest: {
    label: "Forest (Pine + Moss)",
    primary: "138 42% 38%",
    accent: "90 34% 43%",
    primarySoft: "138 36% 85%",
    primaryDeep: "142 45% 28%",
    accentSoft: "90 34% 83%",
    accentDeep: "88 36% 33%",
    secondary: "138 38% 88%",
    ring: "138 42% 38%",
  },
  coral: {
    label: "Coral (Coral + Amber)",
    primary: "12 82% 62%",
    accent: "38 88% 56%",
    primarySoft: "12 98% 88%",
    primaryDeep: "11 78% 49%",
    accentSoft: "42 96% 86%",
    accentDeep: "35 88% 45%",
    secondary: "14 80% 90%",
    ring: "12 82% 62%",
  },
  slate: {
    label: "Slate (Slate + Indigo)",
    primary: "220 12% 48%",
    accent: "238 46% 57%",
    primarySoft: "220 20% 86%",
    primaryDeep: "220 16% 34%",
    accentSoft: "238 58% 87%",
    accentDeep: "238 50% 44%",
    secondary: "220 14% 89%",
    ring: "220 12% 48%",
  },
};

const fontMap: Record<FontPack, { heading: string; body: string }> = {
  default: { heading: "'Outfit', sans-serif", body: "'Inter', sans-serif" },
  editorial: { heading: "'Playfair Display', serif", body: "'Newsreader', serif" },
  mono: { heading: "'Geist Mono', monospace", body: "'JetBrains Mono', monospace" },
};

export const SettingsStudio = () => {
  const { theme, setTheme } = useTheme();
  const { currency, setCurrency } = useCurrency();

  const isColorScheme = (value: unknown): value is ColorScheme => typeof value === "string" && value in colorMap;
  const isFontPack = (value: unknown): value is FontPack => value === "default" || value === "editorial" || value === "mono";

  const [settings, setSettings] = useState<UiSettings>(() => {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return defaultSettings;

    try {
      const parsed = JSON.parse(raw) as Partial<UiSettings>;
      return {
        fontScale: Number.isFinite(parsed.fontScale) ? Math.min(120, Math.max(85, Number(parsed.fontScale))) : defaultSettings.fontScale,
        fontPack: isFontPack(parsed.fontPack) ? parsed.fontPack : defaultSettings.fontPack,
        colorScheme: isColorScheme(parsed.colorScheme) ? parsed.colorScheme : defaultSettings.colorScheme,
      };
    } catch {
      return defaultSettings;
    }
  });

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(settings));
  }, [settings]);

  useEffect(() => {
    const root = document.documentElement;
    root.style.setProperty("font-size", `${settings.fontScale}%`);

    const colors = colorMap[settings.colorScheme];
    root.style.setProperty("--primary", colors.primary);
    root.style.setProperty("--accent", colors.accent);
    root.style.setProperty("--theme-primary-soft", colors.primarySoft);
    root.style.setProperty("--theme-primary-deep", colors.primaryDeep);
    root.style.setProperty("--theme-accent-soft", colors.accentSoft);
    root.style.setProperty("--theme-accent-deep", colors.accentDeep);
    root.style.setProperty("--secondary", colors.secondary);
    root.style.setProperty("--ring", colors.ring);

    const fonts = fontMap[settings.fontPack];
    root.style.setProperty("--font-heading", fonts.heading);
    root.style.setProperty("--font-body", fonts.body);
  }, [settings]);

  const layoutOptions = useMemo(
    () => themeKeys.map((key) => ({ key, label: themeLabels[key] })),
    [],
  );

  return (
    <Card className="rounded-2xl">
      <CardHeader>
        <CardTitle className="text-base">Settings Studio</CardTitle>
        <p className="text-sm text-muted-foreground">Adjust layout theme, currency, color scheme, font style, and text size.</p>
      </CardHeader>
      <CardContent className="grid grid-cols-1 gap-5 md:grid-cols-2">
        <div className="space-y-2">
          <Label>Layout Theme</Label>
          <Select value={theme} onValueChange={(value) => setTheme(value as ThemeName)}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {layoutOptions.map((option) => (
                <SelectItem key={option.key} value={option.key}>{option.label}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <div className="space-y-2">
          <Label>Currency</Label>
          <Select value={currency} onValueChange={(value) => setCurrency(value as CurrencyCode)}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="USD">USD</SelectItem>
              <SelectItem value="INR">INR</SelectItem>
              <SelectItem value="RUB">RUB</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="space-y-2">
          <Label>Color Scheme</Label>
          <Select value={settings.colorScheme} onValueChange={(value) => setSettings((prev) => ({ ...prev, colorScheme: value as ColorScheme }))}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              {Object.entries(colorMap).map(([value, colorPair]) => (
                <SelectItem key={value} value={value}>{colorPair.label}</SelectItem>
              ))}
            </SelectContent>
          </Select>
        </div>

        <div className="space-y-2">
          <Label>Font Family</Label>
          <Select value={settings.fontPack} onValueChange={(value) => setSettings((prev) => ({ ...prev, fontPack: value as FontPack }))}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="default">Default</SelectItem>
              <SelectItem value="editorial">Editorial Serif</SelectItem>
              <SelectItem value="mono">Monospace Focus</SelectItem>
            </SelectContent>
          </Select>
        </div>

        <div className="space-y-2">
          <Label>Font Size ({settings.fontScale}%)</Label>
          <Slider
            value={[settings.fontScale]}
            min={85}
            max={120}
            step={1}
            onValueChange={(value) => setSettings((prev) => ({ ...prev, fontScale: value[0] ?? 100 }))}
          />
        </div>
      </CardContent>
    </Card>
  );
};
