import { useEffect, useMemo, useState } from "react";
import { AlertTriangle, CalendarDays, ChevronRight, ShieldCheck } from "lucide-react";
import { useFinance } from "@/contexts/FinanceContext";
import { useCurrency } from "@/contexts/CurrencyContext";
import { Button } from "@/components/ui/button";

type Region = "India" | "Russia";

interface CalendarEvent {
  id: string;
  name: string;
  type: string;
  start: Date;
  end: Date;
  note: string;
}

const dateFor = (month: number, day: number, durationDays = 0) => {
  const now = new Date();
  const currentYear = now.getFullYear();
  const candidate = new Date(currentYear, month - 1, day);
  if (candidate.getTime() < new Date(now.getFullYear(), now.getMonth(), now.getDate() - 7).getTime()) candidate.setFullYear(currentYear + 1);
  const end = new Date(candidate);
  end.setDate(end.getDate() + durationDays);
  return { start: candidate, end };
};

const eventData = (region: Region): CalendarEvent[] => {
  if (region === "Russia") {
    const winter = dateFor(1, 10, 18);
    const newYear = dateFor(12, 29, 9);
    const stipend = dateFor(8, 5, 0);
    return [
      { id: "ru-winter", name: "Winter exam season", type: "Academic", ...winter, note: "Study materials, transport, and late-night food often rise." },
      { id: "ru-new-year", name: "New Year holidays", type: "Holiday", ...newYear, note: "Gifting, travel, and social spending cluster around this break." },
      { id: "ru-stipend", name: "Student stipend cycle", type: "Income", ...stipend, note: "A regular stipend date to anchor your monthly plan." },
    ];
  }

  const exams = dateFor(7, 18, 8);
  const diwali = dateFor(11, 7, 5);
  const semester = dateFor(8, 1, 13);
  return [
    { id: "in-exams", name: "University exam window", type: "Academic", ...exams, note: "Printing, travel, and convenience food can increase during exam weeks." },
    { id: "in-diwali", name: "Diwali cluster", type: "Festival", ...diwali, note: "Gifts, travel, and celebrations can put pressure on flexible cash." },
    { id: "in-semester", name: "Semester reset", type: "Student costs", ...semester, note: "Books, supplies, and housing deposits often return at the start of term." },
  ];
};

const daysUntil = (date: Date) => Math.ceil((new Date(date.getFullYear(), date.getMonth(), date.getDate()).getTime() - new Date(new Date().getFullYear(), new Date().getMonth(), new Date().getDate()).getTime()) / 86_400_000);

export const EventCalendar = () => {
  const { transactions } = useFinance();
  const { formatFromUSD } = useCurrency();
  const [region, setRegion] = useState<Region>(() => (localStorage.getItem("cash-compass-region") as Region) || "India");
  const [marginAdjusted, setMarginAdjusted] = useState(false);
  const events = useMemo(() => eventData(region).sort((a, b) => a.start.getTime() - b.start.getTime()), [region]);

  useEffect(() => localStorage.setItem("cash-compass-region", region), [region]);

  const activeEvent = events.find((event) => {
    const days = daysUntil(event.start);
    return days >= 0 && days <= 7;
  });

  const forecast = useMemo(() => {
    const expenses = transactions.filter((transaction) => transaction.type === "expense");
    const average = expenses.length ? expenses.reduce((sum, transaction) => sum + transaction.amount, 0) / expenses.length : 0;
    const upcoming = activeEvent;
    if (!upcoming) return { usual: average, projected: average, increase: 0 };

    const eventWindowSpend = expenses.filter((transaction) => {
      const date = new Date(transaction.date);
      const monthDay = date.getMonth() * 31 + date.getDate();
      const startMonthDay = upcoming.start.getMonth() * 31 + upcoming.start.getDate();
      const endMonthDay = upcoming.end.getMonth() * 31 + upcoming.end.getDate();
      return monthDay >= startMonthDay - 7 && monthDay <= endMonthDay;
    });
    const historicalAverage = eventWindowSpend.length
      ? eventWindowSpend.reduce((sum, transaction) => sum + transaction.amount, 0) / eventWindowSpend.length
      : average;
    const projected = historicalAverage * (eventWindowSpend.length ? 1.16 : 1.12);
    return { usual: historicalAverage, projected, increase: Math.max(0, projected - historicalAverage) };
  }, [activeEvent, transactions]);

  const formatDate = (date: Date) => new Intl.DateTimeFormat(undefined, { month: "short", day: "numeric" }).format(date);

  return (
    <section className="rounded-3xl border border-border bg-card/90 p-5 shadow-card">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div className="flex gap-3">
          <div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-primary/15 text-primary"><CalendarDays className="h-5 w-5" /></div>
          <div>
            <p className="font-semibold font-heading">Regional financial calendar</p>
            <p className="mt-0.5 text-sm text-muted-foreground">Events that can change your spending velocity.</p>
          </div>
        </div>
        <div className="flex rounded-full border border-border bg-secondary/40 p-1 text-xs">
          {(["India", "Russia"] as Region[]).map((option) => (
            <button key={option} type="button" onClick={() => setRegion(option)} className={`rounded-full px-3 py-1.5 font-medium transition-colors ${region === option ? "bg-card text-foreground shadow-sm" : "text-muted-foreground"}`}>{option}</button>
          ))}
        </div>
      </div>

      {activeEvent && (
        <div className="mt-5 rounded-2xl border border-primary/25 bg-primary/10 p-4">
          <div className="flex gap-3">
            <AlertTriangle className="mt-0.5 h-4 w-4 shrink-0 text-primary" />
            <div className="flex-1">
              <p className="text-sm font-semibold">{activeEvent.name} is coming soon</p>
              <p className="mt-1 text-sm leading-relaxed text-muted-foreground">You usually spend more during this time. Cash Compass is adjusting your dynamic safety margin by {formatFromUSD(forecast.increase, { maximumFractionDigits: 0 })} per active day.</p>
              <p className="mt-2 text-xs text-muted-foreground">Projected event-day spend: {formatFromUSD(forecast.projected, { maximumFractionDigits: 0 })}</p>
              <Button type="button" variant="secondary" size="sm" className="mt-3" onClick={() => setMarginAdjusted((value) => !value)}>
                <ShieldCheck className="mr-1.5 h-3.5 w-3.5" /> {marginAdjusted ? "Safety margin protected" : "Apply safety margin"}
              </Button>
            </div>
          </div>
        </div>
      )}

      <div className="mt-4 space-y-2">
        {events.map((event) => {
          const distance = daysUntil(event.start);
          return (
            <div key={event.id} className="flex items-center gap-3 rounded-2xl border border-border/80 bg-secondary/20 px-3 py-3">
              <div className="min-w-16 text-center"><p className="text-xs font-semibold">{formatDate(event.start)}</p><p className="text-[10px] uppercase tracking-wide text-muted-foreground">{event.type}</p></div>
              <div className="min-w-0 flex-1"><p className="text-sm font-medium">{event.name}</p><p className="truncate text-xs text-muted-foreground">{event.note}</p></div>
              <span className="whitespace-nowrap text-xs text-muted-foreground">{distance === 0 ? "Today" : `${distance}d`}</span><ChevronRight className="h-4 w-4 text-muted-foreground" />
            </div>
          );
        })}
      </div>
    </section>
  );
};
