# Parity spec — exact behaviour of the React app

Reference for the Flutter port. Every constant and formula here is transcribed
verbatim from `../frontend/src`. When implementing a feature, work from this
file and confirm against the named source file.

Amounts are USD unless noted. **Read §0 first — currency handling is not
uniform in the original.**

---

## 0. Currency handling is inconsistent in the web app

Three different conventions exist. This is not a typo in the source; it is
observable behaviour, and mixing them up silently corrupts amounts.

| Area | Convention |
| --- | --- |
| Transactions, goals, day plans, quick-entry pad | `convertToUSD` on input, `formatFromUSD` on output — **correct** |
| QuickActions **budget planner** | Stores raw display-currency amounts, formats with `formatAmount` — no conversion |
| StudentPlannerHub, SocialBenchmarks | Treats all input as USD directly |

**Decision for the port:** normalise everything to the first convention — store
USD, convert at the edges. The other two are bugs: a budget planned in INR then
viewed in USD currently shows INR numbers with a `$` sign. Flagged rather than
faithfully reproduced.

---

## 1. Add Entry (`QuickActions.tsx`)

**Expense categories (11), in order:**
`Housing, Groceries, Transport, Entertainment, Food, Utilities, Shopping, Health, Travel, Education, Other`

**Income categories (6), in order:**
`Salary, Freelance, Investment, Business, Gift, Other`

Switching type resets category to `Salary` (income) or `Groceries` (expense),
and for income clears the unplanned flag and reason tags.

**Recurrence (6):** `none, daily, weekly, biweekly, monthly, yearly` — labels
`One-time, Daily, Weekly, Biweekly, Monthly, Yearly`. No real scheduler; it is
appended to the note:

```
note = recurrence != none
     ? "${note ? note + ' | ' : ''}Recurring: ${recurrence}"
     : note
```

**Reason tags (4):** `emotional` "Emotional purchase", `social` "Social",
`discount` "Discount / sale", `impulse` "Impulse". Expense-only.

**Validation:** name non-empty AND amount finite AND > 0, else toast
"Invalid entry" / "Please provide a name and valid amount."

---

## 2. Set Goal (`QuickActions.tsx`)

**Period presets (6):** default `6-months`.

```
1-month 30 · 3-months 90 · 6-months 180 · 1-year 365 · 2-years 730
custom = Number(customDays) || 90     (min 7, default 90)
```

**Daily savings preview:**
```
dailySavingsNeeded = (!target || days <= 0) ? 0 : max(0, (target - initial) / days)
```
Also shown: `×7` weekly and `×30` monthly.

Note the original's confirmation toast uses `target / days` — ignoring
`initial`, inconsistent with the preview. Port the preview formula.

Icon default `🎯`. Target must be finite and > 0.

---

## 3. Dashboard planner (`DashboardPlanner.tsx`)

**KPIs:**
```
spentToday        = Σ expenses where date == today
spentToDate       = Σ all expenses
remainingBalance  = max(0, (manualBalance ?? 0) - spentToDate)
dailyRecords      = expenses grouped by date, sorted DESC
averageSpentPerDay= dailyRecords.isEmpty ? 0 : Σ day.expense / dailyRecords.length
```

**Daily budget** (reads the range written by the dashboard):
```
if range key valid:
    days = max(1, ceil((end - start) / msPerDay) + 1)
    return remainingBalance > 0 ? remainingBalance / days : 0
else:                       // fallback: rest of this month
    daysRemaining = max(1, daysInMonth - today.day + 1)
    return remainingBalance > 0 ? remainingBalance / daysRemaining : 0
```

**Selected-day maths:**
```
selectedDaySpent     = Σ expenses on planDate
selectedDayPlanned   = Σ plans on planDate
selectedDayRemaining = dailyBudget - selectedDaySpent - selectedDayPlanned
```

**Location profiles** (verbatim):

| Key | Label | Multiplier | Lunch | Transit | Groceries |
| --- | --- | --- | --- | --- | --- |
| `us-city` | US City | 1.0 | 16 | 9 | 22 |
| `india-metro` | India Metro | 0.48 | 6 | 2.5 | 10 |
| `eastern-europe` | Eastern Europe | 0.72 | 11 | 4.5 | 15 |

