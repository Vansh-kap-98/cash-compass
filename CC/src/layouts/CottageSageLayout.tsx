import { BalanceOverview } from "@/components/BalanceOverview";
import { SavingsProgress } from "@/components/SavingsProgress";
import { TransactionFeed } from "@/components/TransactionFeed";
import { InsightBox } from "@/components/InsightBox";
import { FinancialCharts } from "@/components/FinancialCharts";
import { Leaf } from "lucide-react";

export const CottageSageLayout = () => (
  <div className="min-h-screen p-6 md:p-10">
    {}
    <header className="flex items-center justify-between mb-8">
      <div className="flex items-center gap-2">
        <Leaf className="w-5 h-5 text-primary" />
        <h1 className="font-heading text-xl font-bold">Curated</h1>
      </div>
    </header>

    {}
    <div
      className="grid gap-6"
      style={{
        gridTemplateColumns: "1fr 1fr 1fr",
        gridTemplateRows: "auto auto",
        gridTemplateAreas: `"bal bal goal" "feed insight insight"`,
      }}
    >
      <div style={{ gridArea: "bal" }}>
        <BalanceOverview />
        <div className="mt-6">
          <FinancialCharts />
        </div>
      </div>
      <div style={{ gridArea: "goal" }}>
        <SavingsProgress />
      </div>
      <div style={{ gridArea: "feed" }}>
        <TransactionFeed />
      </div>
      <div style={{ gridArea: "insight" }}>
        <InsightBox />
      </div>
    </div>
  </div>
);
