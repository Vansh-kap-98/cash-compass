# Cash Compass

A personal finance dashboard, in two implementations:

| Directory | What it is | Status |
| --- | --- | --- |
| `mobile/` | Flutter app for Android | **The live app.** New feature work goes here. |
| `frontend/` | React + TypeScript + Vite web app | **Reference implementation.** Kept as the source of truth for behaviour. |

The Flutter app is a port of the React app. `mobile/PARITY_SPEC.md` transcribes
every constant and formula from `frontend/src`, and several Dart files cite
their React counterpart in a header comment — so `frontend/` is documentation
you can run, not dead code. Don't add features to it.

There is no backend in this repo. Supabase handles auth only — and is not
configured yet, so the app runs in offline demo mode; all financial data lives
on-device (`localStorage` on web, `shared_preferences` on Android).

**[CURRENT_FEATURES.md](CURRENT_FEATURES.md) tracks what is built, what is
partial, and what has not been started.** Start there before picking up work.

---

## Repository layout

```
cash-compass/
├── frontend/          React reference app (Vite, TypeScript, Tailwind, shadcn/ui)
│   ├── src/           Components, contexts, pages
│   └── package.json
├── mobile/            Flutter Android app — the live target
│   ├── lib/           Dart source
│   ├── test/          Unit + widget tests
│   ├── PARITY_SPEC.md Exact behaviour transcribed from the React app
│   └── SETUP.md       Full toolchain install guide — read this first
├── .claude/           Claude Code config (CLAUDE.md, settings.json)
├── .cursor/           Cursor MCP config
├── .gemini/           Gemini CLI config
└── .mcp.json          CodeGraph MCP server registration
```

---

## Running the mobile app (Flutter)

**`mobile/SETUP.md` is the authoritative guide** — it covers installing the
Flutter SDK, Android Studio, and clearing `flutter doctor`, including several
Windows path traps that cause hard-to-diagnose build failures. Read it in full
the first time. What follows is the short version for a machine that already
has the toolchain.

### Requirements

- Flutter `>=3.44.0` (Dart `>=3.12.0`) — check with `flutter --version`
- An Android emulator or a physical device with USB debugging enabled

### Configure Supabase credentials

**Optional — skip this to start.** Supabase is not configured on this project
yet. With no config the app boots straight into demo mode, which is fully
functional offline, so a fresh clone runs with no credentials at all.

When Supabase is wired up, copy `mobile/config/dev.json.example` to
`mobile/config/dev.json` and fill in the values from a maintainer:

```json
{
  "SUPABASE_URL": "https://your-project.supabase.co",
  "SUPABASE_ANON_KEY": "your-anon-key"
}
```

That file is gitignored. It is read via `String.fromEnvironment`, so nothing is
bundled into the binary as a readable asset.

### Run

```bash
cd mobile
```

```bash
flutter pub get
```

```bash
flutter run
```

Add `--dart-define-from-file=config/dev.json` once that file exists.

### Test and analyse

```bash
flutter test
```

```bash
flutter analyze
```

---

## Running the web app (React)

You only need this if you're checking reference behaviour against the parity
spec. It is not the deliverable.

### Requirements

- Node.js 20+ (developed on v22)

### Configure Supabase credentials

Create `frontend/.env`:

```
VITE_SUPABASE_URL=https://your-project.supabase.co
VITE_SUPABASE_ANON_KEY=your-anon-key
```

Without these the app still boots, but login and signup are disabled and the
console logs a warning.

### Run

```bash
cd frontend
```

```bash
npm install
```

```bash
npm run dev
```

The dev server listens on http://localhost:8080.

`.npmrc` sets `legacy-peer-deps=true`; leave it in place or `npm install` will
fail on peer-dependency conflicts. A `bun.lock` is also committed if you prefer
`bun install`.

### Other scripts

| Command | Does |
| --- | --- |
| `npm run build` | Production build to `dist/` |
| `npm run lint` | ESLint over the project |
| `npm test` | Vitest, single run |
| `npm run test:watch` | Vitest in watch mode |

---

## Using CodeGraph with AI models

This repo is indexed by CodeGraph, a queryable knowledge graph of every symbol
and call edge in the codebase. It answers "how does X work" or "what breaks if
I change X" in one call, returning verbatim source plus call paths — including
dynamic-dispatch hops that `grep` cannot follow.

It's optional. The app builds and runs without it. But the agent instructions
in `.claude/CLAUDE.md` and `GEMINI.md` assume it's available, and it makes AI
assistance on this repo substantially cheaper and more accurate.

### Install and index

```bash
npm install -g @colbymchenry/codegraph
```

```bash
codegraph init
```

