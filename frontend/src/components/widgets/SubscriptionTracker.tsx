import { useEffect, useMemo, useState } from "react";
import { BadgeCheck, CreditCard, LockKeyhole, RotateCcw } from "lucide-react";
import { useFinance, type FinanceTransaction } from "@/contexts/FinanceContext";
import { useCurrency } from "@/contexts/CurrencyContext";
import { Button } from "@/components/ui/button";

interface RecurringCandidate { merchant: string; amount: number; cadence: number; transactions: FinanceTransaction[]; }
interface Liability { id: string; name: string; amount: number; }

const previewRecurringCharges = (): FinanceTransaction[] => {
  const today = new Date();
  return [0, 30, 60].map((daysAgo, index) => {
    const date = new Date(today);
    date.setDate(date.getDate() - daysAgo);
    return { id: `preview-spotify-${index}`, name: "Spotify", amount: 2.5, type: "expense", category: "Entertainment", date: date.toISOString().slice(0, 10) };
  });
};

const merchantSignature = (name: string) => name.toLowerCase().replace(/\d|[^a-zа-я]/gi, "").replace(/(payment|subscription|monthly)/g, "").trim();

const detectRecurringCharges = (transactions: FinanceTransaction[]): RecurringCandidate[] => {
  const groups = new Map<string, FinanceTransaction[]>();
  transactions.filter((transaction) => transaction.type === "expense").forEach((transaction) => {
    const signature = merchantSignature(transaction.name);
    if (!signature) return;
    groups.set(signature, [...(groups.get(signature) ?? []), transaction]);
  });

  return [...groups.entries()].flatMap(([merchant, entries]) => {
    const sorted = [...entries].sort((a, b) => new Date(a.date).getTime() - new Date(b.date).getTime());
    if (sorted.length < 2) return [];
    const intervals = sorted.slice(1).map((transaction, index) => Math.round((new Date(transaction.date).getTime() - new Date(sorted[index].date).getTime()) / 86_400_000));
    const monthlyIntervals = intervals.filter((interval) => interval >= 27 && interval <= 33);
    const average = sorted.reduce((sum, transaction) => sum + transaction.amount, 0) / sorted.length;
    const amountsConsistent = sorted.every((transaction) => Math.abs(transaction.amount - average) <= Math.max(1, average * 0.15));
    return monthlyIntervals.length && amountsConsistent ? [{ merchant, amount: average, cadence: Math.round(monthlyIntervals.reduce((sum, interval) => sum + interval, 0) / monthlyIntervals.length), transactions: sorted }] : [];
  });
};

const LIABILITIES_KEY = "cash-compass-fixed-liabilities-v1";

export const SubscriptionTracker = () => {
  const { transactions } = useFinance();
  const { formatFromUSD } = useCurrency();
  const [liabilities, setLiabilities] = useState<Liability[]>(() => {
    try { return JSON.parse(localStorage.getItem(LIABILITIES_KEY) ?? "[]") as Liability[]; } catch { return []; }
  });
  const sourceTransactions = transactions.length ? transactions : previewRecurringCharges();
  const candidates = useMemo(() => detectRecurringCharges(sourceTransactions), [sourceTransactions]);

  useEffect(() => localStorage.setItem(LIABILITIES_KEY, JSON.stringify(liabilities)), [liabilities]);

  const protect = (candidate: RecurringCandidate) => {
    if (liabilities.some((item) => item.name === candidate.merchant)) return;
    setLiabilities((current) => [...current, { id: `liability-${Date.now()}`, name: candidate.merchant, amount: candidate.amount }]);
  };

  return (
    <section className="rounded-3xl border border-border bg-card/90 p-5 shadow-card">
      <div className="flex gap-3"><div className="flex h-10 w-10 items-center justify-center rounded-2xl bg-primary/15 text-primary"><CreditCard className="h-5 w-5" /></div><div><p className="font-semibold font-heading">Fixed liabilities</p><p className="mt-0.5 text-sm text-muted-foreground">A quiet audit of repeating monthly charges.</p></div></div>

      {candidates.map((candidate) => (
        <div key={candidate.merchant} className="mt-4 rounded-2xl border border-primary/25 bg-primary/10 p-4">
          <div className="flex items-start justify-between gap-3"><div><p className="text-sm font-semibold">We detected a recurring charge</p><p className="mt-1 text-sm text-muted-foreground">{candidate.merchant} appears every {candidate.cadence} days at about {formatFromUSD(candidate.amount)}.</p></div><RotateCcw className="h-4 w-4 shrink-0 text-primary" /></div>
          <Button type="button" size="sm" className="mt-3" onClick={() => protect(candidate)} disabled={liabilities.some((item) => item.name === candidate.merchant)}><LockKeyhole className="mr-1.5 h-3.5 w-3.5" />{liabilities.some((item) => item.name === candidate.merchant) ? "Protected" : "Add to fixed liabilities"}</Button>
        </div>
      ))}

      {!transactions.length && <p className="mt-3 text-xs text-muted-foreground">Showing a sample signal until you add transactions. Detection then uses only your local entries.</p>}
      <div className="mt-4 space-y-2">
        {liabilities.map((item) => <div key={item.id} className="flex items-center justify-between rounded-2xl border border-border px-3 py-2.5 text-sm"><span className="flex items-center gap-2"><BadgeCheck className="h-4 w-4 text-primary" />{item.name}</span><span className="font-semibold">{formatFromUSD(item.amount)}</span></div>)}
        {!liabilities.length && !candidates.length && <p className="text-sm text-muted-foreground">No repeating monthly charges found yet.</p>}
      </div>
    </section>
  );
};
