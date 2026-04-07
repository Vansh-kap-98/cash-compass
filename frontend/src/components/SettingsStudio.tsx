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

const colorSchemeLabels: Record<ColorScheme, string> = {
  bloom: "Bloom",
  mint: "Mint",
  sunset: "Sunset",
  ocean: "Ocean",
  forest: "Forest",
  coral: "Coral",
  slate: "Slate",
};

const colorMap: Record<ColorScheme, { primary: string; secondary: string; ring: string }> = {
  bloom: { primary: "270 20% 72%", secondary: "270 16% 87%", ring: "270 20% 72%" },
  mint: { primary: "165 30% 48%", secondary: "165 26% 88%", ring: "165 30% 48%" },
  sunset: { primary: "22 78% 58%", secondary: "20 70% 90%", ring: "22 78% 58%" },
  ocean: { primary: "204 75% 48%", secondary: "202 72% 90%", ring: "204 75% 48%" },
  forest: { primary: "138 42% 38%", secondary: "138 38% 88%", ring: "138 42% 38%" },
  coral: { primary: "12 82% 62%", secondary: "14 80% 90%", ring: "12 82% 62%" },
  slate: { primary: "220 12% 48%", secondary: "220 14% 89%", ring: "220 12% 48%" },
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
              {Object.entries(colorSchemeLabels).map(([value, label]) => (
                <SelectItem key={value} value={value}>{label}</SelectItem>
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
