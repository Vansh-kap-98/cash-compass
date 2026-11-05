import type { RealtimeChannel } from "@supabase/supabase-js";

import { supabase } from "./supabaseClient";

/** One row of `public.transactions`. */
export interface CloudTransaction {
  id: string;
  amount: number;
  /** `'income'` or `'expense'`, matching the database check constraint. */
  type: "income" | "expense";
  occurred_on: string;
  category: string | null;
  note: string | null;
}

/**
 * Deliberately separate from `FinanceTransaction` in `FinanceContext`.
 *
 * That one is the local, offline-first record in localStorage, shaped by this
 * app's own history; this mirrors a Postgres row and nothing else. One type
 * answering to two schemas would hide the first mismatch rather than fail on
 * it.
 */
function toTransaction(row: Record<string, unknown>): CloudTransaction {
  return {
    id: String(row.id),
    // numeric(12,2) arrives as a string over the wire, not a number.
    amount: Number(row.amount ?? 0),
    type: row.type === "income" ? "income" : "expense",
    occurred_on: String(row.occurred_on ?? ""),
    category: (row.category as string | null) ?? null,
    note: (row.note as string | null) ?? null,
  };
}

/** Contribution to the balance: income adds, expense subtracts. */
export function signedAmount(t: CloudTransaction): number {
  return t.type === "income" ? t.amount : -t.amount;
}

/** Balance from rows already in hand — the same arithmetic the view performs. */
export function balanceOf(rows: CloudTransaction[]): number {
  return rows.reduce((sum, t) => sum + signedAmount(t), 0);
}

/**
 * Lists the signed-in user's transactions, newest first.
 *
 * No `user_id` filter anywhere in this file: row-level security scopes every
 * query to `auth.uid()` server-side. Filtering here as well would imply the
 * client is what enforces the boundary.
 */
export async function listTransactions(): Promise<CloudTransaction[]> {
  const { data, error } = await supabase
    .from("transactions")
    .select("*")
    .order("occurred_on", { ascending: false })
    .order("created_at", { ascending: false });

  if (error) throw error;
  return (data ?? []).map(toTransaction);
}

export interface NewTransaction {
  amount: number;
  type: "income" | "expense";
  category?: string;
  note?: string;
}

/**
 * Inserts a transaction.
 *
 * `user_id` is deliberately absent — the column defaults to `auth.uid()`, so
 * the server decides ownership and a tampered request cannot write onto
 * another account.
 */
export async function addTransaction(input: NewTransaction): Promise<void> {
  const { error } = await supabase.from("transactions").insert({
    amount: input.amount,
    type: input.type,
    ...(input.category ? { category: input.category } : {}),
    ...(input.note ? { note: input.note } : {}),
  });

  if (error) throw error;
}

/**
 * Reads the balance from the `public.balances` view.
 *
 * Returns 0 when the account has no rows: the view groups by `user_id`, so an
 * empty account has no row at all rather than a row of zero.
 */
export async function fetchBalance(): Promise<number> {
  const { data, error } = await supabase
    .from("balances")
    .select("balance")
    .maybeSingle();

  if (error) throw error;
  return data ? Number(data.balance ?? 0) : 0;
}

/**
 * Subscribes to inserts, updates and deletes on `public.transactions`.
 *
 * Realtime only forwards rows the subscriber may SELECT, so the RLS policy is
 * what keeps one account's rows out of another's channel — there is no
 * client-side filter to forget.
 *
 * Returns the channel. **The caller must unsubscribe on unmount**; a channel
 * left open survives the component, keeps firing into a dead callback and
 * leaks a socket per mount.
 */
export function subscribeToTransactions(
  onChange: () => void,
  onError?: (message: string) => void,
): RealtimeChannel {
  const channel = supabase
    .channel("public:transactions")
    .on(
      "postgres_changes",
      { event: "*", schema: "public", table: "transactions" },
      () => onChange(),
    )
    .subscribe((status) => {
      // Surfaced rather than swallowed: a channel that never opens looks
      // exactly like an account with no activity.
      if (status === "CHANNEL_ERROR" || status === "TIMED_OUT") {
        onError?.(`Live updates unavailable (${status}).`);
      }
    });

  return channel;
}
