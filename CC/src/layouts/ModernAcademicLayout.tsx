import { BalanceOverview } from "@/components/BalanceOverview";
import { SavingsProgress } from "@/components/SavingsProgress";
import { TransactionFeed } from "@/components/TransactionFeed";
import { InsightBox } from "@/components/InsightBox";
import { FinancialCharts } from "@/components/FinancialCharts";
import { FeatureShowcase } from "@/components/FeatureShowcase";
import { Cpu, ChevronRight, BellDot, ScanText, Binary } from "lucide-react";

const NeoPanel = ({ title, children }: { title: string; children: React.ReactNode }) => (
  <section className="border border-border bg-card p-4">
    <p className="mb-3 text-[10px] font-mono uppercase tracking-[0.18em] text-muted-foreground">{title}</p>
    {children}
  </section>
);

export const ModernAcademicLayout = () => (
  <div className="min-h-screen">
    {}
    <header className="border-b border-border bg-card sticky top-0 z-40">
      <div className="flex items-center justify-between px-6 h-12">
        <div className="flex items-center gap-3">
          <Cpu className="w-4 h-4 text-primary" />
          <span className="font-heading text-sm font-semibold uppercase tracking-wider">
            Curated.sys
          </span>
          <ChevronRight className="w-3 h-3 text-muted-foreground" />
          <span className="text-xs text-muted-foreground font-mono">dashboard</span>
        </div>
      </div>
    </header>

    {}
    <main className="p-4 grid grid-cols-12 gap-4">
      <div className="col-span-12 lg:col-span-5 space-y-4">
        <NeoPanel title="Live Widgets">
          <div className="grid grid-cols-2 gap-3 text-xs">
            <div className="border border-border p-2">
              <p className="flex items-center gap-1.5 text-muted-foreground"><BellDot className="h-3.5 w-3.5 text-primary" /> Alerts</p>
              <p className="mt-1 font-mono">03</p>
            </div>
            <div className="border border-border p-2">
              <p className="flex items-center gap-1.5 text-muted-foreground"><ScanText className="h-3.5 w-3.5 text-primary" /> OCR Queue</p>
              <p className="mt-1 font-mono">07</p>
            </div>
          </div>
        </NeoPanel>
        <BalanceOverview />
        <FinancialCharts />
      </div>
      <div className="col-span-12 lg:col-span-7">
        <SavingsProgress />
      </div>
      <div className="col-span-12 lg:col-span-7">
        <TransactionFeed />
      </div>
      <div className="col-span-12 lg:col-span-5 space-y-4">
        <InsightBox />
        <NeoPanel title="Compile Notes">
          <div className="space-y-2 text-xs">
            <p className="flex items-center gap-1.5 text-muted-foreground"><Binary className="h-3.5 w-3.5 text-primary" /> Target savings hit-rate: 83%</p>
            <p className="text-muted-foreground">Spending anomaly at dining category, +11% WoW.</p>
          </div>
        </NeoPanel>
      </div>

      <div className="col-span-12">
        <FeatureShowcase theme="modern-academic" />
      </div>
    </main>
  </div>
);
