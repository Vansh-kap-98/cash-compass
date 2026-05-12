import { FeatureShowcase } from "@/components/FeatureShowcase";
import { DashboardPlanner } from "@/components/DashboardPlanner";
import { GoalsInsights } from "@/components/GoalsInsights";
import { WorkspaceCanvas } from "@/components/WorkspaceCanvas";
import { SettingsStudio } from "@/components/SettingsStudio";
import { useCurrency } from "@/contexts/CurrencyContext";
import { useFinance } from "@/contexts/FinanceContext";
import { useTheme } from "@/contexts/ThemeContext";
import { Wallet, Bell, CalendarClock, PiggyBank } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { useState } from "react";

const SoftWidget = ({ title, children }: { title: string; children: React.ReactNode }) => (
  <div className="rounded-2xl border border-border bg-card/80 p-3 shadow-card">
    <p className="mb-2 text-[11px] font-medium uppercase tracking-wide text-muted-foreground">{title}</p>
    {children}
  </div>
);

export const SoftBloomLayout = () => {
  const { theme } = useTheme();
  const { formatFromUSD, convertToUSD, convertFromUSD } = useCurrency();
  const { manualBalance, setManualSnapshot } = useFinance();
  const [activeTab, setActiveTab] = useState<"Dashboard" | "Goals" | "Workspace" | "Settings">("Dashboard");

  const updateSnapshot = (value: number) => {
    setManualSnapshot({
      balance: convertToUSD(value),
      incomeToDate: null,
      spentToday: null,
    });
  };

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
        {["Dashboard", "Goals", "Workspace", "Settings"].map((item) => (
          <div
            key={item}
            onClick={() => setActiveTab(item as "Dashboard" | "Goals" | "Workspace" | "Settings")}
            className={`px-3 py-2 rounded-lg cursor-pointer transition-colors ${
              activeTab === item ? "bg-primary text-primary-foreground" : "text-muted-foreground hover:bg-accent"
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
    <main className="flex-1 px-8 py-8 max-w-5xl space-y-6">
      <h1 className="font-heading text-2xl font-bold">Good morning ✨</h1>
      {activeTab === "Dashboard" && <section className="grid grid-cols-1 gap-4 rounded-3xl border border-border bg-card/90 p-4 shadow-card">
        <div className="space-y-2">
          <Label className="text-xs uppercase tracking-wide text-muted-foreground">Total balance</Label>
          <Input
            type="number"
            min="0"
            step="0.01"
            value={manualBalance === null ? "" : convertFromUSD(manualBalance)}
            onChange={(e) => (e.target.value === "" ? setManualSnapshot({ balance: null, incomeToDate: null, spentToday: null }) : updateSnapshot(Math.max(0, Number(e.target.value) || 0)))}
          />
        </div>
        <div className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-dashed border-border bg-secondary/30 p-3">
          <div className="space-y-1">
            <p className="text-sm font-medium">Snapshot drives the whole page</p>
            <p className="text-xs text-muted-foreground">Planner and dashboard calculations now use this total balance plus your expense entries only.</p>
          </div>
          <Button
            type="button"
            variant="secondary"
            onClick={() =>
              setManualSnapshot({
                  balance: manualBalance,
                  incomeToDate: null,
                  spentToday: null,
              })
            }
          >
            Save snapshot
          </Button>
        </div>
      </section>}

      {activeTab === "Dashboard" && <DashboardPlanner />}
      {activeTab === "Goals" && <GoalsInsights />}
      {activeTab === "Workspace" && <WorkspaceCanvas />}
      {activeTab === "Settings" && <SettingsStudio />}

      {activeTab !== "Settings" && <FeatureShowcase theme={theme} />}
    </main>
  </div>
  );
};
