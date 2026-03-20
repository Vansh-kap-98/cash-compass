import { BalanceOverview } from "@/components/BalanceOverview";
import { SavingsProgress } from "@/components/SavingsProgress";
import { TransactionFeed } from "@/components/TransactionFeed";
import { InsightBox } from "@/components/InsightBox";
import { FinancialCharts } from "@/components/FinancialCharts";
import { Leaf, BookHeart, BellRing } from "lucide-react";

const SageWidget = ({ title, children }: { title: string; children: React.ReactNode }) => (
  <article className="organic-radius paper-texture relative overflow-hidden border border-border bg-card p-4 shadow-card">
    <p className="mb-2 text-[11px] uppercase tracking-[0.16em] text-muted-foreground">{title}</p>
    {children}
  </article>
);

export const CottageSageLayout = () => (
  <div className="min-h-screen p-6 md:p-10">
    {}
    <header className="flex items-center justify-between mb-8">
      <div className="flex items-center gap-2">
        <Leaf className="w-5 h-5 text-primary" />
        <h1 className="font-heading text-xl font-bold">Curated</h1>
      </div>
    </header>

    <section className="mb-6 grid grid-cols-1 gap-4 md:grid-cols-3">
      <SageWidget title="Garden Note">
        <p className="text-sm text-muted-foreground">Slow and steady deposits are compounding beautifully.</p>
      </SageWidget>
      <SageWidget title="Upcoming">
        <div className="flex items-center justify-between text-sm">
          <span className="flex items-center gap-2 text-muted-foreground"><BellRing className="h-4 w-4 text-primary" /> Mortgage due</span>
          <span>3d</span>
        </div>
      </SageWidget>
      <SageWidget title="Reading">
        <p className="flex items-center gap-2 text-sm text-muted-foreground"><BookHeart className="h-4 w-4 text-primary" /> Weekly money journal</p>
      </SageWidget>
    </section>

    {}
    <div
      className="grid gap-6"
      style={{
        gridTemplateColumns: "repeat(auto-fit, minmax(280px, 1fr))",
      }}
    >
      <div className="md:col-span-2">
        <BalanceOverview />
        <div className="mt-6">
          <FinancialCharts />
        </div>
      </div>
      <div>
        <SavingsProgress />
      </div>
      <div>
        <TransactionFeed />
      </div>
      <div className="md:col-span-2">
        <InsightBox />
      </div>
    </div>
  </div>
);
