import { BalanceOverview } from "@/components/BalanceOverview";
import { SavingsProgress } from "@/components/SavingsProgress";
import { TransactionFeed } from "@/components/TransactionFeed";
import { InsightBox } from "@/components/InsightBox";
import { FinancialCharts } from "@/components/FinancialCharts";
import { Wallet } from "lucide-react";

export const SoftBloomLayout = () => (
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

      <div className="mt-auto text-xs text-muted-foreground">
        <p className="font-heading font-medium">Your financial landscape,</p>
        <p className="italic">curated.</p>
      </div>
    </aside>

    {}
    <main className="flex-1 px-12 py-8 max-w-3xl space-y-6">
      <h1 className="font-heading text-2xl font-bold">Good morning ✨</h1>
      <BalanceOverview />
      <FinancialCharts />
      <SavingsProgress />
      <InsightBox />
      <TransactionFeed />
    </main>
  </div>
);