`init` builds the index into `.codegraph/`. **That directory is gitignored** —
the index is local to your machine and every teammate builds their own. A
background daemon keeps it in sync with your edits (roughly a one-second lag).

### Use it from a model

`.mcp.json` is committed, so any MCP-aware client picks the server up
automatically once the CLI is installed:

- **Claude Code** — the `codegraph_explore` tool appears on start; `.claude/CLAUDE.md` already instructs the model to prefer it over grep and file reads.
- **Cursor** — configured via `.cursor/mcp.json`.
- **Gemini CLI** — configured via `.gemini/settings.json`, with guidance in `GEMINI.md`.

The practical habit: when you brief a model on a task, name the symbols
involved rather than pasting files. One `codegraph_explore` call returns the
source, the callers, and the blast radius, which is both cheaper and more
complete than the model reading files one at a time.

### Use it from the shell

The CLI prints the same output the MCP tool returns, so it works regardless of
which model you use:

| Command | Does |
| --- | --- |
| `codegraph explore "<question or symbols>"` | Relevant source + call paths in one shot |
| `codegraph query <search>` | Find symbols by name |
| `codegraph node <name>` | One symbol's source + caller/callee trail |
| `codegraph callers <symbol>` | Everything that calls it |
| `codegraph impact <symbol>` | What a change would affect |
| `codegraph affected <files...>` | Which test files cover your changes |
| `codegraph status` | Index statistics |
| `codegraph sync` | Manually sync after large external changes |

Example:

```bash
codegraph explore "how does FinanceProvider persist transactions"
```

---

## Contributing

All changes reach `main` through a reviewed pull request. Work happens on your
own fork, and the maintainer merges.

### How that is enforced

Fork-and-PR is a convention, not something GitHub enforces on its own — a
collaborator with write access can push straight to `main` and merge their own
PR without anyone reviewing it. The gate is **branch protection**, configured on
the upstream repo under *Settings → Rules → Rulesets* (or *Settings →
Branches*), targeting `main`:

| Setting | Effect |
| --- | --- |
| Require a pull request before merging | Blocks direct pushes to `main` |
| Require approvals: 1 | A PR cannot merge itself |
| Do not allow bypassing the above | Applies the rules to admins too |

Contributors who work from a fork and are *not* collaborators are already gated
structurally — they have no write access to push with. Adding someone as a
collaborator hands them that access, so if the fork flow is the intent, it is
cleaner not to add them at all.

Note this governs the **source**, not the app. Merging a PR does not update
anyone's installed APK — see [Releasing an APK](#releasing-an-apk).

### Fork and clone

1. Click **Fork** on https://github.com/Vansh-kap-98/cash-compass
2. Clone your fork and add the original repo as `upstream`:

```bash
git clone https://github.com/YOUR-USERNAME/cash-compass.git
```

```bash
cd cash-compass
```

```bash
git remote add upstream https://github.com/Vansh-kap-98/cash-compass.git
```

Confirm you have both remotes — `origin` is yours, `upstream` is the shared one:

```bash
git remote -v
```

### Stay in sync

Before starting any new branch, pull the latest upstream `main`:

```bash
git fetch upstream
```

```bash
git checkout main
```

```bash
git merge upstream/main
```

```bash
git push origin main
```

### Branch, commit, push

Never commit to `main`. Branch per piece of work, named `type/short-description`
— `feat/goal-reminders`, `fix/currency-conversion`, `docs/setup-notes`:

```bash
git checkout -b feat/your-feature
```

Stage and review before committing. Check what you're about to commit rather
than reflexively running `git add .` — build output and `config/dev.json` must
never land in a commit:

```bash
git status
```

```bash
git diff
```

```bash
git add mobile/lib/some_file.dart
```

```bash
git commit -m "Add goal reminder notifications"
```

Write commit messages in the imperative mood ("Add", "Fix", "Refactor"), with a
subject under ~72 characters. If the change needs explanation, add a blank line
and a body describing *why*, not *what*.

Push the branch to your fork:

```bash
git push -u origin feat/your-feature
```

After the first push, subsequent pushes on the same branch are just:

```bash
git push
```

### Useful recovery commands

| Situation | Command |
| --- | --- |
| See recent history compactly | `git log --oneline -10` |
| Unstage a file (keep the edit) | `git restore --staged <file>` |
| Discard uncommitted edits to a file | `git restore <file>` |
| Amend the last commit (before pushing) | `git commit --amend` |
| Stash work in progress | `git stash` / `git stash pop` |
| See which branch you're on | `git branch` |

Avoid `git push --force` on a shared branch. If you must rewrite a branch only
you are using, `git push --force-with-lease` is the safer form — it refuses to
overwrite commits you haven't seen.

---

## Raising issues

Open issues at https://github.com/Vansh-kap-98/cash-compass/issues — search
first, duplicates are common on a small team.

