import { BalanceOverview } from "@/components/BalanceOverview";
import { SavingsProgress } from "@/components/SavingsProgress";
import { TransactionFeed } from "@/components/TransactionFeed";
import { InsightBox } from "@/components/InsightBox";
import { FinancialCharts } from "@/components/FinancialCharts";

export const ClassicLinenLayout = () => (
  <div className="min-h-screen bg-background flex justify-center py-12 px-6">
    <div className="max-w-4xl w-full bg-card shadow-lg p-10 md:p-16 relative border border-border">
      {}
      <div className="absolute inset-0 opacity-[0.03] pointer-events-none bg-[url('https:
      
      <header className="text-center mb-16 space-y-4">
        <h1 className="font-heading text-5xl md:text-6xl text-primary border-b border-primary/20 pb-6 inline-block">
          The Ledger
        </h1>
        <div className="flex justify-center gap-8 text-xs uppercase tracking-widest text-muted-foreground pt-4">
          <span>March 2026</span>
          <span>•</span>
          <span>Vol. VII</span>
          <span>•</span>
          <span>Private Account</span>
        </div>
      </header>

      <div className="space-y-16">
        <section>
          <div className="flex flex-col items-center mb-10">
            <span className="text-[10px] uppercase tracking-[0.3em] text-muted-foreground mb-2">Statement Overview</span>
            <BalanceOverview />
          </div>
        </section>

        <section className="grid grid-cols-1 md:grid-cols-2 gap-12">
          <div className="space-y-4">
            <h3 className="font-heading text-lg border-b border-border pb-2 italic">Projections</h3>
            <SavingsProgress />
          </div>
          <div className="space-y-4">
            <h3 className="font-heading text-lg border-b border-border pb-2 italic">Analysis</h3>
            <InsightBox />
          </div>
        </section>

        <section className="space-y-8">
           <h3 className="font-heading text-xl text-center border-b border-border pb-4">Statistical Trends</h3>
           <FinancialCharts />
        </section>

        <section className="space-y-6">
          <h3 className="font-heading text-xl text-center border-b border-border pb-4">Log of Activities</h3>
          <TransactionFeed />
        </section>
      </div>

      <footer className="mt-20 pt-8 border-t border-border flex justify-between items-center text-[10px] tracking-widest text-muted-foreground">
        <span>CURATED CAPITAL | EST. 2024</span>
        <span className="italic">Page 01 of 01</span>
      </footer>
    </div>
  </div>
);
