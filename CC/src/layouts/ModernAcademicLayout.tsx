import { BalanceOverview } from "@/components/BalanceOverview";
import { SavingsProgress } from "@/components/SavingsProgress";
import { TransactionFeed } from "@/components/TransactionFeed";
import { InsightBox } from "@/components/InsightBox";
import { FinancialCharts } from "@/components/FinancialCharts";
import { Cpu, ChevronRight } from "lucide-react";

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
      <div className="col-span-5">
        <BalanceOverview />
        <div className="mt-4">
          <FinancialCharts />
        </div>
      </div>
      <div className="col-span-7">
        <SavingsProgress />
      </div>
      <div className="col-span-7">
        <TransactionFeed />
      </div>
      <div className="col-span-5">
        <InsightBox />
      </div>
    </main>
  </div>
);
