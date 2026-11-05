# Cash Compass — Penny Pilots
## 5-minute defense script

Nine continuous turns. Each person speaks once, start to finish, then hands on —
no back-and-forth inside a block. Features are still covered by cross-country
pairs; the two halves of each pair simply speak one after the other.

| # | Speaker | Block | Slot | Length |
|---|---------|-------|------|--------|
| 1 | **Vansh** | What Cash Compass is | 0:00–0:30 | 30s |
| 2 | **Gleb** | " | 0:30–1:00 | 30s |
| 3 | **Kintan** | The build | 1:00–1:30 | 30s |
| 4 | **Ismail** | " | 1:30–2:00 | 30s |
| 5 | **Athena** | Research & the need | 2:00–2:35 | 35s |
| 6 | **Vlad** | " | 2:35–3:05 | 30s |
| 7 | **Akshit** | The algorithms | 3:05–3:45 | 40s |
| 8 | **Meehika** | Design | 3:45–4:20 | 35s |
| 9 | **Simphiwe** | Close | 4:20–4:45 | 25s |
|   | *buffer* | — | 4:45–5:00 | 15s |

Pace assumes ~160 words/minute.

---

## 1 · VANSH — 0:00–0:30

Good morning. We're Penny Pilots, and this is Cash Compass: a personal finance
app built for students.

Most finance apps answer the question "where did my money go". They're built for
salaried users — bank integrations, net-worth charts, monthly reports. Students
need a different question answered. Not "what am I worth", but "can I afford
this, right now?"

That single change drives every decision in the product.

> *(76 words)*

---

## 2 · GLEB — 0:30–1:00

It drives what we store, what we calculate, and what goes on the first screen.

And we built it twice — as an Android application and as a web application. One
team, across two countries, delivering the same product on two platforms.

Those two builds made opposite architectural choices, deliberately, and that
contrast is the most interesting thing we can show you today. Kintan will start
with mobile.

> *(78 words)*

---

## 3 · KINTAN — 1:00–1:30

The Android app is built in Flutter — twenty-three thousand lines of Dart, with
five hundred and thirty-seven automated tests passing.

The defining constraint is that there is no server. No account, no sign-up, and
no financial record ever leaves the handset. It works completely offline; only
two things touch the internet at all — the daily exchange rate, and the font on
first launch.

> *(74 words)*

---

## 4 · ISMAIL — 1:30–2:00

On the web we made the opposite call.

Fourteen React components over a responsive twelve-column workspace, backed by
eighteen REST endpoints and four PostgreSQL tables through Supabase. Core routes
return in under a hundred milliseconds.

So: device-local and private by default, or shared services so your data follows
you across machines. Same product — two honest answers to the same trade-off.

> *(74 words)*

---

## 5 · ATHENA — 2:00–2:35

So why build this at all?

We ran eight surveys and built four personas, and what we heard was consistent.
Students don't lack intent — they lack friction-free tools. Manual entry is where
budgeting dies.

So we removed it. Point the camera at a receipt and it's read on-device, by ML
Kit — the image is never uploaded anywhere. Nothing is saved until the student
confirms what we read.

> *(84 words)*

---

## 6 · VLAD — 2:35–3:05

The market data frames why that matters.

Forty-three million higher-education students in our context, typically working
with a five to ten thousand rupee monthly allowance. Only eighteen per cent
actively track their spending. And around sixty-five per cent may run out seven
to ten days before the month ends.

That last figure is the product. Nothing else on the market answers a student
standing in a shop with four days left.

> *(81 words)*

---

## 7 · AKSHIT — 3:05–3:45

What makes this more than a spreadsheet is five mathematical models.

The survival calculator takes your income streams, your fixed costs and your
upcoming bills, and returns a single number: what you can safely spend today.
That resolves to a status — Green, Tight, or Critical. Alongside it sit
social-event budgeting and a loan-runway visualiser, so you can test a decision
before you spend the money rather than after.

The receipt parser applies the same discipline. It cross-checks every total
three ways — the printed label, cash minus change, and the sum of the line items.
When those disagree, we say so rather than guessing.

> *(113 words)*

---

## 8 · MEEHIKA — 3:45–4:20

Across both platforms the flow is the same three steps: capture, understand,
decide. Twenty-two high-fidelity Figma screens define it.

The mobile app uses a restrained monochrome system — black, white and three
greys, one typeface, and a single reserved red used only to confirm destructive
actions. Every container carries a slim border, so the interface stays legible
even when a student enlarges the text by thirty per cent. The web keeps the Cash
Compass green identity while preserving the identical information flow.

> *(89 words)*

---

## 9 · SIMPHIWE — 4:20–4:45

Two countries, two implementations, one product. The research, the engineering
and this defense were coordinated across the whole team, and everything is on
GitHub — source, documentation and the full development history.

We're honest about what's next: transaction editing, continuous integration, and
a backend decision. But the core works today.

We'll now show one student journey — transaction, to insight, to decision. Thank
you.

> *(72 words)*

---

## Cue sheet

- **Eight handovers, roughly two seconds each.** That's most of the 15-second
  buffer, so the handover is the thing to rehearse. Step up as the previous
  person says their last sentence rather than after it.
- **Only three turns name the next speaker** (Gleb hands to Kintan; the rest
  follow the slide order). Everyone else should just begin — announcing each
  other nine times burns close to twenty seconds.
- **Nobody says their own name or role.** The slide already shows it.
- **Drop first if you're over:** Akshit's receipt paragraph, Meehika's final
  sentence, then Simphiwe's roadmap line. In that order — each costs about seven
  seconds and none of them breaks the argument.
- **Numbers to say slowly:** 23,436 / 537 / 43.3 million / 18 per cent / 65 per
  cent. These are the credibility beats; rushing them wastes them.