```
cost         = baseCost * multiplier
healthyLimit = max(0, selectedDayRemaining * 0.4)
badge        = cost <= healthyLimit ? "On Budget" : "Trim Needed"
```

> The multiplier never touches the daily budget in the original — only the
> staple costs. "Location-adjusted budget" is aspirational wording.

**Suggestions** (max 3, in order). Exactly one of the first group:
```
remaining < 0
  → "You are over today's budget. Switch to essential-only purchases for the rest of the day."
remaining < dailyBudget * 0.25
  → "You are in the final 25% of your daily budget. Keep only high-priority plan items."
else
  → "You still have comfortable room today. Front-load essentials and delay impulse categories."
```
Then, conditionally:
```
selectedDayPlanned > dailyBudget
  → "Your planned spend is above budget. Reduce one plan item by around 20-30%."
averageSpentPerDay > dailyBudget
  → "Your average daily spend is above your location-adjusted budget. Try a three-day low-spend streak."
filler (if fewer than 3)
  → "Use category caps for Food and Shopping today to protect tomorrow's flexibility."
```

**Day plan:** `{id, title, estimate (USD), date}` → `cash-compass-day-plans-v1`,
newest first. Today's plans show 4; saved list shows 6; records show 20.

---

## 4. Budget planner (`QuickActions.tsx`)

Types: `trip` (Plane), `outing` (Utensils), `event` (Users). Default `trip`.

```
budgetTotal = Σ items.estimate
perPerson   = budgetTotal / max(1, people)     // "Per person" shown only when people > 1
```

Line item: `{id, name, estimate}`, **appended** (not prepended). Silently
ignores empty name or estimate <= 0.

**Finalize** — blocked unless title non-empty and at least one item; also
rejects `dateTo < dateFrom` ("Invalid dates").

```json
{ "id": "bp-<ms>", "title": "...", "planType": "trip",
  "dateFrom": "yyyy-MM-dd", "dateTo": "yyyy-MM-dd (omitted if unset)",
  "people": 4, "items": [{"id":"bi-<ms>","name":"Hotel","estimate":8000}],
  "total": 8000, "perPerson": 2000, "createdAt": "<ISO>" }
```
Stored newest-first as an array in `cash-compass-budget-plans-v1`. After
finalize, title/dateTo/people/items reset; `dateFrom` and `planType` persist.

Receipt view: latest plan in full, then up to 3 more in "Recent Finalised Bills".

---

## 5. Workspace widgets (`WorkspaceCanvas.tsx`)

Storage `cash-compass-workspace-v3`. Every type defaults to a 3×2 span.

**safe-to-spend:**
```
available    = max(0, (manualBalance ?? 0) - totalSpent)
daysRemaining= max(1, daysInMonth - today.day + 1)
dailyBudget  = available / daysRemaining
safeToSpend  = max(0, dailyBudget - spentToday)
completion   = dailyBudget > 0 ? (safeToSpend / dailyBudget) * 100 : 0
```

**sub-stash-jar:** `fill% = min(100, totalSavings / 5000 * 100)`; badge number
`floor(totalSavings / 100)`. "Boost +$5" contributes a literal `5` to
`goals[0]` — not currency-converted, and a silent no-op with no goals.

**burn-rate-line:** 7 points, `i=0` is 6 days ago through `i=6` today; each is
the sum of that day's expenses.

**manga-status:** `avg = Σ(current/target)*100 / goals.length`, capped 100.
`stage = floor(avg / 25)` → `😔 😐 😊 😄 🤩` (🤩 only at exactly 100).

**ascii-fortune:**
```
["💰 A penny saved is a penny earned",
 "📈 Small steps lead to big gains",
 "🎯 Goals achieved with patience",
 "💡 Smart spending = Happy future",
 "🚀 Invest in yourself today"]
index = weekdayName[0].charCodeAt(0) % 5
```
> Only indices 0, 2, 3, 4 can ever occur — "Goals achieved with patience"
> (index 2) shows Mon/Wed, index 4 Tue/Thu, 0 Fri, 3 Sat/Sun. Index 1 is
> unreachable. Port as a proper daily rotation instead.

