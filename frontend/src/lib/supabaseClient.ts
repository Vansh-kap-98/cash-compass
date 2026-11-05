import { createClient, type SupabaseClient } from "@supabase/supabase-js";

export interface Database {
  public: {
    Tables: {
      // Mirrors supabase/migrations/0001_transactions.sql + 0003_account_data.sql.
      // Hand-written rather than generated, so it has to be updated alongside
      // those files — a drift here shows up as a type error, not as a runtime
      // surprise.
      //
      // Note on `user_id`: it is present on every Row and absent from every
      // Insert. The column defaults to auth.uid(), and the type is what stops
      // a client from sending its own.
      transactions: {
        Row: {
          id: string;
          user_id: string;
          amount: number;
          type: "income" | "expense";
          category: string | null;
          note: string | null;
          occurred_on: string;
          created_at: string;
          name: string;
          icon: string | null;
          is_unplanned: boolean;
          reason_tags: string[];
        };
        Insert: {
          amount: number;
          type: "income" | "expense";
          category?: string | null;
          note?: string | null;
          occurred_on?: string;
          name?: string;
          icon?: string | null;
          is_unplanned?: boolean;
          reason_tags?: string[];
        };
        Update: {
          amount?: number;
          type?: "income" | "expense";
          category?: string | null;
          note?: string | null;
          occurred_on?: string;
          name?: string;
          icon?: string | null;
          is_unplanned?: boolean;
          reason_tags?: string[];
        };
        Relationships: [];
      };
      goals: {
        Row: {
          id: string;
          user_id: string;
          name: string;
          target: number;
          current: number;
          icon: string;
          created_at: string;
        };
        Insert: {
          name: string;
          target: number;
          current?: number;
          icon?: string;
        };
        Update: {
          name?: string;
          target?: number;
          current?: number;
          icon?: string;
        };
        Relationships: [];
      };
      budgets: {
        Row: {
          id: string;
          user_id: string;
          name: string;
          monthly_limit: number;
          created_at: string;
        };
        Insert: {
          name: string;
          monthly_limit: number;
        };
        Update: {
          name?: string;
          monthly_limit?: number;
        };
        Relationships: [];
      };
      // One row per user: `user_id` is the primary key, not a surrogate id.
      // It is therefore writable on insert (as the conflict target for an
      // upsert) unlike the other tables here.
      finance_settings: {
        Row: {
          user_id: string;
          starting_balance: number;
          manual_balance: number | null;
          manual_income_to_date: number | null;
          manual_spent_today: number | null;
          updated_at: string;
        };
        Insert: {
          user_id?: string;
          starting_balance?: number;
          manual_balance?: number | null;
          manual_income_to_date?: number | null;
          manual_spent_today?: number | null;
        };
        Update: {
          starting_balance?: number;
          manual_balance?: number | null;
          manual_income_to_date?: number | null;
          manual_spent_today?: number | null;
        };
        Relationships: [];
      };
    };
    Views: {
      balances: {
        Row: {
          user_id: string;
          balance: number;
        };
        Relationships: [];
      };
    };
    Functions: Record<string, never>;
  };
}

const env = import.meta.env;
// `process` does not exist in a Vite browser build and @types/node is not
// installed, so naming it directly does not type-check even behind a `typeof`
// guard. Reaching through globalThis keeps the same runtime behaviour — the
// NEXT_PUBLIC_* fallbacks still resolve if this is ever run under Node — while
// #akshitsaini
// staying honest that the browser bundle has no process object.
const processEnv = (globalThis as { process?: { env?: Record<string, string | undefined> } }).process
  ?.env;

// #kintanjain
const supabaseUrl =
  env.VITE_SUPABASE_URL ?? env.NEXT_PUBLIC_SUPABASE_URL ?? processEnv?.NEXT_PUBLIC_SUPABASE_URL ?? processEnv?.VITE_SUPABASE_URL;

const supabaseAnonKey =
  env.VITE_SUPABASE_ANON_KEY ??
  env.NEXT_PUBLIC_SUPABASE_ANON_KEY ??
  processEnv?.NEXT_PUBLIC_SUPABASE_ANON_KEY ??
  processEnv?.VITE_SUPABASE_ANON_KEY;

export const isSupabaseConfigured = Boolean(supabaseUrl && supabaseAnonKey);

const fallbackUrl = "https://example.supabase.co";
const fallbackAnonKey = "public-anon-key";

if (!isSupabaseConfigured) {
  // Keep the app bootable so the misconfiguration surfaces in the console
  // and on the login screen, rather than as a white screen at import time.
  console.warn("Supabase environment variables are missing. Login and signup will be unavailable until configured.");
}

export const supabase: SupabaseClient<Database> = createClient<Database>(supabaseUrl ?? fallbackUrl, supabaseAnonKey ?? fallbackAnonKey, {
  auth: {
    autoRefreshToken: true,
    persistSession: true,
    detectSessionInUrl: true,
    flowType: "pkce",
  },
});