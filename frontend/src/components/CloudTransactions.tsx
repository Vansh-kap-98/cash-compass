import { useCallback, useEffect, useRef, useState } from "react";
import { CloudOff, Plus, RefreshCw } from "lucide-react";
import type { RealtimeChannel } from "@supabase/supabase-js";

import { Button } from "@/components/ui/button";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { useCurrency } from "@/contexts/CurrencyContext";
import {
  addTransaction,
  balanceOf,
  listTransactions,
  subscribeToTransactions,
  type CloudTransaction,
} from "@/lib/transactionsRepository";

/**
 * The synced transaction list, backed by Supabase.
 *
 * Deliberately additive rather than a rewrite of the dashboard. The existing
 * dashboard is the offline-first product — localStorage, usable with no
 * account — and converting it to a network-backed view would be a large change
 * across a well-tested surface. This is the server-backed path; nothing else
 * depends on it.
 *
 * Live through a `postgres_changes` channel: a transaction added on the phone
 * appears here without a reload. The refresh button is the fallback for when
 * the socket is asleep.
 */
export const CloudTransactions = () => {
  const { formatFromUSD, convertToUSD, currency } = useCurrency();

  const [rows, setRows] = useState<CloudTransaction[] | null>(null); // null = loading
  const [error, setError] = useState<string | null>(null);
  const [liveWarning, setLiveWarning] = useState<string | null>(null);

  const load = useCallback(async () => {
    try {
      setRows(await listTransactions());
      setError(null);
    } catch (e) {
      // The real message, never a generic apology: an RLS denial reads very
      // differently from a missing table, and hiding that costs hours.
      const message = e instanceof Error ? e.message : String(e);
      setError(message);
      if (import.meta.env.DEV) console.error("listTransactions failed", e);
    }
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  // One channel for the lifetime of the mount, torn down on unmount. Held in a
  // ref so a re-render cannot open a second one.
  const channelRef = useRef<RealtimeChannel | null>(null);
  useEffect(() => {
    channelRef.current = subscribeToTransactions(
      () => void load(),
      (message) => setLiveWarning(message),
    );

    return () => {
      if (channelRef.current) {
        void channelRef.current.unsubscribe();
        channelRef.current = null;
      }
    };
  }, [load]);

  const balance = rows ? balanceOf(rows) : 0;

  return (
    <section className="surface-outline rounded-3xl bg-card p-5">
      <header className="flex items-start justify-between gap-3">
        <div>
          <h2 className="font-heading font-semibold">Synced transactions</h2>
          <p className="mt-0.5 text-sm text-muted-foreground">
            Shared with the mobile app through your account.
          </p>
        </div>
        <Button
          type="button"
          variant="outline"
          size="sm"
          onClick={() => void load()}
          aria-label="Refresh"
        >
          <RefreshCw className="h-3.5 w-3.5" />
        </Button>
      </header>

      {error ? (
        <div className="surface-outline mt-4 rounded-2xl p-4">
          <p className="flex items-center gap-2 text-sm font-semibold">
            <CloudOff className="h-4 w-4" />
            Could not load transactions
          </p>
          <p className="mt-1 text-sm text-muted-foreground">{error}</p>
          <Button type="button" size="sm" className="mt-3" onClick={() => void load()}>
            Try again
          </Button>
        </div>
      ) : rows === null ? (
        <p className="mt-6 text-sm text-muted-foreground">Loading…</p>
      ) : (
        <>
          <div className="surface-outline mt-4 rounded-2xl bg-secondary p-4">
            <p className="text-xs uppercase tracking-wide text-muted-foreground">
              Balance
            </p>
            <p className="mt-1 text-3xl font-bold tabular-nums">
              {formatFromUSD(balance)}
            </p>
            <p className="mt-1 text-xs text-muted-foreground">
              Derived from {rows.length}{" "}
              {rows.length === 1 ? "transaction" : "transactions"}, live.
            </p>
          </div>

          {liveWarning && (
            <p className="mt-3 text-xs text-muted-foreground">
              {liveWarning} Use refresh to update.
            </p>
          )}

          <AddForm
            currencyCode={currency}
            convertToUSD={convertToUSD}
            onAdded={() => void load()}
          />

          <div className="mt-4 space-y-2">
            {rows.length === 0 ? (
              <p className="text-sm text-muted-foreground">
                Nothing yet. Add one here, or on the phone signed in to the same
                account — it will appear on both.
              </p>
            ) : (
              rows.map((t) => (
                <div
                  key={t.id}
                  className="surface-outline flex items-center justify-between rounded-2xl px-3 py-2.5 text-sm"
                >
                  <span className="min-w-0">
                    <span className="block truncate font-semibold">
                      {t.category || t.type}
                    </span>
                    <span className="block truncate text-xs text-muted-foreground">
                      {t.note || t.occurred_on}
                    </span>
                  </span>
                  <span className="shrink-0 font-semibold tabular-nums">
                    {t.type === "income" ? "+" : "−"}
                    {formatFromUSD(t.amount)}
                  </span>
                </div>
              ))
            )}
          </div>
        </>
      )}
    </section>
  );
};

const AddForm = ({
  currencyCode,
  convertToUSD,
  onAdded,
}: {
  currencyCode: string;
  convertToUSD: (amount: number) => number;
  onAdded: () => void;
}) => {
  const [amount, setAmount] = useState("");
  const [category, setCategory] = useState("");
  const [type, setType] = useState<"income" | "expense">("expense");
  const [saving, setSaving] = useState(false);
  const [formError, setFormError] = useState<string | null>(null);

  const submit = async (event: React.FormEvent) => {
    event.preventDefault();
    const typed = Number(amount);
    if (!Number.isFinite(typed) || typed <= 0) {
      setFormError("Enter an amount greater than zero.");
      return;
    }

    setSaving(true);
    setFormError(null);
    try {
      // Stored in USD like everything else — the table has no currency column,
      // so a figure typed in rupees must be converted before it is sent or the
      // two platforms will disagree.
      await addTransaction({
        amount: Number(convertToUSD(typed).toFixed(2)),
        type,
        category: category.trim(),
      });
      setAmount("");
      setCategory("");
      onAdded();
    } catch (e) {
      const message = e instanceof Error ? e.message : String(e);
      setFormError(message);
      if (import.meta.env.DEV) console.error("addTransaction failed", e);
    } finally {
      setSaving(false);
    }
  };

  return (
    <form onSubmit={submit} className="surface-outline mt-4 rounded-2xl p-4">
      <div className="flex flex-wrap items-end gap-3">
        <div className="min-w-[8rem] flex-1">
          <Label htmlFor="cloud-amount" className="text-xs">
            Amount ({currencyCode})
          </Label>
          <Input
            id="cloud-amount"
            inputMode="decimal"
            value={amount}
            onChange={(e) => setAmount(e.target.value)}
            placeholder="0.00"
          />
        </div>
        <div className="min-w-[8rem] flex-1">
          <Label htmlFor="cloud-category" className="text-xs">
            Category
          </Label>
          <Input
            id="cloud-category"
            value={category}
            onChange={(e) => setCategory(e.target.value)}
            placeholder="Groceries"
          />
        </div>
        <div className="flex gap-2">
          <Button
            type="button"
            variant={type === "expense" ? "default" : "outline"}
            size="sm"
            onClick={() => setType("expense")}
          >
            Expense
          </Button>
          <Button
            type="button"
            variant={type === "income" ? "default" : "outline"}
            size="sm"
            onClick={() => setType("income")}
          >
            Income
          </Button>
        </div>
        <Button type="submit" size="sm" disabled={saving}>
          <Plus className="mr-1 h-3.5 w-3.5" />
          {saving ? "Saving…" : "Add"}
        </Button>
      </div>
      {formError && (
        <p className="mt-2 text-sm text-destructive">{formError}</p>
      )}
    </form>
  );
};