**3d-growth-gem:** `size = min(80, 30 + totalSavings / 10000 * 50)`, hexagon
`50,10 90,40 90,70 50,90 10,70 10,40`, gradient `#c084fc → #7c3aed`, 4s spin.

**quick-entry-pad:** top-3 categories by spend, falling back to
`Food, Transport, Shopping`. Adds an expense named after the category.

**waste-auditor / roommate-sync** — hardcoded in the original; being wired to
real data per the plan. Original values for reference: Streaming 15.99,
Cloud Storage 9.99, Gym 49.99; Alex +45.50 ("owed"), Jordan −32.00 ("owes").

---

## 6. Event calendar (`widgets/EventCalendar.tsx`)

Region persisted at `cash-compass-region` (no `-v1`), default `India`.

**Roll-forward:** an event moves to next year only once its start is more than
7 days in the past — a grace window that keeps just-passed events visible.

**India:** exam window Jul 18 +8d (Academic) · Diwali cluster Nov 7 +5d
(Festival) · Semester reset Aug 1 +13d (Student costs)

**Russia:** Winter exams Jan 10 +18d (Academic) · New Year holidays Dec 29 +9d
(Holiday) · Stipend cycle Aug 5 (Income)

Active event = first with `0 <= daysUntil <= 7`.

**Forecast:**
```
average = Σ expenses / count
window  = expenses where monthDay in [startMonthDay - 7, endMonthDay]
          using monthDay = month * 31 + day      // year-agnostic
historicalAverage = window.isEmpty ? average : Σ window / window.length
projected = historicalAverage * (window.isEmpty ? 1.12 : 1.16)
increase  = max(0, projected - historicalAverage)
```

---

## 7. Social benchmarks (`widgets/SocialBenchmarks.tsx`)

| City | Course | Food | Transit | Sample |
| --- | --- | --- | --- | --- |
| Delhi | Engineering | 84 | 24 | 214 |
| Delhi | Arts | 73 | 21 | 129 |
| Moscow | Engineering | 136 | 42 | 178 |
| Moscow | Arts | 122 | 39 | 111 |

Lobby opt-in at `cash-compass-private-lobby-v1` (`"true"`/`"false"`). Seed
challenge: `{title: "Seven-day save streak", target: 20, joined: false}`.
Default weekly target input `20`. The original has no leave control despite
claiming "You can leave the lobby at any time" — add one.

---

## 8. Student Planner Hub (`StudentPlannerHub.tsx`)

Never imported on the web; persists nothing. **The port should persist it.**

Semester: `start = Jan 15 of current year`, `end = start + 112 days` (16 weeks).

**Survival Calculator** — horizon default 30, clamped `max(7, …)`, max 120.
```
totalIncomeForHorizon = Σ streams:
    one-time → amount
    weekly   → amount * horizonDays / 7
    monthly  → amount * horizonDays / 30

discretionaryPool = balance + incomeToDate - spentToday
                  + totalIncomeForHorizon - fixedCostsTotal - upcomingBills
dailySpendable    = horizonDays <= 0 ? 0 : discretionaryPool / horizonDays
```
Status: `>= 25` Green Zone · `>= 12` Tight Zone · else Critical Zone.

> `fixedCosts` is hardcoded empty with no setter in the original — a half-built
> feature. The port should add the missing add/remove UI.

**Social Budgeting**
```
totalSocialRealistic = Σ plans: realisticEstimate / max(1, splitCount)
postSocialDaily      = (discretionaryPool - totalSocialRealistic) / horizonDays
lowEstimate     = finite ? max(0, low) : realistic
stretchEstimate = finite ? max(realistic, stretch) : realistic
```
Date defaults to today + 2 days. `low`/`stretch`/`note` are stored but never
displayed in the original — surface them.

