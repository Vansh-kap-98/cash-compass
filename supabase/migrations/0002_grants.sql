-- Fixes a gap in 0001: the table had row-level policies but no table-level
-- privileges.
--
-- These are two separate permission systems and BOTH must allow the action:
--
--   GRANT  -> may this role touch this table at all?
--   POLICY -> which rows may it touch?
--
-- 0001 wrote the policy and skipped the grant, so Postgres refused at the
-- first gate and the policy was never consulted. The symptom is
-- `42501 permission denied for table transactions` on every query, including
-- for a correctly signed-in user, which reads like a broken login rather than
-- a missing grant.
--
-- Run this after 0001. Safe to run more than once.

-- Signed-in users only. `anon` is deliberately omitted: an unauthenticated
-- visitor must not read anyone's transactions, and its current denial is the
-- behaviour we want, not an oversight.
grant select, insert, update, delete on public.transactions to authenticated;

-- A view does not inherit the base table's grants.
grant select on public.balances to authenticated;

-- Verify, after running the above:
--
--   select grantee, privilege_type
--   from information_schema.role_table_grants
--   where table_name = 'transactions';
--
-- Expect four rows for `authenticated` (SELECT, INSERT, UPDATE, DELETE) and
-- none for `anon`.
