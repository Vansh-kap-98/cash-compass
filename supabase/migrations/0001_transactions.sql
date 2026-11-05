-- Cash Compass — transactions table, RLS, realtime, derived balances view.
--
-- Paste into the Supabase SQL editor and run. Safe to run more than once.
--
-- The dashboard reported "No migrations", so this creates the table fresh.
-- If a `public.transactions` already existed this script would NOT adapt it —
-- it would fail on the create and leave your data untouched, which is the
-- intended behaviour. Tell me and I will write an ALTER-based migration
-- instead.

-- ---------------------------------------------------------------- table
create table if not exists public.transactions (
  id          uuid primary key default gen_random_uuid(),

  -- Defaulted from the session, so the client never sends it. Combined with
  -- the WITH CHECK below, a client cannot write a row onto another user even
  -- by crafting the request by hand.
  user_id     uuid not null default auth.uid()
                references auth.users(id) on delete cascade,

  -- Always positive. Direction lives in `type`, not in the sign — a negative
  -- amount with type 'income' would otherwise be a second way to express the
  -- same thing, and the view below would quietly disagree with the app.
  amount      numeric(12,2) not null check (amount > 0),
  type        text not null check (type in ('income','expense')),

  category    text,
  note        text,

  occurred_on date not null default current_date,
  created_at  timestamptz not null default now()
);

-- The list query is "mine, newest first". Without this it is a sequential
-- scan plus a sort on every load.
create index if not exists transactions_user_occurred_idx
  on public.transactions (user_id, occurred_on desc, created_at desc);

-- ------------------------------------------------------------------ RLS
alter table public.transactions enable row level security;

-- One policy covering all four verbs.
--   USING      -> which existing rows you may read, update or delete
--   WITH CHECK -> which new or edited rows you may write
-- Both are required. USING alone would let a user UPDATE one of their rows to
-- carry someone else's user_id, handing the row away.
drop policy if exists "Users manage their own transactions" on public.transactions;
create policy "Users manage their own transactions"
  on public.transactions
  for all
  to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ------------------------------------------------------------- realtime
-- Realtime only forwards rows the subscriber is allowed to SELECT, so the
-- policy above is what keeps one account's inserts out of another's stream.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime'
      and schemaname = 'public'
      and tablename = 'transactions'
  ) then
    alter publication supabase_realtime add table public.transactions;
  end if;
end $$;

-- UPDATE and DELETE events carry only the primary key by default, which is
-- not enough for Realtime to evaluate the policy against the *old* row — so
-- those events get dropped rather than delivered. FULL makes the old row
-- available. INSERT (the demo path) works either way; this is for later.
alter table public.transactions replica identity full;

-- ------------------------------------------------------------- balances
-- Derived, never stored.
--
-- security_invoker = true makes the view run as the caller, so the
-- transactions policy applies and each user sums only their own rows. Without
-- it the view would run as its owner and every user would see every balance —
-- the classic way an RLS setup leaks through a view.
create or replace view public.balances
with (security_invoker = true) as
  select
    user_id,
    coalesce(sum(amount) filter (where type = 'income'),  0)
      - coalesce(sum(amount) filter (where type = 'expense'), 0) as balance
  from public.transactions
  group by user_id;

-- A view is not covered by the base table's grants.
grant select on public.balances to authenticated;
