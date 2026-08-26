# Cash Compass — React reference implementation

**This is not the delivery target.** The live app is the Flutter one in
[../mobile](../mobile). This directory is kept as the behavioural source of
truth that the port is measured against.

Do not add features here. See the [root README](../README.md) for why.

## Why it still exists

[../mobile/PARITY_SPEC.md](../mobile/PARITY_SPEC.md) transcribes every constant
and formula in this app, and instructs the reader to confirm against the named
source file when something is ambiguous. Several Dart files also cite their
React counterpart in a header comment. Deleting this directory would turn all
of those into dangling references.

Run it when you need to see the original behaviour of something the spec
describes but doesn't fully settle.

## Running it

Requires Node.js 20+ (developed on v22).

```bash
npm install
```

```bash
npm run dev
```

Serves on http://localhost:8080.

[.npmrc](.npmrc) sets `legacy-peer-deps=true` — leave it, or `npm install`
fails on peer-dependency conflicts. A `bun.lock` is committed too if you prefer
`bun install`.

### Supabase

Optional. Without a `.env` the app boots with login and signup disabled and logs
a warning — which is fine for reading reference behaviour. To enable auth,
create `.env`:

```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

Supabase is not configured on this project yet, so there are currently no values
to fill in.

## Scripts

| Command | Does |
| --- | --- |
| `npm run dev` | Dev server on :8080 |
| `npm run build` | Production build to `dist/` |
| `npm run lint` | ESLint |
| `npm test` | Vitest, single run |
| `npm run test:watch` | Vitest in watch mode |

## Known lint state

`npm run lint` currently reports 4 errors and 15 warnings — mostly
`react-refresh/only-export-components` and `react-hooks/exhaustive-deps` in the
context files. These are pre-existing and deliberately left alone: this code is
a reference for what the app *does*, and changing it risks diverging from what
the parity spec documents.

If you are here to read behaviour, ignore them. If you genuinely need to change
this app, fix the lint in the same PR.

## Layout

```
src/
├── components/   UI, including widgets/ for the workspace cards
├── contexts/     FinanceContext, CurrencyContext, ThemeContext
├── context/      AuthContext (note: singular — a historical split)
├── layouts/      One layout per theme
├── pages/        Route targets
└── lib/          Supabase client, helpers
```

Note there are two similarly named directories: `AuthContext.tsx` lives in
`context/` (singular) while the other three live in `contexts/` (plural). Both
paths are referenced by the parity spec, so they are left as they are rather
than consolidated.
