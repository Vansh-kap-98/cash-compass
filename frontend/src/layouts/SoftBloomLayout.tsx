
import { DashboardPlanner } from "@/components/DashboardPlanner";
import { GoalsInsights } from "@/components/GoalsInsights";
import { WorkspaceCanvas } from "@/components/WorkspaceCanvas";
import { SettingsStudio } from "@/components/SettingsStudio";
import { ThemeToggle } from "@/components/ThemeToggle";
import { EventCalendar } from "@/components/widgets/EventCalendar";
import { SubscriptionTracker } from "@/components/widgets/SubscriptionTracker";
import { SocialBenchmarks } from "@/components/widgets/SocialBenchmarks";
import { SmartCards } from "@/components/insights/SmartCards";
import { SpendingPatternInsight } from "@/components/forms/ReasonTags";
import { useCurrency } from "@/contexts/CurrencyContext";
import { useFinance } from "@/contexts/FinanceContext";
import { useTheme } from "@/contexts/ThemeContext";
import { Wallet, Bell, CalendarClock, PiggyBank } from "lucide-react";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { useState, useMemo, useEffect } from "react";

const MS_PER_DAY = 24 * 60 * 60 * 1000;

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

  // Local input state for balance to avoid fighting formatting while typing
  const [balanceInput, setBalanceInput] = useState<string>(
    manualBalance === null ? "" : String(convertFromUSD(manualBalance)),
  );

  useEffect(() => {
    setBalanceInput(manualBalance === null ? "" : String(convertFromUSD(manualBalance)));
  }, [manualBalance, convertFromUSD]);

  const todayIso = new Date().toISOString().slice(0, 10);
  const defaultEndIso = new Date(Date.now() + 7 * MS_PER_DAY).toISOString().slice(0, 10);
  const RANGE_KEY = "cash-compass-range-v1";

  const readSavedRange = () => {
    try {
      const raw = localStorage.getItem(RANGE_KEY);
      if (!raw) return { start: todayIso, end: defaultEndIso };
      const parsed = JSON.parse(raw);
      if (parsed?.start && parsed?.end) return { start: parsed.start, end: parsed.end };
      return { start: todayIso, end: defaultEndIso };
    } catch {
      return { start: todayIso, end: defaultEndIso };
    }
  };

  const saved = readSavedRange();
  const [startIso, setStartIso] = useState<string>(saved.start);
  const [endIso, setEndIso] = useState<string>(saved.end);

  const formatIsoToDisplay = (iso: string) => {
    try {
      const d = new Date(iso);
      if (isNaN(d.getTime())) return "";
      const day = String(d.getDate()).padStart(2, "0");
      const month = String(d.getMonth() + 1).padStart(2, "0");
      const year = String(d.getFullYear());
      return `${day}/${month}/${year}`;
    } catch {
      return "";
    }
  };

  const parseToIso = (value: string): string | null => {
    const v = value.trim();
    if (!v) return null;
    // ISO yyyy-mm-dd
    const isoMatch = v.match(/^(\d{4})-(\d{2})-(\d{2})$/);
    if (isoMatch) {
      const d = new Date(v);
      if (!isNaN(d.getTime())) return v;
    }
    // dd/mm/yyyy or d/m/yyyy with / - or . separators
    const dm = v.match(/^(\d{1,2})[/.-](\d{1,2})[/.-](\d{2,4})$/);
    if (dm) {
      const day = Number(dm[1]);
      const month = Number(dm[2]);
      let year = Number(dm[3]);
      if (year < 100) year += year >= 70 ? 1900 : 2000;
      const js = new Date(year, month - 1, day);
      if (js && js.getFullYear() === year && js.getMonth() === month - 1 && js.getDate() === day) {
        return js.toISOString().slice(0, 10);
      }
    }
    return null;
  };

  const [startInput, setStartInput] = useState<string>(formatIsoToDisplay(startIso));
  const [endInput, setEndInput] = useState<string>(formatIsoToDisplay(endIso));

  useEffect(() => setStartInput(formatIsoToDisplay(startIso)), [startIso]);
  useEffect(() => setEndInput(formatIsoToDisplay(endIso)), [endIso]);
  useEffect(() => {
    try {
      localStorage.setItem(RANGE_KEY, JSON.stringify({ start: startIso, end: endIso }));
    } catch {
      return;
    }
  }, [startIso, endIso]);

  const days = useMemo(() => {
    try {
      const s = new Date(startIso);
      const e = new Date(endIso);
      const diff = Math.ceil((e.getTime() - s.getTime()) / MS_PER_DAY);
      return Math.max(1, diff);
    } catch {
      return 1;
    }
  }, [startIso, endIso]);

  const dailyBudgetUSD = manualBalance !== null ? manualBalance / days : null;

  return (
  <>
  <div className="flex min-h-screen">
    {}
    <aside className="hidden w-[280px] shrink-0 border-r border-border bg-secondary/30 p-6 lg:flex lg:flex-col lg:gap-6 lg:sticky lg:top-0 lg:h-screen lg:overflow-y-auto">
      <div className="flex items-center gap-2 mb-4">
        <div className="w-8 h-8 rounded-lg bg-primary flex items-center justify-center">
          <Wallet className="w-4 h-4 text-primary-foreground" />
        </div>
        <span className="font-heading font-semibold text-lg">cash-compass</span>
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
        <p className="italic">cash-compass.</p>
      </div>
    </aside>

    {}
    <main className="flex-1 px-4 py-6 sm:px-8 sm:py-8 max-w-5xl space-y-6">
      <div className="flex items-center gap-2 overflow-x-auto pr-14 lg:hidden">
        {[
          ["Dashboard", "Dashboard"],
          ["Goals", "Goals"],
          ["Workspace", "Workspace"],
          ["Settings", "Settings"],
        ].map(([label, tab]) => (
          <button
            key={tab}
            type="button"
            onClick={() => setActiveTab(tab as "Dashboard" | "Goals" | "Workspace" | "Settings")}
            className={`shrink-0 rounded-full px-3 py-1.5 text-xs font-medium transition-colors ${activeTab === tab ? "bg-primary text-primary-foreground" : "bg-card/80 text-muted-foreground border border-border"}`}
          >
            {label}
          </button>
        ))}
      </div>
      <h1 className="font-heading text-2xl font-bold">Good morning ✨</h1>
      {activeTab === "Dashboard" && <section data-tour="balance-summary" className="grid grid-cols-1 sm:grid-cols-4 gap-4 rounded-3xl border border-border bg-card/90 p-4 shadow-card items-end">
        <div className="space-y-2">
          <Label className="text-xs uppercase tracking-wide text-muted-foreground">Total balance</Label>
          <Input
            type="number"
            min="0"
            step="0.01"
            value={balanceInput}
            onChange={(e) => setBalanceInput(e.target.value)}
            onBlur={() => {
              if (balanceInput === "") {
                setManualSnapshot({ balance: null, incomeToDate: null, spentToday: null });
                return;
              }
              const parsed = Number(balanceInput || 0);
              updateSnapshot(Math.max(0, parsed || 0));
            }}
          />
        </div>
          <div className="space-y-2">
            <Label className="text-xs uppercase tracking-wide text-muted-foreground">Start date</Label>
            <Input
              type="text"
              placeholder="dd/mm/yyyy"
              value={startInput}
              onChange={(e) => setStartInput(e.target.value)}
              onBlur={() => {
                const parsed = parseToIso(startInput);
                if (parsed) setStartIso(parsed);
                else setStartInput(formatIsoToDisplay(startIso));
              }}
              onKeyDown={(e) => {
                if (e.key === "Enter") (e.target as HTMLInputElement).blur();
              }}
            />
          </div>
          <div className="space-y-2">
            <Label className="text-xs uppercase tracking-wide text-muted-foreground">End date</Label>
            <Input
              type="text"
              placeholder="dd/mm/yyyy"
              value={endInput}
              onChange={(e) => setEndInput(e.target.value)}
              onBlur={() => {
                const parsed = parseToIso(endInput);
                if (parsed) setEndIso(parsed);
                else setEndInput(formatIsoToDisplay(endIso));
              }}
              onKeyDown={(e) => {
                if (e.key === "Enter") (e.target as HTMLInputElement).blur();
              }}
            />
          </div>

          <div className="space-y-2">
            <Label className="text-xs uppercase tracking-wide text-muted-foreground">Daily budget</Label>
            <div className="text-sm font-medium">{dailyBudgetUSD === null ? "—" : formatFromUSD(dailyBudgetUSD)}</div>
            <div className="text-xs text-muted-foreground">Spread over {days} day{days > 1 ? "s" : ""}</div>
          </div>
        <div className="flex flex-wrap items-center justify-between gap-3 rounded-2xl border border-dashed border-border bg-secondary/30 p-3 sm:col-span-4">
          <div className="space-y-1">
            <p className="text-sm font-medium">Snapshot drives the whole page</p>
            <p className="text-xs text-muted-foreground">Planner and dashboard calculations now use this total balance plus your expense entries only.</p>
          </div>
          <Button
            type="button"
            variant="secondary"
            onClick={() => {
              if (balanceInput === "") {
                setManualSnapshot({ balance: null, incomeToDate: null, spentToday: null });
                return;
              }
              const parsed = Number(balanceInput || 0);
              updateSnapshot(Math.max(0, parsed || 0));
            }}
          >
            Save snapshot
          </Button>
        </div>
      </section>}

      {activeTab === "Dashboard" && <>
        <DashboardPlanner />
        <section className="grid grid-cols-1 gap-4 xl:grid-cols-2">
          <EventCalendar />
          <SubscriptionTracker />
        </section>
        <SmartCards dailyLimit={dailyBudgetUSD} />
        <SpendingPatternInsight />
        <SocialBenchmarks />
      </>}
      {activeTab === "Goals" && <GoalsInsights />}
      {activeTab === "Workspace" && <WorkspaceCanvas />}
      {activeTab === "Settings" && <SettingsStudio />}

      {activeTab !== "Settings" && null /* FeatureShowcase removed */}
    </main>
  </div>
  <ThemeToggle />
  </>
  );
};
