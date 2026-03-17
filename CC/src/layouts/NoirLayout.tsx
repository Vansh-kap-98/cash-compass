import { BalanceOverview } from "@/components/BalanceOverview";
import { SavingsProgress } from "@/components/SavingsProgress";
import { TransactionFeed } from "@/components/TransactionFeed";
import { InsightBox } from "@/components/InsightBox";
import { FinancialCharts } from "@/components/FinancialCharts";

export const NoirLayout = () => (
  <div className="min-h-screen">
    {}
    <header className="border-b border-foreground/10">
      <div className="max-w-[800px] mx-auto px-6 py-6 flex items-center justify-between">
        <h1 className="font-heading text-xl font-bold uppercase tracking-[0.2em]">
          Curated Capital
        </h1>
      </div>
    </header>

    {}
    <div className="max-w-[800px] mx-auto px-6 pt-8 pb-2">
      <div
        className="w-full h-32 bg-foreground/5 noir-border flex items-center justify-center"
        style={{ clipPath: "ellipse(100% 100% at 50% 0%)" }}
      >
        <p className="font-heading text-lg italic text-muted-foreground">
          "Your financial landscape, curated."
        </p>
      </div>
    </div>

    {}
    <main className="max-w-[800px] mx-auto px-6 py-8 space-y-6">
      <BalanceOverview />
      <FinancialCharts />
      <div className="grid grid-cols-2 gap-6">
        <SavingsProgress />
        <InsightBox />
      </div>
      <TransactionFeed />
    </main>
  </div>
);
