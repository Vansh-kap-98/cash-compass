import { ThemeName } from "@/contexts/ThemeContext";
import {
  Activity,
  BellRing,
  Bot,
  Fingerprint,
  Flame,
  Layers,
  MoonStar,
  Sparkles,
  Users,
  Wallet,
  Waves,
  Zap,
} from "lucide-react";

type FeatureItem = {
  title: string;
  summary: string;
  tags: string[];
  icon: React.ComponentType<{ className?: string }>;
};

const showcaseItems: FeatureItem[] = [
  {
    title: "One-Tap Quick Entry",
    summary: "Floating FAB + portal overlay mock with GSAP pop animation preset.",
    tags: ["Portal", "useRef auto-focus", "GSAP fromTo"],
    icon: Zap,
  },
  {
    title: "Safe-to-Spend Dashboard",
    summary: "Hero allowance widget preview with memoized formula and daily refresh option.",
    tags: ["Memoized calc", "Zustand bucket", "00:00 refresh"],
    icon: Wallet,
  },
  {
    title: "Burn-Rate Forecaster",
    summary: "Trend-line panel preview with 7-day average and zero-date intersection.",
    tags: ["Rolling avg", "Regression", "Gradient line"],
    icon: Flame,
  },
  {
    title: "Shared Roommate Lobbies",
    summary: "Lobby controls and realtime sync options for cross-device debt updates.",
    tags: ["Supabase Realtime", "Ledger", "Settlement minimizer"],
    icon: Users,
  },
  {
    title: "Automated Subscription Tracker",
    summary: "Recurring charge detector options with cycle metadata and reminders.",
    tags: ["28-31 day pattern", "is_recurring", "48h reminder"],
    icon: BellRing,
  },
  {
    title: "Smart Auto-Categorization",
    summary: "Dictionary and fuzzy matching controls with manual override learning.",
    tags: ["JSON map", "fuse.js", "User override"],
    icon: Bot,
  },
  {
    title: "Visual Sub-Stash Goals",
    summary: "Liquid-fill goal card with SVG wave and bounce micro-interaction options.",
    tags: ["(current/goal)*100", "clip-path wave", "GSAP bounce"],
    icon: Waves,
  },
  {
    title: "Nudge Notifications",
    summary: "Budget depletion trigger presets and rotating message tone controls.",
    tags: ["50/80/100", "Template literal", "friendly/urgent JSON"],
    icon: Sparkles,
  },
  {
    title: "Biometric Fast-Access",
    summary: "Security card with WebAuthn and short-lived token session mode options.",
    tags: ["WebAuthn", "Biometric gate", "Secure token"],
    icon: Fingerprint,
  },
  {
    title: "Dark Mode & Night Themes",
    summary: "Theme switching controls with local persistence and smooth transitions.",
    tags: ["Tailwind dark:", "matchMedia", "duration-500"],
    icon: MoonStar,
  },
];

const themeClasses: Record<ThemeName, { frame: string; card: string; pill: string; button: string; fab: string }> = {
  "soft-bloom": {
    frame: "rounded-3xl border border-border bg-card/70 p-5 shadow-card",
    card: "rounded-2xl border border-border bg-background/70 p-4",
    pill: "rounded-full bg-primary/15 px-2 py-0.5 text-primary",
    button: "rounded-xl border border-border bg-card px-3 py-1.5 text-xs hover:bg-accent",
    fab: "bg-primary text-primary-foreground shadow-card",
  },
  "retro-pixel": {
    frame: "retro-pixel-border bg-card p-4",
    card: "retro-pixel-border bg-secondary/30 p-3",
    pill: "retro-pixel-border bg-card px-2 py-0.5 text-primary",
    button: "retro-pixel-border bg-card px-3 py-1.5 text-[10px] uppercase tracking-[0.1em]",
    fab: "retro-pixel-border bg-primary text-primary-foreground",
  },
  "modern-academic": {
    frame: "border border-border bg-card p-4",
    card: "border border-border bg-background/60 p-4",
    pill: "border border-border bg-secondary/40 px-2 py-0.5 font-mono text-[10px]",
    button: "border border-border bg-card px-3 py-1.5 text-[10px] font-mono uppercase",
    fab: "border border-border bg-primary text-primary-foreground",
  },
  "kawaii-pastel": {
    frame: "rounded-[2rem] border-2 border-primary/20 bg-white/95 p-5 shadow-card",
    card: "rounded-[1.2rem] border-2 border-secondary/30 bg-white p-4",
    pill: "rounded-full bg-primary/15 px-2 py-0.5 text-primary",
    button: "rounded-full border-2 border-primary/20 bg-white px-3 py-1.5 text-xs hover:bg-primary/10",
    fab: "rounded-full border-4 border-primary/30 bg-primary text-primary-foreground shadow-card",
  },
  "cyber-terminal": {
    frame: "rounded border border-primary/20 bg-black/40 p-4",
    card: "rounded border border-primary/15 bg-black/50 p-4",
    pill: "rounded border border-primary/20 bg-primary/10 px-2 py-0.5 text-primary",
    button: "rounded border border-primary/20 bg-black/40 px-3 py-1.5 text-[10px] uppercase",
    fab: "rounded border border-primary/30 bg-primary text-primary-foreground",
  },
};

export const FeatureShowcase = ({ theme }: { theme: ThemeName }) => {
  const styles = themeClasses[theme];

  return (
    <section className={styles.frame}>
      <div className="mb-4 flex items-start justify-between gap-3">
        <div>
          <h2 className="font-heading text-lg">Spec Feature Showcase</h2>
          <p className="text-xs text-muted-foreground">UI only for now. Buttons and options are placeholders for future wiring.</p>
        </div>
        <button type="button" className={styles.button}>Open Roadmap</button>
      </div>

      <div className="grid grid-cols-1 gap-3 lg:grid-cols-2">
        {showcaseItems.map((item) => (
          <article key={item.title} className={styles.card}>
            <div className="mb-2 flex items-center justify-between gap-2">
              <p className="flex items-center gap-2 text-sm font-semibold">
                <item.icon className="h-4 w-4 text-primary" />
                {item.title}
              </p>
              <span className={styles.pill}>Showcase</span>
            </div>
            <p className="mb-3 text-xs text-muted-foreground">{item.summary}</p>
            <div className="mb-3 flex flex-wrap gap-2 text-[10px] uppercase tracking-[0.08em] text-muted-foreground">
              {item.tags.map((tag) => (
                <span key={tag} className={styles.pill}>{tag}</span>
              ))}
            </div>
            <div className="flex flex-wrap gap-2">
              <button type="button" className={styles.button}>Preview</button>
              <button type="button" className={styles.button}>Configure</button>
              <button type="button" className={styles.button}>Enable Later</button>
            </div>
          </article>
        ))}
      </div>

      <button
        type="button"
        aria-label="Quick Entry Showcase"
        className={`fixed bottom-6 right-6 z-50 flex h-14 w-14 items-center justify-center text-xl ${styles.fab}`}
      >
        +
      </button>
      <p className="mt-4 text-xs text-muted-foreground">Floating Action Button is rendered as a static showcase element in this phase.</p>
    </section>
  );
};
