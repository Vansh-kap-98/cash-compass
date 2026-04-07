import { useMemo, useState } from "react";
import { useFinance } from "@/contexts/FinanceContext";
import { useCurrency } from "@/contexts/CurrencyContext";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";

type GeoProfileKey = "us-city" | "india-metro" | "eastern-europe";

interface GeoProfile {
  label: string;
  multiplier: number;
  staples: Array<{ name: string; baseCost: number }>;
}

interface DayPlan {
  id: string;
  title: string;
  estimate: number;
  date: string;
}

const geoProfiles: Record<GeoProfileKey, GeoProfile> = {
  "us-city": {
    label: "US City",
    multiplier: 1,
    staples: [
      { name: "Lunch", baseCost: 16 },
      { name: "Transit", baseCost: 9 },
      { name: "Groceries", baseCost: 22 },
    ],
  },
  "india-metro": {
    label: "India Metro",
    multiplier: 0.48,
    staples: [
      { name: "Lunch", baseCost: 6 },
      { name: "Transit", baseCost: 2.5 },
      { name: "Groceries", baseCost: 10 },
    ],
  },
  "eastern-europe": {
    label: "Eastern Europe",
    multiplier: 0.72,
    staples: [
      { name: "Lunch", baseCost: 11 },
      { name: "Transit", baseCost: 4.5 },
      { name: "Groceries", baseCost: 15 },
    ],
  },
};

