import { BalanceOverview } from "@/components/BalanceOverview";
import { SavingsProgress } from "@/components/SavingsProgress";
import { TransactionFeed } from "@/components/TransactionFeed";
import { InsightBox } from "@/components/InsightBox";
import { FinancialCharts } from "@/components/FinancialCharts";
import { Heart, Star, Sparkles, Cloud } from "lucide-react";

export const KawaiiPastelLayout = () => (
  <div className="min-h-screen bg-background relative overflow-hidden">
    {}
    <div className="absolute top-10 left-10 text-primary/20 animate-bounce"><Cloud className="w-16 h-16 fill-current" /></div>
    <div className="absolute bottom-20 right-10 text-secondary/30 rotate-12"><Heart className="w-12 h-12 fill-current" /></div>
    <div className="absolute top-1/2 left-5 text-accent/20 -rotate-12"><Star className="w-10 h-10 fill-current" /></div>

    <div className="max-w-6xl mx-auto px-6 py-10 relative z-10">
      <header className="flex flex-col items-center mb-12 text-center">
        <div className="bg-white p-4 rounded-full shadow-card mb-4 border-4 border-primary/20">
          <Sparkles className="w-8 h-8 text-primary" />
        </div>
        <h1 className="font-heading text-4xl font-bold text-primary">Sweet Savings! 🎀</h1>
        <p className="text-muted-foreground mt-2">Let's grow your pocket garden together!</p>
      </header>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
        <div className="lg:col-span-8 space-y-8">
          <div className="bg-white p-8 rounded-[3rem] shadow-card border-2 border-primary/10">
            <BalanceOverview />
          </div>
          <FinancialCharts />
          <div className="bg-white p-8 rounded-[3rem] shadow-card border-2 border-secondary/20">
            <TransactionFeed />
          </div>
        </div>

        <div className="lg:col-span-4 space-y-8">
          <div className="bg-white p-8 rounded-[3rem] shadow-card border-2 border-accent/20">
            <SavingsProgress />
          </div>
          <div className="bg-white p-8 rounded-[3rem] shadow-card border-2 border-muted/30">
            <InsightBox />
          </div>
          <div className="bg-primary/10 p-6 rounded-[2rem] border-2 border-dashed border-primary/30 text-center">
             <p className="text-sm font-medium italic">"You're doing amazing! Keep sparkling! ✨"</p>
          </div>
        </div>
      </div>
    </div>
  </div>
);