A useful bug report contains:

- **Which app** — `mobile/` or `frontend/`. These behave differently on purpose in places.
- **Environment** — Flutter/Dart version (`flutter --version`) or Node version, plus device or emulator and Android version.
- **Steps to reproduce** — numbered, starting from a fresh launch.
- **Expected vs actual** — including exact amounts and currency if it's a calculation bug.
- **Logs** — the relevant `flutter run` console output or browser console errors.

For a parity bug — the Flutter app disagreeing with the React app — cite the
`PARITY_SPEC.md` section number. Note that §0 documents three inconsistent
currency conventions in the React app, two of which are bugs the port
*deliberately* does not reproduce — so check there before filing.

For a feature request, describe the problem you hit rather than the solution
you have in mind, and say whether you intend to implement it yourself.

From the terminal, if you have the GitHub CLI:

```bash
gh issue create
```

---

## Sending pull requests

### Before you open one

- `flutter analyze` and `flutter test` pass (or `npm run lint` and `npm test` for frontend changes).
- The app actually runs — build success isn't the same as working.
- No credentials, `config/dev.json`, `.env`, or build output in the diff.
- Your branch is rebased or merged onto current `upstream/main`.
- Behaviour changes are reflected in `PARITY_SPEC.md` if they alter a documented constant or formula.

### Open it

Push your branch, then either use the **Compare & pull request** button GitHub
shows on your fork, or:

```bash
gh pr create --base main --title "Add goal reminder notifications"
```

Target `main` on `Vansh-kap-98/cash-compass`. Keep one PR to one concern — a
reviewer can approve a focused fifty-line diff quickly and will stall on an
unfocused five-hundred-line one.

### Write the description

State what changed and why, link the issue it closes (`Closes #12`), and say
how you verified it — which tests, which device. Screenshots or a screen
recording are close to mandatory for UI changes, since the reviewer can't
easily reproduce your emulator state.

### Review

Expect comments; they're about the code, not you. Push follow-up commits to the
same branch and the PR updates automatically:

```bash
git push
```

Don't force-push mid-review unless asked — it makes the reviewer lose their
place. Once approved, a maintainer merges; delete your branch afterwards.

---

## Releasing an APK

An APK is a frozen snapshot of the code at build time. It has no link back to
the repo: **merging a PR changes nothing on anyone's phone.** For an installed
app to change, someone has to rebuild, republish, and have each tester reinstall.
Sideloaded Android apps never self-update.

### Two rules govern whether an update installs

**Same signing key.** Android identifies an app by application ID plus signing
key. Every build here uses `com.cashcompass.cash_compass`, so an APK signed with
a different key will not install over an existing one — it fails with
`App not installed`, and the only fix is uninstalling first, which wipes that
app's data. Release builds must therefore all be signed with the *same*
keystore. See [SETUP.md](mobile/SETUP.md) section 6.

**Increasing versionCode.** [pubspec.yaml](mobile/pubspec.yaml) carries
`version: 0.1.0+1`. The number after `+` becomes Android's `versionCode`, and it
is what the OS compares:

| versionCode vs installed | Result |
| --- | --- |
| Higher | Installs as an update, app data preserved |
| Same | Ambiguous; some installers refuse, and builds are indistinguishable |
| Lower | Always rejected as a downgrade |

**Bump the `+N` on every build you hand out.** Forgetting is the most common
cause of "I installed it but it's still the old app".

### Publishing a build

```bash
cd mobile && flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/debug-info
```

`--split-per-abi` emits one APK per architecture (~40 MB each) instead of a
single 113 MB fat binary. Testers on any modern phone want
`app-arm64-v8a-release.apk`.

Attach it to a GitHub release so there is a permanent URL and a visible history
of which build is which:

```bash
gh release create v0.1.0+2 mobile/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

Confirm the signature is the project keystore and not a debug key before
distributing:

```bash
apksigner verify --print-certs mobile/build/app/outputs/flutter-apk/app-arm64-v8a-release.apk
```

A certificate DN of `CN=Android Debug` means it fell back to the local debug key
-- that build is for your own device only, never for sharing.

### Installing a build (for testers)

Download the APK from the release page and open it; Android asks once for
permission to install from that source.

**Uninstall any local development build first.** A `flutter run` build carries
your own machine's debug key under the same application ID, so a released APK
will refuse to install over it. This looks like a broken download but is not.

### Forks and builds

Anyone who forks the repo can build a fully working APK — no keystore and no
Supabase credentials are needed, since the release build falls back to a local
debug key and the app boots into offline demo mode when unconfigured. What a
fork cannot produce is a build that Android accepts as *this* app: without the
project keystore its signature differs, so it can neither update installs of an
official build nor be updated by one.