**Loan Runway** — defaults: lump sum `4200`, safety buffer `350`.
```
semesterExpenses = Σ expenses within [semesterStart, semesterEnd]
weeksElapsed     = max(1, max(1, daysSince(semesterStart)) / 7)
weeksRemaining   = max(1, daysUntil(semesterEnd) / 7)
burnRate         = semesterExpenses / weeksElapsed
loanRemaining    = max(0, lumpSum - semesterExpenses - safetyBuffer)
runwayWeeks      = burnRate <= 0 ? weeksRemaining : loanRemaining / burnRate
recommendedCap   = loanRemaining / weeksRemaining
runwayProgress   = min(100, runwayWeeks / weeksRemaining * 100)
```

**Bloom Streaks** — dates as `yyyy-MM-dd`, badge at `>= 3`.
```
sorted = dates DESC; streak = 0; cursor = today
for date in sorted:
    if sameDay(date, cursor): streak++; cursor -= 1 day
```
> The original compares against a `cursor` carrying the current time-of-day,
> and keeps iterating after a gap. Port as a clean consecutive-day count.

---

## 9. Themes

All four alternates, verbatim from `../frontend/src/index.css`. Format is
`H S% L%`, matching `hsl()` in [app_tokens.dart](lib/app/theme/app_tokens.dart).

### retro-pixel — radius `0rem`, Silkscreen / JetBrains Mono
```
background 218 37% 82   foreground 2 24% 20    card 34 38% 84
primary 180 40% 50      primary-fg 34 38% 84   secondary 43 68% 62
secondary-fg 2 24% 20   muted 218 25% 76       muted-fg 2 18% 34
accent 341 80% 69       accent-fg 2 24% 20     destructive 353 78% 62
destructive-fg 34 38% 84  border 2 24% 20      input 28 28% 78   ring 180 40% 50
```
Shadow is a hard offset `4px 4px 0` in the border colour — no blur. Also has
`.retro-grid` (26px crosshatch) and `.retro-pixel-border` (2px + 4px offset).

### modern-academic — dark, radius `0.25rem`, Geist Mono
```
background 220 15% 10   foreground 210 20% 90  card 220 15% 15
primary 190 100% 50     primary-fg 220 15% 5   secondary 220 15% 20
secondary-fg 210 20% 85 muted 220 15% 18       muted-fg 210 10% 55
accent 220 15% 20       accent-fg 190 100% 50  destructive 0 70% 50
destructive-fg 0 0% 100 border 220 15% 25      input 220 15% 22  ring 190 100% 50
```

### kawaii-pastel — radius `2rem`, Outfit / Inter
```
background 300 100% 98  foreground 300 20% 20  card 0 0% 100
primary 325 100% 75     primary-fg 300 100% 98 secondary 190 100% 95
secondary-fg 190 60% 30 muted 60 100% 95       muted-fg 60 30% 40
accent 33 100% 90       accent-fg 33 60% 40    destructive 0 100% 70
destructive-fg 0 0% 100 border 300 100% 90     input 300 100% 92  ring 325 100% 75
```
Shadow is a hard drop `0 10px 0` in pink — no blur.

### cyber-terminal — radius `0rem`, JetBrains Mono throughout
```
background 140 100% 2   foreground 140 100% 60 card 140 100% 4
primary 140 100% 60     primary-fg 140 100% 2  secondary 140 100% 10
secondary-fg 140 100% 70 muted 140 100% 8      muted-fg 140 50% 40
accent 140 100% 15      accent-fg 140 100% 80  destructive 0 100% 50
destructive-fg 0 0% 100 border 140 100% 20     input 140 100% 15  ring 140 100% 60
```
Shadow is a green glow `0 0 10px` at 20% opacity.

**Gotcha:** none of the four alternates redefine `--theme-primary-soft`,
`--theme-primary-deep`, `--theme-accent-soft`, or `--theme-accent-deep`. Those
Soft Bloom values leak into every theme through the shared `body` and `.bg-*`
gradient rules — so the web app's alternate themes are subtly contaminated with
Soft Bloom purple/orange. In Dart, give each theme its own explicit values.

---

## 10. Dead controls in the original

Reproduce the UI, but these do nothing on the web and should be made
functional or removed: waste-auditor `✕`, roommate-sync "Settle Up",
chibi-mascot click, EventCalendar "Apply safety margin" (cosmetic toggle,
not persisted), `AuthShell.eyebrow` (accepted, never rendered),
`DashboardPlanner.plannedToday` (computed, never shown).
