import { BalanceOverview } from "@/components/BalanceOverview";
import { SavingsProgress } from "@/components/SavingsProgress";
import { TransactionFeed } from "@/components/TransactionFeed";
import { InsightBox } from "@/components/InsightBox";
import { FinancialCharts } from "@/components/FinancialCharts";
import { FeatureShowcase } from "@/components/FeatureShowcase";
import { useCurrency } from "@/contexts/CurrencyContext";
import { Heart, Star, Sparkles, Cloud, Bell, CalendarDays, PiggyBank } from "lucide-react";

const KawaiiWidget = ({ title, children }: { title: string; children: React.ReactNode }) => (
  <div className="rounded-[1.5rem] border-2 border-primary/20 bg-white/95 p-4 shadow-card">
    <p className="mb-2 text-[11px] font-medium uppercase tracking-[0.12em] text-primary">{title}</p>
    {children}
  </div>
);

export const KawaiiPastelLayout = () => {
  const { formatFromUSD } = useCurrency();

  return (
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

      <section className="mb-8 grid grid-cols-1 gap-4 sm:grid-cols-3">
        <KawaiiWidget title="Today's Sparkle">
          <p className="text-sm text-muted-foreground">You stayed under your snack budget today.</p>
        </KawaiiWidget>
        <KawaiiWidget title="Reminder">
          <p className="flex items-center gap-2 text-sm text-muted-foreground"><Bell className="h-4 w-4 text-primary" /> Card payment in 2 days</p>
        </KawaiiWidget>
        <KawaiiWidget title="Mini Goal">
          <p className="flex items-center gap-2 text-sm text-muted-foreground"><PiggyBank className="h-4 w-4 text-primary" /> Save {formatFromUSD(40, { maximumFractionDigits: 0 })} this weekend</p>
        </KawaiiWidget>
      </section>

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

      <section className="mt-8 grid grid-cols-1 gap-4 sm:grid-cols-4">
        {[
          { icon: CalendarDays, label: "Planner" },
          { icon: Bell, label: "Alerts" },
          { icon: Heart, label: "Mood" },
          { icon: Sparkles, label: "Boost" },
        ].map((item) => (
          <div key={item.label} className="rounded-[1.2rem] border-2 border-secondary/30 bg-white p-3 text-center shadow-card">
            <item.icon className="mx-auto mb-1 h-4 w-4 text-primary" />
            <p className="text-[11px] uppercase tracking-[0.12em] text-muted-foreground">{item.label}</p>
          </div>
        ))}
      </section>

      <div className="mt-8">
        <FeatureShowcase theme="kawaii-pastel" />
      </div>
    </div>
  </div>
  );
};
