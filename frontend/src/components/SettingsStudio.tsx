import { useEffect, useMemo, useState } from "react";
import { useTheme, type ThemeName, themeLabels } from "@/contexts/ThemeContext";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Label } from "@/components/ui/label";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Slider } from "@/components/ui/slider";
import { useCurrency, type CurrencyCode } from "@/contexts/CurrencyContext";
import { Badge } from "@/components/ui/badge";
import { RefreshCw } from "lucide-react";
import { Button } from "@/components/ui/button";
import { restartAppTour } from "@/lib/tourState";

const STORAGE_KEY = "cash-compass-ui-settings-v1";

type FontPack = "default" | "editorial" | "mono";

interface UiSettings {
  fontScale: number;
  fontPack: FontPack;
}

const themeKeys: ThemeName[] = ["soft-bloom", "retro-pixel", "modern-academic", "kawaii-pastel", "cyber-terminal"];

const defaultSettings: UiSettings = {
  fontScale: 100,
  fontPack: "default",
};

const fontMap: Record<FontPack, { heading: string; body: string }> = {
  default: { heading: "'Outfit', sans-serif", body: "'Inter', sans-serif" },
  editorial: { heading: "'Playfair Display', serif", body: "'Newsreader', serif" },
  mono: { heading: "'Geist Mono', monospace", body: "'JetBrains Mono', monospace" },
};

export const SettingsStudio = () => {
  const { theme, setTheme } = useTheme();
  const { currency, setCurrency, ratesLoading, ratesError, lastUpdated } = useCurrency();

  const isFontPack = (value: unknown): value is FontPack => value === "default" || value === "editorial" || value === "mono";

  const [settings, setSettings] = useState<UiSettings>(() => {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return defaultSettings;

    try {
      const parsed = JSON.parse(raw) as Partial<UiSettings>;
      return {
        fontScale: Number.isFinite(parsed.fontScale) ? Math.min(120, Math.max(85, Number(parsed.fontScale))) : defaultSettings.fontScale,
        fontPack: isFontPack(parsed.fontPack) ? parsed.fontPack : defaultSettings.fontPack,
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
        <p className="text-sm text-muted-foreground">Adjust theme colours, currency, font style, and text size. Layout stays the same across all themes.</p>
      </CardHeader>
      <CardContent className="grid grid-cols-1 gap-5 md:grid-cols-2">
        <div className="space-y-2">
          <Label>Theme (Colors Only)</Label>
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
          <p className="text-xs text-muted-foreground">Switching theme changes colours, fonts, and visual style only.</p>
        </div>

        <div className="space-y-2">
          <Label>Currency</Label>
          <Select value={currency} onValueChange={(value) => setCurrency(value as CurrencyCode)}>
            <SelectTrigger>
              <SelectValue />
            </SelectTrigger>
            <SelectContent>
              <SelectItem value="USD">USD ($)</SelectItem>
              <SelectItem value="INR">INR (₹)</SelectItem>
              <SelectItem value="RUB">RUB (₽)</SelectItem>
            </SelectContent>
          </Select>
          <div className="flex items-center gap-2 text-xs text-muted-foreground">
            {ratesLoading && (
              <span className="flex items-center gap-1">
                <RefreshCw className="h-3 w-3 animate-spin" /> Updating rates…
              </span>
            )}
            {!ratesLoading && lastUpdated && (
              <span>Rates updated {lastUpdated.toLocaleTimeString()}</span>
            )}
            {ratesError && (
              <Badge variant="secondary" className="text-xs">{ratesError}</Badge>
            )}
          </div>
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

        <div className="space-y-2 rounded-2xl border border-border bg-secondary/20 p-4 md:col-span-2">
          <div>
            <Label>App tour</Label>
            <p className="mt-1 text-xs text-muted-foreground">Replay the dashboard walkthrough whenever you want a quick orientation.</p>
          </div>
          <Button type="button" variant="secondary" size="sm" onClick={restartAppTour}>Restart app tour</Button>
        </div>
      </CardContent>
    </Card>
  );
};
