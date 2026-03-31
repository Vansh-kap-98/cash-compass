import { BalanceOverview } from "@/components/BalanceOverview";
import { SavingsProgress } from "@/components/SavingsProgress";
import { TransactionFeed } from "@/components/TransactionFeed";
import { InsightBox } from "@/components/InsightBox";
import { FinancialCharts } from "@/components/FinancialCharts";
import { FeatureShowcase } from "@/components/FeatureShowcase";
import { useCurrency } from "@/contexts/CurrencyContext";
import { Wallet, Bell, CalendarClock, PiggyBank } from "lucide-react";

const SoftWidget = ({ title, children }: { title: string; children: React.ReactNode }) => (
  <div className="rounded-2xl border border-border bg-card/80 p-3 shadow-card">
    <p className="mb-2 text-[11px] font-medium uppercase tracking-wide text-muted-foreground">{title}</p>
    {children}
  </div>
);

export const SoftBloomLayout = () => {
  const { formatFromUSD } = useCurrency();

  return (
  <div className="flex min-h-screen">
    {}
    <aside className="w-[280px] shrink-0 border-r border-border bg-secondary/30 p-6 flex flex-col gap-6 sticky top-0 h-screen overflow-y-auto">
      <div className="flex items-center gap-2 mb-4">
        <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center">
          <Wallet className="w-4 h-4 text-primary-foreground" />
        </div>
        <span className="font-heading font-semibold text-lg">Curated</span>
      </div>

      <nav className="space-y-1 mt-4 font-body text-sm">
        {["Dashboard", "Transactions", "Goals", "Insights", "Settings"].map((item, i) => (
          <div
            key={item}
            className={`px-3 py-2 rounded-lg cursor-pointer transition-colors ${
              i === 0 ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:bg-accent"
            }`}
          >
            {item}
          </div>
        ))}
      </nav>

      <div className="space-y-3">
        <SoftWidget title="Today">
          <div className="flex items-center justify-between text-xs">
            <span className="flex items-center gap-1.5 text-muted-foreground">
              <CalendarClock className="h-3.5 w-3.5 text-primary" /> Next bill
            </span>
            <span className="font-medium">2d</span>
          </div>
        </SoftWidget>
        <SoftWidget title="Alerts">
          <div className="flex items-center justify-between text-xs">
            <span className="flex items-center gap-1.5 text-muted-foreground">
              <Bell className="h-3.5 w-3.5 text-primary" /> Unread
            </span>
            <span className="rounded-full bg-primary/20 px-2 py-0.5 font-medium text-primary">3</span>
          </div>
        </SoftWidget>
        <SoftWidget title="Auto Save">
          <div className="space-y-2 text-xs">
            <div className="flex items-center justify-between text-muted-foreground">
              <span className="flex items-center gap-1.5"><PiggyBank className="h-3.5 w-3.5 text-primary" /> Weekly target</span>
              <span>{formatFromUSD(220, { maximumFractionDigits: 0 })}</span>
            </div>
            <div className="h-2 rounded-full bg-secondary">
              <div className="h-full w-[68%] rounded-full bg-primary" />
            </div>
          </div>
        </SoftWidget>
      </div>

      <div className="mt-auto text-xs text-muted-foreground">
        <p className="font-heading font-medium">Your financial landscape,</p>
        <p className="italic">curated.</p>
      </div>
    </aside>

    {}
    <main className="flex-1 px-8 py-8 max-w-4xl space-y-6">
      <h1 className="font-heading text-2xl font-bold">Good morning ✨</h1>
      <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
        <div className="rounded-2xl border border-border bg-card p-4 shadow-card">
          <p className="text-xs uppercase tracking-wide text-muted-foreground">Mini Planner</p>
          <p className="mt-1 text-sm">Transfer to savings vault at 8:00 PM</p>
        </div>
        <div className="rounded-2xl border border-border bg-card p-4 shadow-card">
          <p className="text-xs uppercase tracking-wide text-muted-foreground">Focus Tip</p>
          <p className="mt-1 text-sm">Pause one impulse purchase this week.</p>
        </div>
      </div>
      <BalanceOverview />
      <FinancialCharts />
      <SavingsProgress />
      <InsightBox />
      <TransactionFeed />
      <FeatureShowcase theme="soft-bloom" />
    </main>
  </div>
  );
};