export const DashboardPlanner = () => {
  const { formatFromUSD } = useCurrency();
  const { transactions, manualBalance, manualIncomeToDate, manualSpentToday } = useFinance();

  const [geo, setGeo] = useState<GeoProfileKey>("us-city");
  const [planTitle, setPlanTitle] = useState("");
  const [planEstimate, setPlanEstimate] = useState("");
  const [planDate, setPlanDate] = useState(new Date().toISOString().slice(0, 10));
  const [plans, setPlans] = useState<DayPlan[]>([]);

  const today = new Date().toISOString().slice(0, 10);

  const monthlyIncome = useMemo(() => {
    if (manualIncomeToDate !== null) return manualIncomeToDate;

    const now = new Date();
    return transactions
      .filter((tx) => {
        if (tx.type !== "income") return false;
        const txDate = new Date(tx.date);
        return txDate.getMonth() === now.getMonth() && txDate.getFullYear() === now.getFullYear();
      })
      .reduce((sum, tx) => sum + tx.amount, 0);
  }, [manualIncomeToDate, transactions]);

  const spentToday = useMemo(() => {
    if (manualSpentToday !== null) return manualSpentToday;

    return transactions
      .filter((tx) => tx.type === "expense" && tx.date === today)
      .reduce((sum, tx) => sum + tx.amount, 0);
  }, [manualSpentToday, transactions, today]);

  const dailyRecords = useMemo(() => {
    const map = new Map<string, { income: number; expense: number }>();

    for (const tx of transactions) {
      const entry = map.get(tx.date) ?? { income: 0, expense: 0 };
      if (tx.type === "income") entry.income += tx.amount;
      if (tx.type === "expense") entry.expense += tx.amount;
      map.set(tx.date, entry);
    }

    return [...map.entries()]
      .map(([date, totals]) => ({
        date,
        income: totals.income,
        expense: totals.expense,
        net: totals.income - totals.expense,
      }))
      .sort((a, b) => b.date.localeCompare(a.date));
  }, [transactions]);

  const averageSpentPerDay = useMemo(() => {
    if (dailyRecords.length === 0) return 0;
    const totalExpense = dailyRecords.reduce((sum, day) => sum + day.expense, 0);
    return totalExpense / dailyRecords.length;
  }, [dailyRecords]);

  const dailyBudget = useMemo(() => {
    const profile = geoProfiles[geo];
    const base = monthlyIncome > 0 ? (monthlyIncome * 0.55) / 30 : 35;
    return base * profile.multiplier;
  }, [geo, monthlyIncome]);

  const remainingToday = dailyBudget - spentToday;

  const todaysPlans = plans.filter((plan) => plan.date === today);
  const plannedToday = todaysPlans.reduce((sum, plan) => sum + plan.estimate, 0);

  const dayAiSuggestions = useMemo(() => {
    const items: string[] = [];

    if (remainingToday < 0) {
      items.push("You are over today’s budget. Switch to essential-only purchases for the rest of the day.");
    } else if (remainingToday < dailyBudget * 0.25) {
      items.push("You are in the final 25% of your daily budget. Keep only high-priority plan items.");
    } else {
      items.push("You still have comfortable room today. Front-load essentials and delay impulse categories.");
    }

    if (plannedToday > remainingToday) {
      items.push("Your planned spend is above remaining budget. Reduce one plan item by around 20-30%.");
    }

    if (averageSpentPerDay > dailyBudget) {
      items.push("Your average daily spend is above your location-adjusted budget. Try a three-day low-spend streak.");
    }

    if (items.length < 3) {
      items.push("Use category caps for Food and Shopping today to protect tomorrow’s flexibility.");
    }

    return items.slice(0, 3);
  }, [averageSpentPerDay, dailyBudget, plannedToday, remainingToday]);

  const addPlan = () => {
    const estimate = Number(planEstimate);
    if (!planTitle.trim() || !Number.isFinite(estimate) || estimate <= 0) return;

    setPlans((prev) => [
      {
        id: `plan-${Date.now()}`,
        title: planTitle.trim(),
        estimate,
        date: planDate,
      },
      ...prev,
    ]);

    setPlanTitle("");
    setPlanEstimate("");
  };

  return (
    <div className="space-y-6">
      <section className="grid grid-cols-1 gap-4 md:grid-cols-2 xl:grid-cols-4">
        <Card className="rounded-2xl">
          <CardHeader className="pb-2">
            <CardTitle className="text-xs uppercase tracking-wide text-muted-foreground">Total Balance</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-semibold">{formatFromUSD(manualBalance ?? 0)}</p>
          </CardContent>
        </Card>

        <Card className="rounded-2xl">
          <CardHeader className="pb-2">
            <CardTitle className="text-xs uppercase tracking-wide text-muted-foreground">Spent Today</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-semibold">{formatFromUSD(spentToday)}</p>
          </CardContent>
        </Card>

        <Card className="rounded-2xl">
          <CardHeader className="pb-2">
            <CardTitle className="text-xs uppercase tracking-wide text-muted-foreground">Monthly Income</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-semibold">{formatFromUSD(monthlyIncome)}</p>
          </CardContent>
        </Card>

        <Card className="rounded-2xl">
          <CardHeader className="pb-2">
            <CardTitle className="text-xs uppercase tracking-wide text-muted-foreground">Average Spent/Day</CardTitle>
          </CardHeader>
          <CardContent>
            <p className="text-2xl font-semibold">{formatFromUSD(averageSpentPerDay)}</p>
          </CardContent>
        </Card>
      </section>

      <section className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Card className="rounded-2xl">
          <CardHeader>
            <CardTitle className="text-base">Daily Plan Builder</CardTitle>
            <p className="text-sm text-muted-foreground">Create plans for any day and compare with your location-adjusted daily budget.</p>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="grid grid-cols-1 gap-3 md:grid-cols-2">
              <div className="space-y-1.5 md:col-span-2">
                <Label>Plan name</Label>
                <Input value={planTitle} onChange={(e) => setPlanTitle(e.target.value)} placeholder="Groceries and transit" />
              </div>
              <div className="space-y-1.5">
                <Label>Estimated amount</Label>
                <Input type="number" min="0" step="0.01" value={planEstimate} onChange={(e) => setPlanEstimate(e.target.value)} />
              </div>
              <div className="space-y-1.5">
                <Label>Plan date</Label>
                <Input type="date" value={planDate} onChange={(e) => setPlanDate(e.target.value)} />
              </div>
            </div>
            <Button type="button" onClick={addPlan} className="w-full">Add Plan</Button>

            <div className="rounded-xl border border-border p-3 text-sm space-y-2">
              <p>Today planned: <span className="font-semibold">{formatFromUSD(plannedToday)}</span></p>
              <p>Today budget: <span className="font-semibold">{formatFromUSD(dailyBudget)}</span></p>
              <p className={remainingToday >= 0 ? "text-emerald-600" : "text-destructive"}>
                Remaining today: {formatFromUSD(remainingToday)}
              </p>
            </div>

            <div className="space-y-2">
              {todaysPlans.slice(0, 4).map((plan) => (
                <div key={plan.id} className="flex items-center justify-between rounded-xl border border-border p-3 text-sm">
                  <span>{plan.title}</span>
                  <span className="font-medium">{formatFromUSD(plan.estimate)}</span>
                </div>
              ))}
              {todaysPlans.length === 0 && (
                <p className="text-sm text-muted-foreground">No plans added for today yet.</p>
              )}
            </div>
          </CardContent>
        </Card>

        <Card className="rounded-2xl">
          <CardHeader>
            <CardTitle className="text-base">Location Budget Guidance</CardTitle>
            <p className="text-sm text-muted-foreground">Item budgets compare your current spend against your daily cap for your geography.</p>
          </CardHeader>
          <CardContent className="space-y-4">
            <div className="space-y-1.5">
              <Label>Geographical profile</Label>
              <Select value={geo} onValueChange={(value) => setGeo(value as GeoProfileKey)}>
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  {Object.entries(geoProfiles).map(([key, profile]) => (
                    <SelectItem key={key} value={key}>{profile.label}</SelectItem>
                  ))}
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              {geoProfiles[geo].staples.map((item) => {
                const cost = item.baseCost * geoProfiles[geo].multiplier;
                const healthyLimit = Math.max(0, remainingToday * 0.4);
                const affordable = cost <= healthyLimit;
                return (
                  <div key={item.name} className="rounded-xl border border-border p-3 text-sm">
                    <div className="flex items-center justify-between">
                      <span className="font-medium">{item.name}</span>
                      <Badge variant={affordable ? "default" : "secondary"}>{affordable ? "On Budget" : "Trim Needed"}</Badge>
                    </div>
                    <p className="text-muted-foreground mt-1">Typical cost: {formatFromUSD(cost)}</p>
                    <p className="text-muted-foreground">Suggested max now: {formatFromUSD(healthyLimit)}</p>
                  </div>
                );
              })}
            </div>

            <div className="rounded-xl border border-border bg-secondary/40 p-3 text-sm space-y-2">
              <p className="font-medium">AI suggestions for today</p>
              {dayAiSuggestions.map((tip) => (
                <p key={tip} className="text-muted-foreground">• {tip}</p>
              ))}
            </div>
          </CardContent>
        </Card>
      </section>

      <Card className="rounded-2xl">
        <CardHeader>
          <CardTitle className="text-base">All Day Records</CardTitle>
          <p className="text-sm text-muted-foreground">Historical record of daily income and spending.</p>
        </CardHeader>
        <CardContent className="space-y-2">
          {dailyRecords.slice(0, 20).map((day) => (
            <div key={day.date} className="grid grid-cols-2 gap-2 rounded-xl border border-border p-3 text-sm md:grid-cols-4">
              <p>{day.date}</p>
              <p>Income: {formatFromUSD(day.income)}</p>
              <p>Spent: {formatFromUSD(day.expense)}</p>
              <p className={day.net >= 0 ? "text-emerald-600" : "text-destructive"}>Net: {formatFromUSD(day.net)}</p>
            </div>
          ))}
          {dailyRecords.length === 0 && <p className="text-sm text-muted-foreground">No records yet. Add entries to start building your history.</p>}
        </CardContent>
      </Card>
    </div>
  );
};
