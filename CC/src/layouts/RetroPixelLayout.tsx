import { BalanceOverview } from "@/components/BalanceOverview";
import { SavingsProgress } from "@/components/SavingsProgress";
import { TransactionFeed } from "@/components/TransactionFeed";
import { InsightBox } from "@/components/InsightBox";
import { FinancialCharts } from "@/components/FinancialCharts";
import { Search, Play, Mail, Music2, TriangleAlert, Sparkles, Heart, Wallet, ScanLine, Gamepad2 } from "lucide-react";

const PixelBadge = ({ children }: { children: React.ReactNode }) => (
  <span className="retro-pixel-border bg-card px-2 py-1 text-[10px] uppercase tracking-[0.2em] text-primary">
    {children}
  </span>
);

const PixelWindow = ({ title, children }: { title: string; children: React.ReactNode }) => (
  <article className="retro-pixel-border bg-card">
    <div className="border-b-2 border-border bg-primary/80 px-3 py-2">
      <p className="text-[10px] uppercase tracking-[0.14em] text-primary-foreground">{title}</p>
    </div>
    <div className="p-4">{children}</div>
  </article>
);

export const RetroPixelLayout = () => (
  <div className="relative min-h-screen overflow-hidden bg-background px-4 py-8 md:px-8 md:py-10">
    <div className="pointer-events-none absolute inset-0 retro-grid" />

    <div className="relative mx-auto max-w-6xl space-y-6">
      <header className="retro-pixel-border bg-card px-4 py-5 md:px-6">
        <div className="flex flex-wrap items-center justify-between gap-4">
          <div className="space-y-1">
            <h1 className="font-heading text-2xl uppercase text-foreground md:text-4xl">Pixel Finance Desk</h1>
            <p className="text-xs uppercase tracking-[0.15em] text-muted-foreground">Cash Compass 1999 Edition</p>
          </div>
          <div className="flex flex-wrap items-center gap-2 text-[10px]">
            <PixelBadge>100% Online</PixelBadge>
            <PixelBadge>Commercial Ready</PixelBadge>
          </div>
        </div>
      </header>

      <section className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <PixelWindow title="Search Console">
          <div className="retro-pixel-border flex items-center gap-2 bg-secondary/70 px-2 py-2">
            <Search className="h-4 w-4 text-primary" />
            <p className="text-xs text-muted-foreground">Search transactions, bills, goals...</p>
          </div>
        </PixelWindow>

        <PixelWindow title="Now Playing">
          <div className="space-y-3">
            <div className="flex items-center justify-between text-xs text-muted-foreground">
              <span>Budget Wave 64kb</span>
              <Play className="h-4 w-4 text-primary" />
            </div>
            <div className="retro-pixel-border h-9 bg-secondary/70 p-1">
              <div className="h-full w-full bg-[repeating-linear-gradient(90deg,transparent_0px,transparent_4px,hsl(var(--primary)/0.35)_4px,hsl(var(--primary)/0.35)_5px)]" />
            </div>
          </div>
        </PixelWindow>

        <PixelWindow title="Inbox Status">
          <div className="space-y-2 text-xs">
            <div className="flex items-center justify-between">
              <span className="text-muted-foreground">Unread alerts</span>
              <span className="retro-pixel-border bg-accent px-2 py-0.5 text-accent-foreground">3</span>
            </div>
            <div className="flex items-center justify-between">
              <span className="text-muted-foreground">Receipts to sort</span>
              <span className="retro-pixel-border bg-secondary px-2 py-0.5">7</span>
            </div>
          </div>
        </PixelWindow>
      </section>

      <section className="grid grid-cols-2 gap-3 md:grid-cols-6">
        {[
          { icon: Search, label: "Scan" },
          { icon: Sparkles, label: "Magic" },
          { icon: Heart, label: "Mood" },
          { icon: TriangleAlert, label: "Alerts" },
          { icon: Music2, label: "Music" },
          { icon: Mail, label: "Mail" },
        ].map((item) => (
          <div key={item.label} className="retro-pixel-border flex h-16 items-center justify-center gap-2 bg-card transition-transform duration-200 hover:-translate-y-1">
            <item.icon className="h-4 w-4 text-primary" />
            <span className="text-[10px] uppercase tracking-[0.1em] text-foreground">{item.label}</span>
          </div>
        ))}
      </section>

      <section className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <div className="space-y-4 md:col-span-2">
          <BalanceOverview />
          <FinancialCharts />

          <PixelWindow title="Retro Control Panel">
            <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
              <div className="space-y-2">
                <p className="text-[10px] uppercase tracking-[0.15em] text-muted-foreground">Savings Throttle</p>
                <div className="retro-pixel-border h-3 bg-secondary">
                  <div className="h-full w-2/3 bg-primary" />
                </div>
              </div>
              <div className="space-y-2">
                <p className="text-[10px] uppercase tracking-[0.15em] text-muted-foreground">Spending Guard</p>
                <div className="retro-pixel-border h-3 bg-secondary">
                  <div className="h-full w-1/2 bg-accent" />
                </div>
              </div>
            </div>
          </PixelWindow>
        </div>

        <div className="space-y-4">
          <PixelWindow title="Quick Scan">
            <div className="space-y-3 text-xs">
              <div className="retro-pixel-border flex items-center justify-between bg-secondary/50 px-2 py-2">
                <span className="text-muted-foreground">Receipt OCR</span>
                <ScanLine className="h-4 w-4 text-primary" />
              </div>
              <div className="retro-pixel-border flex items-center justify-between bg-secondary/50 px-2 py-2">
                <span className="text-muted-foreground">Wallet Sync</span>
                <Wallet className="h-4 w-4 text-primary" />
              </div>
              <div className="retro-pixel-border flex items-center justify-between bg-secondary/50 px-2 py-2">
                <span className="text-muted-foreground">Gameplan Mode</span>
                <Gamepad2 className="h-4 w-4 text-primary" />
              </div>
            </div>
          </PixelWindow>

          <PixelWindow title="System Lights">
            <div className="flex items-center justify-between">
              {[
                { label: "Bank", active: true },
                { label: "Cloud", active: true },
                { label: "Alerts", active: false },
              ].map((light) => (
                <div key={light.label} className="flex flex-col items-center gap-2 text-[10px] uppercase tracking-[0.08em] text-muted-foreground">
                  <div className={`h-4 w-4 border-2 border-border ${light.active ? "bg-primary" : "bg-accent"}`} />
                  <span>{light.label}</span>
                </div>
              ))}
            </div>
          </PixelWindow>

          <InsightBox />
        </div>
      </section>

      <section className="grid grid-cols-1 gap-4 md:grid-cols-2">
        <SavingsProgress />
        <TransactionFeed />
      </section>

      <section className="grid grid-cols-1 gap-4 md:grid-cols-3">
        <PixelWindow title="Pinned Goals">
          <div className="space-y-2 text-xs text-muted-foreground">
            <p className="retro-pixel-border bg-secondary/40 px-2 py-1">Emergency Fund at 74%</p>
            <p className="retro-pixel-border bg-secondary/40 px-2 py-1">Travel Vault at 38%</p>
            <p className="retro-pixel-border bg-secondary/40 px-2 py-1">Investment Auto-DCA enabled</p>
          </div>
        </PixelWindow>
        <PixelWindow title="Alerts Queue">
          <div className="space-y-2 text-xs text-muted-foreground">
            <div className="retro-pixel-border flex items-center justify-between bg-secondary/40 px-2 py-1">
              <span>Card bill due in 2 days</span>
              <TriangleAlert className="h-3.5 w-3.5 text-destructive" />
            </div>
            <div className="retro-pixel-border flex items-center justify-between bg-secondary/40 px-2 py-1">
              <span>Subscription spike detected</span>
              <Sparkles className="h-3.5 w-3.5 text-primary" />
            </div>
          </div>
        </PixelWindow>
        <PixelWindow title="Messages">
          <div className="space-y-2 text-xs text-muted-foreground">
            <div className="retro-pixel-border flex items-center gap-2 bg-secondary/40 px-2 py-1">
              <Mail className="h-3.5 w-3.5 text-primary" />
              <span>Weekly report generated</span>
            </div>
            <div className="retro-pixel-border flex items-center gap-2 bg-secondary/40 px-2 py-1">
              <Music2 className="h-3.5 w-3.5 text-primary" />
              <span>Money Focus playlist ready</span>
            </div>
          </div>
        </PixelWindow>
      </section>

      <footer className="retro-pixel-border bg-card px-4 py-3">
        <div className="flex flex-wrap items-center justify-between gap-2 text-[10px] uppercase tracking-[0.15em] text-muted-foreground">
          <span>ART4FREE vibe</span>
          <span className="text-foreground">.EPS .JPG</span>
        </div>
      </footer>
    </div>
  </div>
);
