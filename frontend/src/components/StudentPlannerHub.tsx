import { useMemo, useState } from "react";
import { addDays, differenceInCalendarDays, format, isSameDay, parseISO } from "date-fns";
import { useFinance } from "@/contexts/FinanceContext";
import { useCurrency } from "@/contexts/CurrencyContext";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Progress } from "@/components/ui/progress";
import { Textarea } from "@/components/ui/textarea";
import { toast } from "@/components/ui/use-toast";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

type IncomeCadence = "one-time" | "weekly" | "monthly";

interface IncomeStream {
  id: string;
  name: string;
  amount: number;
  cadence: IncomeCadence;
}

interface FixedCost {
  id: string;
  name: string;
  amount: number;
}

interface SocialPlan {
  id: string;
  title: string;
  date: string;
  lowEstimate: number;
  realisticEstimate: number;
  stretchEstimate: number;
  splitCount: number;
  note?: string;
}

export const StudentPlannerHub = () => {
  const { formatFromUSD } = useCurrency();
  const { transactions, manualBalance, manualIncomeToDate, manualSpentToday } = useFinance();

  const [horizonDays, setHorizonDays] = useState(30);
  const [upcomingBills, setUpcomingBills] = useState(0);
  const [incomeStreams, setIncomeStreams] = useState<IncomeStream[]>([]);
  const [fixedCosts] = useState<FixedCost[]>([]);

  const [newIncomeName, setNewIncomeName] = useState("");
  const [newIncomeAmount, setNewIncomeAmount] = useState("");
  const [newIncomeCadence, setNewIncomeCadence] = useState<IncomeCadence>("weekly");

  const [newSocialTitle, setNewSocialTitle] = useState("");
  const [newSocialDate, setNewSocialDate] = useState(format(addDays(new Date(), 2), "yyyy-MM-dd"));
  const [newSocialLow, setNewSocialLow] = useState("");
  const [newSocialRealistic, setNewSocialRealistic] = useState("");
  const [newSocialStretch, setNewSocialStretch] = useState("");
  const [newSocialSplit, setNewSocialSplit] = useState("1");
  const [newSocialNote, setNewSocialNote] = useState("");
  const [socialPlans, setSocialPlans] = useState<SocialPlan[]>([]);

  const semesterStart = useMemo(() => new Date(new Date().getFullYear(), 0, 15), []);
  const semesterEnd = useMemo(() => addDays(semesterStart, 16 * 7), [semesterStart]);

  const [loanLumpSum, setLoanLumpSum] = useState(4200);
  const [loanSafetyBuffer, setLoanSafetyBuffer] = useState(350);
  const [streakDates, setStreakDates] = useState<string[]>([]);

  const totalIncomeForHorizon = useMemo(() => {
    return incomeStreams.reduce((sum, stream) => {
      if (stream.cadence === "one-time") return sum + stream.amount;
      if (stream.cadence === "weekly") return sum + stream.amount * (horizonDays / 7);
      return sum + stream.amount * (horizonDays / 30);
    }, 0);
  }, [incomeStreams, horizonDays]);

  const fixedCostsTotal = useMemo(() => fixedCosts.reduce((sum, item) => sum + item.amount, 0), [fixedCosts]);

  const baseBalance = manualBalance ?? 0;
  const baseIncomeToDate = manualIncomeToDate ?? 0;
  const baseSpentToday = manualSpentToday ?? 0;

  const discretionaryPool = useMemo(() => {
    return baseBalance + baseIncomeToDate - baseSpentToday + totalIncomeForHorizon - fixedCostsTotal - upcomingBills;
  }, [baseBalance, baseIncomeToDate, baseSpentToday, fixedCostsTotal, upcomingBills, totalIncomeForHorizon]);

  const dailySpendable = useMemo(() => {
    if (horizonDays <= 0) return 0;
    return discretionaryPool / horizonDays;
  }, [discretionaryPool, horizonDays]);

  const survivalStatus = useMemo(() => {
    if (dailySpendable >= 25) return { label: "Green Zone", tone: "bg-emerald-100 text-emerald-800" };
    if (dailySpendable >= 12) return { label: "Tight Zone", tone: "bg-amber-100 text-amber-900" };
    return { label: "Critical Zone", tone: "bg-rose-100 text-rose-900" };
  }, [dailySpendable]);

  const totalSocialRealistic = useMemo(() => {
    return socialPlans.reduce((sum, plan) => sum + plan.realisticEstimate / Math.max(1, plan.splitCount), 0);
  }, [socialPlans]);

  const postSocialDaily = useMemo(() => {
    if (horizonDays <= 0) return 0;
    return (discretionaryPool - totalSocialRealistic) / horizonDays;
  }, [discretionaryPool, horizonDays, totalSocialRealistic]);

  const semesterExpenses = useMemo(() => {
    return transactions
      .filter((tx) => tx.type === "expense")
      .filter((tx) => {
        const date = new Date(tx.date);
        return date >= semesterStart && date <= semesterEnd;
      })
      .reduce((sum, tx) => sum + tx.amount, 0);
  }, [semesterEnd, semesterStart, transactions]);

  const weeksElapsed = useMemo(() => {
    const days = Math.max(1, differenceInCalendarDays(new Date(), semesterStart));
    return Math.max(1, days / 7);
  }, [semesterStart]);

  const weeksRemaining = useMemo(() => {
    return Math.max(1, differenceInCalendarDays(semesterEnd, new Date()) / 7);
  }, [semesterEnd]);

  const burnRate = useMemo(() => semesterExpenses / weeksElapsed, [semesterExpenses, weeksElapsed]);

  const loanRemaining = useMemo(() => {
    return Math.max(0, loanLumpSum - semesterExpenses - loanSafetyBuffer);
  }, [loanLumpSum, loanSafetyBuffer, semesterExpenses]);

  const runwayWeeks = useMemo(() => {
    if (burnRate <= 0) return weeksRemaining;
    return loanRemaining / burnRate;
  }, [burnRate, loanRemaining, weeksRemaining]);

  const recommendedWeeklyCap = useMemo(() => {
    return weeksRemaining > 0 ? loanRemaining / weeksRemaining : 0;
  }, [loanRemaining, weeksRemaining]);

  const runwayProgress = useMemo(() => Math.min(100, (runwayWeeks / weeksRemaining) * 100), [runwayWeeks, weeksRemaining]);

  const currentStreak = useMemo(() => {
    const sorted = [...streakDates]
      .map((date) => parseISO(date))
      .sort((a, b) => b.getTime() - a.getTime());

    if (sorted.length === 0) return 0;

    let streak = 0;
    let cursor = new Date();

    for (const date of sorted) {
      if (isSameDay(date, cursor)) {
        streak += 1;
        cursor = addDays(cursor, -1);
      }
    }

    return streak;
  }, [streakDates]);

  const addIncome = () => {
    const amount = Number(newIncomeAmount);
    if (!newIncomeName.trim() || !Number.isFinite(amount) || amount <= 0) {
      toast({ title: "Quick check", description: "Add a name and a valid amount for this income stream." });
      return;
    }

    setIncomeStreams((prev) => [
      {
        id: `inc-${Date.now()}`,
        name: newIncomeName.trim(),
        amount,
        cadence: newIncomeCadence,
      },
      ...prev,
    ]);
    setNewIncomeName("");
    setNewIncomeAmount("");
  };

  const addSocialPlan = () => {
    const lowEstimate = Number(newSocialLow);
    const realisticEstimate = Number(newSocialRealistic);
    const stretchEstimate = Number(newSocialStretch);
    const splitCount = Math.max(1, Number(newSocialSplit) || 1);

    if (!newSocialTitle.trim() || realisticEstimate <= 0) {
      toast({ title: "Almost there", description: "Add an event title and at least a realistic estimate." });
      return;
    }

    setSocialPlans((prev) => [
      {
        id: `social-${Date.now()}`,
        title: newSocialTitle.trim(),
        date: newSocialDate,
        lowEstimate: Number.isFinite(lowEstimate) ? Math.max(0, lowEstimate) : realisticEstimate,
        realisticEstimate,
        stretchEstimate: Number.isFinite(stretchEstimate) ? Math.max(realisticEstimate, stretchEstimate) : realisticEstimate,
        splitCount,
        note: newSocialNote.trim() || undefined,
      },
      ...prev,
    ]);

    setNewSocialTitle("");
    setNewSocialLow("");
    setNewSocialRealistic("");
    setNewSocialStretch("");
    setNewSocialSplit("1");
    setNewSocialNote("");
  };

  const markTodayOnTrack = () => {
    const today = format(new Date(), "yyyy-MM-dd");
    setStreakDates((prev) => (prev.includes(today) ? prev : [today, ...prev]));
    toast({ title: "Bloom streak updated", description: "Nice work. You stayed within your plan today." });
  };

  return (
    <div className="grid grid-cols-1 gap-6">
      <Card className="rounded-3xl border-border bg-card/90">
        <CardHeader>
          <CardTitle className="text-base">Survival Calculator</CardTitle>
          <p className="text-sm text-muted-foreground">Find your daily spendable cash after essentials, with no guilt attached.</p>
        </CardHeader>
        <CardContent className="space-y-5">
          <div className="grid grid-cols-1 gap-4 md:grid-cols-3">
            <div className="space-y-1.5">
              <Label>Horizon (days)</Label>
              <Input type="number" min="7" max="120" value={horizonDays} onChange={(e) => setHorizonDays(Math.max(7, Number(e.target.value) || 30))} />
            </div>
            <div className="space-y-1.5">
              <Label>Upcoming must-pay bills</Label>
              <Input type="number" min="0" step="0.01" value={upcomingBills} onChange={(e) => setUpcomingBills(Math.max(0, Number(e.target.value) || 0))} />
            </div>
            <div className="space-y-1.5">
              <Label>Current status</Label>
              <div className="h-10 rounded-md border border-border bg-background px-3 py-2 text-sm">
                <span className={`rounded-full px-2 py-1 text-xs font-medium ${survivalStatus.tone}`}>{survivalStatus.label}</span>
              </div>
            </div>
          </div>

          <div className="rounded-2xl border border-border bg-secondary/40 p-4">
            <p className="text-xs uppercase tracking-wide text-muted-foreground">Daily Spendable</p>
            <p className="mt-1 text-3xl font-semibold">{formatFromUSD(dailySpendable)}</p>
            <p className="mt-1 text-xs text-muted-foreground">Based on your manual balance, income to date, and spend so far.</p>
          </div>

          <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
            <div className="space-y-2 rounded-xl border border-border p-3">
              <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Income Streams</p>
              <p className="text-xs text-muted-foreground">Start with the top snapshot. Add extra income only if it truly exists.</p>
              <div className="space-y-2">
                {incomeStreams.slice(0, 4).map((stream) => (
                  <div key={stream.id} className="flex items-center justify-between text-sm">
                    <span>{stream.name}</span>
                    <span>{formatFromUSD(stream.amount)} <span className="text-xs text-muted-foreground">/{stream.cadence}</span></span>
                  </div>
                ))}
              </div>
              <div className="grid grid-cols-1 gap-2 pt-2 md:grid-cols-3">
                <Input placeholder="New income" value={newIncomeName} onChange={(e) => setNewIncomeName(e.target.value)} />
                <Input type="number" placeholder="Amount" value={newIncomeAmount} onChange={(e) => setNewIncomeAmount(e.target.value)} />
                <Select value={newIncomeCadence} onValueChange={(value) => setNewIncomeCadence(value as IncomeCadence)}>
                  <SelectTrigger>
                    <SelectValue />
                  </SelectTrigger>
                  <SelectContent>
                    <SelectItem value="one-time">One-time</SelectItem>
                    <SelectItem value="weekly">Weekly</SelectItem>
                    <SelectItem value="monthly">Monthly</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <Button type="button" variant="secondary" className="w-full" onClick={addIncome}>Add Income Stream</Button>
            </div>

            <div className="space-y-2 rounded-xl border border-border p-3">
              <p className="text-xs font-medium uppercase tracking-wide text-muted-foreground">Fixed Costs</p>
              <p className="text-xs text-muted-foreground">Add only the bills you know are locked in.</p>
              <div className="space-y-2">
                {fixedCosts.map((item) => (
                  <div key={item.id} className="flex items-center justify-between text-sm">
                    <span>{item.name}</span>
                    <span>{formatFromUSD(item.amount)}</span>
                  </div>
                ))}
              </div>
              <p className="text-xs text-muted-foreground">Total essentials: {formatFromUSD(fixedCostsTotal)}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
        <Card className="rounded-3xl border-border bg-card/90">
          <CardHeader>
            <CardTitle className="text-base">Social Budgeting</CardTitle>
            <p className="text-sm text-muted-foreground">Plan nights out and trips with realistic cost ranges, then see the impact before you go.</p>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 gap-2 md:grid-cols-2">
              <Input placeholder="Plan title" value={newSocialTitle} onChange={(e) => setNewSocialTitle(e.target.value)} />
              <Input type="date" value={newSocialDate} onChange={(e) => setNewSocialDate(e.target.value)} />
              <Input type="number" placeholder="Low" value={newSocialLow} onChange={(e) => setNewSocialLow(e.target.value)} />
              <Input type="number" placeholder="Realistic" value={newSocialRealistic} onChange={(e) => setNewSocialRealistic(e.target.value)} />
              <Input type="number" placeholder="Stretch" value={newSocialStretch} onChange={(e) => setNewSocialStretch(e.target.value)} />
              <Input type="number" min="1" placeholder="Split count" value={newSocialSplit} onChange={(e) => setNewSocialSplit(e.target.value)} />
            </div>
            <Textarea placeholder="Optional note: who is joining, transport plan, etc." value={newSocialNote} onChange={(e) => setNewSocialNote(e.target.value)} />
            <Button type="button" onClick={addSocialPlan} className="w-full">Add Social Plan</Button>

            <div className="rounded-xl border border-border p-3">
              <p className="text-sm font-medium">If all realistic plans happen:</p>
              <p className="text-xs text-muted-foreground">Your daily spendable adjusts to {formatFromUSD(postSocialDaily)}.</p>
            </div>

            <div className="space-y-2">
              {socialPlans.slice(0, 4).map((plan) => (
                <div key={plan.id} className="rounded-xl border border-border p-3">
                  <div className="flex items-center justify-between">
                    <p className="font-medium">{plan.title}</p>
                    <Badge variant="secondary">{format(parseISO(plan.date), "MMM d")}</Badge>
                  </div>
                  <p className="text-sm text-muted-foreground">
                    Your share: {formatFromUSD(plan.realisticEstimate / Math.max(1, plan.splitCount))} (realistic)
                  </p>
                </div>
              ))}
            </div>
          </CardContent>
        </Card>

        <Card className="rounded-3xl border-border bg-card/90">
          <CardHeader>
            <CardTitle className="text-base">Loan Runway Visualizer</CardTitle>
            <p className="text-sm text-muted-foreground">Make your lump sum last all semester with a clear burn-rate view.</p>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 gap-2 md:grid-cols-2">
              <div className="space-y-1.5">
                <Label>Loan lump sum</Label>
                <Input type="number" min="0" value={loanLumpSum} onChange={(e) => setLoanLumpSum(Math.max(0, Number(e.target.value) || 0))} />
              </div>
              <div className="space-y-1.5">
                <Label>Safety buffer</Label>
                <Input type="number" min="0" value={loanSafetyBuffer} onChange={(e) => setLoanSafetyBuffer(Math.max(0, Number(e.target.value) || 0))} />
              </div>
            </div>

            <div className="space-y-2 rounded-xl border border-border p-3">
              <p className="text-sm">Remaining runway: <span className="font-semibold">{runwayWeeks.toFixed(1)} weeks</span></p>
              <Progress value={runwayProgress} />
              <p className="text-xs text-muted-foreground">You have {weeksRemaining.toFixed(1)} semester weeks left.</p>
            </div>

            <div className="grid grid-cols-2 gap-3 text-sm">
              <div className="rounded-xl border border-border p-3">
                <p className="text-xs text-muted-foreground">Current weekly burn</p>
                <p className="font-semibold">{formatFromUSD(burnRate)}</p>
              </div>
              <div className="rounded-xl border border-border p-3">
                <p className="text-xs text-muted-foreground">Suggested weekly cap</p>
                <p className="font-semibold">{formatFromUSD(recommendedWeeklyCap)}</p>
              </div>
            </div>

            <p className="rounded-xl bg-secondary/40 p-3 text-sm text-muted-foreground">
              If your pace is above the cap, trimming around 10-15% on flexible spend should keep finals week safer.
            </p>
          </CardContent>
        </Card>
      </div>

      <Card className="rounded-3xl border-border bg-card/90">
        <CardHeader>
          <CardTitle className="text-base">Bloom Streaks</CardTitle>
          <p className="text-sm text-muted-foreground">Stay under your daily plan for 3 days in a row to earn a streak badge.</p>
        </CardHeader>
        <CardContent className="flex flex-col gap-4 md:flex-row md:items-center md:justify-between">
          <div>
            <p className="text-sm text-muted-foreground">Current streak</p>
            <p className="text-3xl font-semibold">{currentStreak} day{currentStreak === 1 ? "" : "s"}</p>
            {currentStreak >= 3 && <Badge className="mt-2">3-Day Bloom Streak</Badge>}
          </div>
          <div className="space-y-2">
            <Button type="button" onClick={markTodayOnTrack}>Mark Today On Track</Button>
            <p className="text-xs text-muted-foreground">No penalties. Missed days just restart softly.</p>
          </div>
        </CardContent>
      </Card>
    </div>
  );
};
