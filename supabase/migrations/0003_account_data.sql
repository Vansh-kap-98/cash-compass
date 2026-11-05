-- Moves the rest of the finance data off the device and onto the account.
--
-- Scope: transactions, goals, budgets, and the manual balance snapshot --
-- everything `useFinance` (web) and `FinanceProvider` (mobile) hold. Theme,
-- language, currency and the exchange-rate cache stay on the device: those are
-- per-device preferences, not user data.
--
-- Every table below follows the same three-part pattern as 0001 + 0002, which
-- is the part that is easy to get wrong:
--   1. enable RLS                 -- without it the policy is never consulted
--   2. one policy for `authenticated`, USING *and* WITH CHECK
--   3. GRANT to `authenticated`   -- a policy alone is not permission (see 0002)
-- `anon` is granted nothing anywhere.
--
-- Safe to run more than once.

-- ---------------------------------------------------------------- transactions
-- The local model carries four fields the 0001 table has no room for, so a
-- row written from the dashboard would lose them on a round trip.
alter table public.transactions
  add column if not exists name         text    not null default '',
  add column if not exists icon         text,
  add column if not exists is_unplanned boolean not null default false,
  add column if not exists reason_tags  text[]  not null default '{}';

-- Only expenses can be unplanned, and only these four reasons exist. Enforced
-- here as well as in both clients: the clients can be out of date, the table
-- cannot.
do $$
begin
  if not exists (
    select 1 from pg_constraint where conname = 'transactions_reason_tags_valid'
  ) then
    alter table public.transactions
      add constraint transactions_reason_tags_valid
      check (reason_tags <@ array['emotional','social','discount','impulse']::text[]);
  end if;

  if not exists (
    select 1 from pg_constraint where conname = 'transactions_unplanned_is_expense'
  ) then
    alter table public.transactions
      add constraint transactions_unplanned_is_expense
      check (not is_unplanned or type = 'expense');
  end if;
end $$;

-- ----------------------------------------------------------------------- goals
create table if not exists public.goals (
  id         uuid primary key default gen_random_uuid(),
  user_id    uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name       text not null,
  target     numeric(12,2) not null check (target > 0),
  -- Never above target: `contributeToGoal` already clamps, but a second client
  -- writing concurrently would not know that.
  current    numeric(12,2) not null default 0 check (current >= 0),
  icon       text not null default '🎯',
  created_at timestamptz not null default now(),
  constraint goals_current_within_target check (current <= target)
);

create index if not exists goals_user_created_idx
  on public.goals (user_id, created_at desc);

alter table public.goals enable row level security;

drop policy if exists "Users manage their own goals" on public.goals;
create policy "Users manage their own goals"
  on public.goals for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

grant select, insert, update, delete on public.goals to authenticated;

-- --------------------------------------------------------------------- budgets
create table if not exists public.budgets (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null default auth.uid() references auth.users(id) on delete cascade,
  name          text not null,
  monthly_limit numeric(12,2) not null check (monthly_limit > 0),
  created_at    timestamptz not null default now()
);

-- `upsertBudget` matches on a case-insensitive name, so the uniqueness that
-- makes it an upsert rather than an insert has to be case-insensitive too --
-- otherwise "Food" and "food" become two budgets.
create unique index if not exists budgets_user_name_idx
  on public.budgets (user_id, lower(name));

alter table public.budgets enable row level security;

drop policy if exists "Users manage their own budgets" on public.budgets;
create policy "Users manage their own budgets"
  on public.budgets for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

grant select, insert, update, delete on public.budgets to authenticated;

-- ------------------------------------------------------------ finance_settings
-- One row per user, keyed by user_id rather than a surrogate id: there is
-- nothing to have two of, and a primary key on user_id makes that structural
-- instead of a rule someone has to remember.
create table if not exists public.finance_settings (
  user_id               uuid primary key default auth.uid() references auth.users(id) on delete cascade,
  starting_balance      numeric(12,2) not null default 0,
  -- Nullable on purpose: null means "the user has not set a snapshot", which
  -- is different from zero and the UI renders it differently.
  manual_balance        numeric(12,2),
  manual_income_to_date numeric(12,2),
  manual_spent_today    numeric(12,2),
  updated_at            timestamptz not null default now()
);

alter table public.finance_settings enable row level security;

drop policy if exists "Users manage their own finance settings" on public.finance_settings;
create policy "Users manage their own finance settings"
  on public.finance_settings for all to authenticated
  using (user_id = auth.uid())
  with check (user_id = auth.uid());

grant select, insert, update, delete on public.finance_settings to authenticated;

-- -------------------------------------------------------------------- realtime
-- Needed for the cross-device live update. `replica identity full` makes the
-- old row available on update/delete events, without which a deletion arrives
-- with nothing but an id.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'goals'
  ) then
    alter publication supabase_realtime add table public.goals;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'budgets'
  ) then
    alter publication supabase_realtime add table public.budgets;
  end if;

  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'finance_settings'
  ) then
    alter publication supabase_realtime add table public.finance_settings;
  end if;
end $$;

alter table public.goals            replica identity full;
alter table public.budgets          replica identity full;
alter table public.finance_settings replica identity full;

-- Verify:
--   select tablename, rowsecurity from pg_tables
--   where schemaname = 'public'
--     and tablename in ('transactions','goals','budgets','finance_settings');
-- Expect rowsecurity = true on all four.
