import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Plus, Target, CalendarIcon, SlidersHorizontal, X, Minus, GripHorizontal, MapPin, Plane, Users, Utensils } from "lucide-react";
import { format } from "date-fns";
import { useFinance, type TransactionType } from "@/contexts/FinanceContext";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Calendar } from "@/components/ui/calendar";
import { toast } from "@/components/ui/use-toast";
import { useCurrency } from "@/contexts/CurrencyContext";
import { Badge } from "@/components/ui/badge";

const expenseCategories = ["Housing","Groceries","Transport","Entertainment","Food","Utilities","Shopping","Health","Travel","Education","Other"];
const incomeCategories = ["Salary","Freelance","Investment","Business","Gift","Other"];

type RecurrenceType = "none" | "daily" | "weekly" | "biweekly" | "monthly" | "yearly";
type GoalPeriod = "1-month" | "3-months" | "6-months" | "1-year" | "2-years" | "custom";
type BudgetPlanType = "trip" | "outing" | "event";

interface BudgetLineItem { id: string; name: string; estimate: number; }
interface FinalizedBudgetPlan {
  id: string;
  title: string;
  planType: BudgetPlanType;
  dateFrom: string;
  dateTo?: string;
  people: number;
  items: BudgetLineItem[];
  total: number;
  perPerson: number;
  createdAt: string;
}

const BUDGET_PLANS_KEY = "cash-compass-budget-plans-v1";

export const QuickActions = () => {
  const { formatFromUSD, formatAmount, convertFromUSD, convertToUSD, currency } = useCurrency();
  const { transactions, goals, addTransaction, addGoal } = useFinance();

  // ── Add Entry state ──
  const [entryOpen, setEntryOpen] = useState(false);
  const [txType, setTxType] = useState<TransactionType>("expense");
  const [txName, setTxName] = useState("");
  const [txAmount, setTxAmount] = useState("");
  const [txCategory, setTxCategory] = useState("Groceries");
  const [txDate, setTxDate] = useState<Date>(new Date());
  const [txNote, setTxNote] = useState("");
  const [txRecurrence, setTxRecurrence] = useState<RecurrenceType>("none");

  // ── Set Goal state ──
  const [goalOpen, setGoalOpen] = useState(false);
  const [goalName, setGoalName] = useState("");
  const [goalTarget, setGoalTarget] = useState("");
  const [goalInitial, setGoalInitial] = useState("");
  const [goalIcon, setGoalIcon] = useState("🎯");
  const [goalPeriod, setGoalPeriod] = useState<GoalPeriod>("6-months");
  const [goalCustomDays, setGoalCustomDays] = useState("90");

  // ── Plan Budget state ──
  const [budgetOpen, setBudgetOpen] = useState(false);
  const [budgetMinimized, setBudgetMinimized] = useState(false);
  const [budgetPlanType, setBudgetPlanType] = useState<BudgetPlanType>("trip");
  const [budgetTitle, setBudgetTitle] = useState("");
  const [budgetDateFrom, setBudgetDateFrom] = useState(format(new Date(), "yyyy-MM-dd"));
  const [budgetDateTo, setBudgetDateTo] = useState("");
  const [budgetPeople, setBudgetPeople] = useState("1");
  const [budgetItems, setBudgetItems] = useState<BudgetLineItem[]>([]);
  const [newItemName, setNewItemName] = useState("");
  const [newItemEstimate, setNewItemEstimate] = useState("");
  const [finalizedPlans, setFinalizedPlans] = useState<FinalizedBudgetPlan[]>(() => {
    const raw = localStorage.getItem(BUDGET_PLANS_KEY);
    if (!raw) return [];
    try {
      const parsed = JSON.parse(raw) as FinalizedBudgetPlan[];
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  });

  // Drag state for budget planner
  const [dragPos, setDragPos] = useState({ x: 0, y: 0 });
  const dragRef = useRef<HTMLDivElement>(null);
  const isDragging = useRef(false);
  const dragStart = useRef({ x: 0, y: 0, posX: 0, posY: 0 });

  const onDragMouseDown = useCallback((e: React.MouseEvent) => {
    isDragging.current = true;
    dragStart.current = { x: e.clientX, y: e.clientY, posX: dragPos.x, posY: dragPos.y };
    e.preventDefault();
  }, [dragPos]);

  useEffect(() => {
    const onMove = (e: MouseEvent) => {
      if (!isDragging.current) return;
      setDragPos({
        x: dragStart.current.posX + (e.clientX - dragStart.current.x),
        y: dragStart.current.posY + (e.clientY - dragStart.current.y),
      });
    };
    const onUp = () => { isDragging.current = false; };
    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
    return () => { window.removeEventListener("mousemove", onMove); window.removeEventListener("mouseup", onUp); };
  }, []);

  useEffect(() => {
    localStorage.setItem(BUDGET_PLANS_KEY, JSON.stringify(finalizedPlans));
  }, [finalizedPlans]);

  // ── Handlers ──
  const handleAddTransaction = () => {
    const amountInput = Number(txAmount);
    const amount = convertToUSD(amountInput);
    if (!txName.trim() || !Number.isFinite(amountInput) || amountInput <= 0) {
      toast({ title: "Invalid entry", description: "Please provide a name and valid amount." });
      return;
    }
    const noteWithRecurrence = txRecurrence !== "none"
      ? `${txNote ? txNote + " | " : ""}Recurring: ${txRecurrence}`
      : txNote;

    addTransaction({ name: txName, amount, type: txType, category: txCategory, date: txDate.toISOString().slice(0, 10), note: noteWithRecurrence });
    setTxName(""); setTxAmount(""); setTxNote(""); setTxRecurrence("none");
    setTxCategory(txType === "income" ? "Salary" : "Groceries");
    toast({ title: "Entry saved", description: txRecurrence !== "none" ? `Recurring ${txRecurrence} entry added.` : "Transaction recorded." });
  };

  const goalDays = useMemo(() => {
    const map: Record<GoalPeriod, number> = { "1-month": 30, "3-months": 90, "6-months": 180, "1-year": 365, "2-years": 730, custom: Number(goalCustomDays) || 90 };
    return map[goalPeriod];
  }, [goalPeriod, goalCustomDays]);

  const handleAddGoal = () => {
    const targetInput = Number(goalTarget);
    const initialInput = Number(goalInitial || 0);
    const target = convertToUSD(targetInput);
    const initial = convertToUSD(initialInput);
    if (!goalName.trim() || !Number.isFinite(targetInput) || targetInput <= 0) {
      toast({ title: "Invalid goal", description: "Add a goal name and target amount." });
      return;
    }
    addGoal({ name: goalName, target, initialAmount: Number.isFinite(initial) ? initial : 0, icon: goalIcon || "🎯" });
    setGoalName(""); setGoalTarget(""); setGoalInitial(""); setGoalIcon("🎯");
    toast({ title: "Goal created", description: `Save ${formatAmount(targetInput)} in ${goalDays} days — that's ~${formatAmount(targetInput / goalDays)}/day.` });
  };

  const dailySavingsNeeded = useMemo(() => {
    const t = Number(goalTarget);
    const i = Number(goalInitial || 0);
    if (!t || goalDays <= 0) return 0;
    return Math.max(0, (t - i) / goalDays);
  }, [goalTarget, goalInitial, goalDays]);

  const budgetTotal = useMemo(() => budgetItems.reduce((s, i) => s + i.estimate, 0), [budgetItems]);
  const perPerson = useMemo(() => budgetTotal / Math.max(1, Number(budgetPeople) || 1), [budgetTotal, budgetPeople]);

  const addBudgetItem = () => {
    const est = Number(newItemEstimate);
    if (!newItemName.trim() || !est || est <= 0) return;
    setBudgetItems(prev => [...prev, { id: `bi-${Date.now()}`, name: newItemName.trim(), estimate: est }]);
    setNewItemName(""); setNewItemEstimate("");
  };

  const removeBudgetItem = (id: string) => setBudgetItems(prev => prev.filter(i => i.id !== id));

  const clearBudgetDraft = () => {
    setBudgetTitle("");
    setBudgetDateTo("");
    setBudgetPeople("1");
    setBudgetItems([]);
    setNewItemName("");
    setNewItemEstimate("");
  };

  const finalizeBudgetPlan = () => {
    const people = Math.max(1, Number(budgetPeople) || 1);
    if (!budgetTitle.trim()) {
      toast({ title: "Plan title required", description: "Add a plan title before finalising." });
      return;
    }
    if (budgetItems.length === 0) {
      toast({ title: "No items added", description: "Add at least one budget item to generate a bill and receipt." });
      return;
    }
    if (budgetDateTo && budgetDateTo < budgetDateFrom) {
      toast({ title: "Invalid dates", description: "End date cannot be before start date." });
      return;
    }

    const total = budgetItems.reduce((sum, item) => sum + item.estimate, 0);
    const finalizedPlan: FinalizedBudgetPlan = {
      id: `bp-${Date.now()}`,
      title: budgetTitle.trim(),
      planType: budgetPlanType,
      dateFrom: budgetDateFrom,
      dateTo: budgetDateTo || undefined,
      people,
      items: budgetItems,
      total,
      perPerson: total / people,
      createdAt: new Date().toISOString(),
    };

    setFinalizedPlans((prev) => [finalizedPlan, ...prev]);
    toast({ title: "Budget finalised", description: `Bill created: ${formatAmount(finalizedPlan.total)}${people > 1 ? ` total, ${formatAmount(finalizedPlan.perPerson)} each.` : "."}` });
    clearBudgetDraft();
  };

  const planTypeConfig: Record<BudgetPlanType, { icon: React.ReactNode; label: string }> = {
    trip: { icon: <Plane className="w-3.5 h-3.5" />, label: "Trip" },
    outing: { icon: <Utensils className="w-3.5 h-3.5" />, label: "Outing" },
    event: { icon: <Users className="w-3.5 h-3.5" />, label: "Event" },
  };

  return (
    <>
      {/* ═══ ADD ENTRY DIALOG ═══ */}
      <Dialog open={entryOpen} onOpenChange={setEntryOpen}>
        <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>Add Entry</DialogTitle>
            <DialogDescription>Log an expense or income. Mark recurring charges to track them.</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label>Type</Label>
                <Select value={txType} onValueChange={(v) => { setTxType(v as TransactionType); setTxCategory(v === "income" ? "Salary" : "Groceries"); }}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    <SelectItem value="expense">Expense</SelectItem>
                    <SelectItem value="income">Income</SelectItem>
                  </SelectContent>
                </Select>
              </div>
              <div className="space-y-1.5">
                <Label>Date</Label>
                <Popover>
                  <PopoverTrigger asChild>
                    <Button type="button" variant="outline" className="w-full justify-start text-left font-normal text-sm">
                      <CalendarIcon className="mr-2 h-3.5 w-3.5" />{format(txDate, "PPP")}
                    </Button>
                  </PopoverTrigger>
                  <PopoverContent className="w-auto p-0" align="start">
                    <Calendar mode="single" selected={txDate} onSelect={(d) => d && setTxDate(d)} initialFocus />
                  </PopoverContent>
                </Popover>
              </div>
            </div>
            <div className="space-y-1.5">
              <Label>Name</Label>
              <Input placeholder="e.g. Grocery run" value={txName} onChange={(e) => setTxName(e.target.value)} />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label>Amount ({currency})</Label>
                <Input type="number" min="0" step="0.01" value={txAmount} onChange={(e) => setTxAmount(e.target.value)} placeholder="0.00" />
              </div>
              <div className="space-y-1.5">
                <Label>Category</Label>
                <Select value={txCategory} onValueChange={setTxCategory}>
                  <SelectTrigger><SelectValue /></SelectTrigger>
                  <SelectContent>
                    {(txType === "income" ? incomeCategories : expenseCategories).map((c) => (
                      <SelectItem key={c} value={c}>{c}</SelectItem>
                    ))}
                  </SelectContent>
                </Select>
              </div>
            </div>

            {/* Recurring toggle */}
            <div className="rounded-xl border border-border p-3 space-y-2">
              <Label className="text-xs uppercase tracking-wide text-muted-foreground">Is this recurring?</Label>
              <div className="flex flex-wrap gap-1.5">
                {(["none","daily","weekly","biweekly","monthly","yearly"] as RecurrenceType[]).map(r => (
                  <button
                    key={r}
                    type="button"
                    onClick={() => setTxRecurrence(r)}
                    className={`px-2.5 py-1 rounded-full text-xs font-medium transition-all ${
                      txRecurrence === r
                        ? "bg-primary text-primary-foreground shadow-sm"
                        : "bg-secondary/60 text-muted-foreground hover:bg-secondary"
                    }`}
                  >
                    {r === "none" ? "One-time" : r.charAt(0).toUpperCase() + r.slice(1)}
                  </button>
                ))}
              </div>
              {txRecurrence !== "none" && (
                <p className="text-xs text-muted-foreground mt-1">
                  This will be tagged as a <span className="font-semibold text-foreground">{txRecurrence}</span> recurring charge.
                </p>
              )}
            </div>

            <div className="space-y-1.5">
              <Label>Note (optional)</Label>
              <Textarea placeholder="Any details about this entry" value={txNote} onChange={(e) => setTxNote(e.target.value)} className="h-16" />
            </div>
            <Button type="button" className="w-full" onClick={handleAddTransaction}>Save Entry</Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* ═══ SET GOAL DIALOG ═══ */}
      <Dialog open={goalOpen} onOpenChange={setGoalOpen}>
        <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-lg">
          <DialogHeader>
            <DialogTitle>Set Savings Goal</DialogTitle>
            <DialogDescription>Define how much to save and by when. We'll show you the daily target.</DialogDescription>
          </DialogHeader>
          <div className="space-y-4">
            <div className="grid grid-cols-3 gap-3">
              <div className="col-span-2 space-y-1.5">
                <Label>Goal name</Label>
                <Input value={goalName} onChange={(e) => setGoalName(e.target.value)} placeholder="Emergency fund" />
              </div>
              <div className="space-y-1.5">
                <Label>Icon</Label>
                <Input value={goalIcon} onChange={(e) => setGoalIcon(e.target.value)} placeholder="🎯" className="text-center text-lg" />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-1.5">
                <Label>Target amount ({currency})</Label>
                <Input type="number" min="1" step="0.01" value={goalTarget} onChange={(e) => setGoalTarget(e.target.value)} placeholder="5000" />
              </div>
              <div className="space-y-1.5">
                <Label>Already saved ({currency})</Label>
                <Input type="number" min="0" step="0.01" value={goalInitial} onChange={(e) => setGoalInitial(e.target.value)} placeholder="0" />
              </div>
            </div>

            {/* Time period selector */}
            <div className="rounded-xl border border-border p-3 space-y-2">
              <Label className="text-xs uppercase tracking-wide text-muted-foreground">Time Period</Label>
              <div className="flex flex-wrap gap-1.5">
                {(["1-month","3-months","6-months","1-year","2-years","custom"] as GoalPeriod[]).map(p => (
                  <button
                    key={p}
                    type="button"
                    onClick={() => setGoalPeriod(p)}
                    className={`px-2.5 py-1 rounded-full text-xs font-medium transition-all ${
                      goalPeriod === p
                        ? "bg-primary text-primary-foreground shadow-sm"
                        : "bg-secondary/60 text-muted-foreground hover:bg-secondary"
                    }`}
                  >
                    {p === "custom" ? "Custom" : p.replace("-", " ").replace(/\b\w/g, c => c.toUpperCase())}
                  </button>
                ))}
              </div>
              {goalPeriod === "custom" && (
                <div className="flex items-center gap-2 mt-2">
                  <Input type="number" min="7" value={goalCustomDays} onChange={(e) => setGoalCustomDays(e.target.value)} className="w-24" />
                  <span className="text-xs text-muted-foreground">days</span>
                </div>
              )}
            </div>

            {/* Daily savings preview */}
            {Number(goalTarget) > 0 && (
              <div className="rounded-xl border border-dashed border-primary/40 bg-primary/5 p-3 space-y-1">
                <p className="text-xs text-muted-foreground">To reach your goal in <span className="font-semibold text-foreground">{goalDays} days</span>:</p>
                <p className="text-lg font-bold">{formatAmount(dailySavingsNeeded)} <span className="text-xs font-normal text-muted-foreground">/ day</span></p>
                <p className="text-xs text-muted-foreground">{formatAmount(dailySavingsNeeded * 7)} / week · {formatAmount(dailySavingsNeeded * 30)} / month</p>
              </div>
            )}

            {/* Existing goals */}
            {goals.length > 0 && (
              <div className="rounded-md border p-3 space-y-2">
                <p className="text-xs text-muted-foreground uppercase tracking-wide">Current Goals</p>
                {goals.map((g) => {
                  const pct = Math.min(100, Math.round((g.current / g.target) * 100));
                  return (
                    <div key={g.id} className="space-y-1">
                      <div className="flex items-center justify-between text-sm">
                        <span>{g.icon} {g.name}</span>
                        <span className="text-xs text-muted-foreground">{formatFromUSD(g.current)} / {formatFromUSD(g.target)}</span>
                      </div>
                      <div className="h-1.5 rounded-full bg-secondary"><div className="h-1.5 rounded-full bg-primary" style={{ width: `${pct}%` }} /></div>
                    </div>
                  );
                })}
              </div>
            )}

            <Button type="button" className="w-full" onClick={handleAddGoal}>Create Goal</Button>
          </div>
        </DialogContent>
      </Dialog>

      {/* ═══ PLAN BUDGET — DRAGGABLE POPUP ═══ */}
      <AnimatePresence>
        {budgetOpen && !budgetMinimized && (
          <motion.div
            ref={dragRef}
            initial={{ opacity: 0, scale: 0.9, y: 40 }}
            animate={{ opacity: 1, scale: 1, y: 0 }}
            exit={{ opacity: 0, scale: 0.9, y: 40 }}
            transition={{ type: "spring", damping: 25, stiffness: 300 }}
            style={{ transform: `translate(${dragPos.x}px, ${dragPos.y}px)` }}
            className="fixed bottom-20 right-6 z-[60] w-[380px] max-h-[70vh] rounded-2xl border border-border bg-card shadow-2xl overflow-hidden flex flex-col"
          >
            {/* Drag handle + header */}
            <div
              className="flex items-center justify-between px-4 py-3 border-b border-border bg-secondary/30 cursor-grab active:cursor-grabbing select-none"
              onMouseDown={onDragMouseDown}
            >
              <div className="flex items-center gap-2">
                <GripHorizontal className="w-4 h-4 text-muted-foreground" />
                <span className="text-sm font-semibold font-heading">Budget Planner</span>
              </div>
              <div className="flex items-center gap-1">
                <button type="button" onClick={() => setBudgetMinimized(true)} className="p-1 rounded hover:bg-secondary transition-colors" title="Minimize">
                  <Minus className="w-3.5 h-3.5" />
                </button>
                <button type="button" onClick={() => { setBudgetOpen(false); setBudgetMinimized(false); }} className="p-1 rounded hover:bg-secondary transition-colors" title="Close">
                  <X className="w-3.5 h-3.5" />
                </button>
              </div>
            </div>

            {/* Body */}
            <div className="flex-1 overflow-y-auto p-4 space-y-3">
              {/* Plan type */}
              <div className="flex gap-1.5">
                {(["trip","outing","event"] as BudgetPlanType[]).map(t => (
                  <button
                    key={t}
                    type="button"
                    onClick={() => setBudgetPlanType(t)}
                    className={`flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-medium transition-all ${
                      budgetPlanType === t ? "bg-primary text-primary-foreground" : "bg-secondary/60 text-muted-foreground hover:bg-secondary"
                    }`}
                  >
                    {planTypeConfig[t].icon}{planTypeConfig[t].label}
                  </button>
                ))}
              </div>

              <Input placeholder="Plan title (e.g. Goa Weekend)" value={budgetTitle} onChange={(e) => setBudgetTitle(e.target.value)} className="text-sm" />

              <div className="grid grid-cols-2 gap-2">
                <div className="space-y-1">
                  <Label className="text-xs">From</Label>
                  <Input type="date" value={budgetDateFrom} onChange={(e) => setBudgetDateFrom(e.target.value)} className="text-xs" />
                </div>
                <div className="space-y-1">
                  <Label className="text-xs">To</Label>
                  <Input type="date" value={budgetDateTo} onChange={(e) => setBudgetDateTo(e.target.value)} className="text-xs" />
                </div>
              </div>

              <div className="space-y-1">
                <Label className="text-xs">People splitting</Label>
                <Input type="number" min="1" value={budgetPeople} onChange={(e) => setBudgetPeople(e.target.value)} className="text-sm" />
              </div>

              {/* Add line items */}
              <div className="space-y-1.5">
                <Label className="text-xs uppercase tracking-wide text-muted-foreground">Expense Items</Label>
                <div className="flex gap-1.5">
                  <Input placeholder="Item name" value={newItemName} onChange={(e) => setNewItemName(e.target.value)} className="text-xs flex-1" />
                  <Input type="number" placeholder="Cost" min="0" value={newItemEstimate} onChange={(e) => setNewItemEstimate(e.target.value)} className="text-xs w-24" />
                  <Button type="button" size="sm" variant="secondary" onClick={addBudgetItem} className="h-9 px-2">
                    <Plus className="w-3.5 h-3.5" />
                  </Button>
                </div>
              </div>

              {/* Items list */}
              {budgetItems.length > 0 && (
                <div className="space-y-1">
                  {budgetItems.map(item => (
                    <div key={item.id} className="flex items-center justify-between rounded-lg border border-border px-2.5 py-1.5 text-xs">
                      <span>{item.name}</span>
                      <div className="flex items-center gap-2">
                        <span className="font-medium">{formatAmount(item.estimate)}</span>
                        <button type="button" onClick={() => removeBudgetItem(item.id)} className="text-muted-foreground hover:text-destructive transition-colors">
                          <X className="w-3 h-3" />
                        </button>
                      </div>
                    </div>
                  ))}
                </div>
              )}

              {/* Totals */}
              <div className="rounded-xl border border-dashed border-primary/40 bg-primary/5 p-3 space-y-1.5">
                <div className="flex justify-between text-sm">
                  <span className="text-muted-foreground">Total</span>
                  <span className="font-bold">{formatAmount(budgetTotal)}</span>
                </div>
                {Number(budgetPeople) > 1 && (
                  <div className="flex justify-between text-sm">
                    <span className="text-muted-foreground">Per person</span>
                    <span className="font-semibold">{formatAmount(perPerson)}</span>
                  </div>
                )}
                {budgetItems.length === 0 && (
                  <p className="text-xs text-muted-foreground text-center py-2">Add items above to see your budget breakdown</p>
                )}
                <Button type="button" onClick={finalizeBudgetPlan} className="w-full" disabled={budgetItems.length === 0 || !budgetTitle.trim()}>
                  Finalise Bill & Receipt
                </Button>
              </div>

              {finalizedPlans.length > 0 && (
                <div className="rounded-xl border border-border p-3 space-y-2">
                  <div className="flex items-center justify-between">
                    <p className="text-xs uppercase tracking-wide text-muted-foreground">Latest Receipt</p>
                    <Badge variant="secondary">{planTypeConfig[finalizedPlans[0].planType].label}</Badge>
                  </div>
                  <p className="text-sm font-semibold">{finalizedPlans[0].title}</p>
                  <p className="text-xs text-muted-foreground">
                    {finalizedPlans[0].dateFrom}
                    {finalizedPlans[0].dateTo ? ` to ${finalizedPlans[0].dateTo}` : ""}
                  </p>
                  <div className="space-y-1">
                    {finalizedPlans[0].items.map((item) => (
                      <div key={item.id} className="flex items-center justify-between text-xs">
                        <span>{item.name}</span>
                        <span className="font-medium">{formatAmount(item.estimate)}</span>
                      </div>
                    ))}
                  </div>
                  <div className="pt-1 border-t border-border space-y-1 text-xs">
                    <div className="flex items-center justify-between">
                      <span className="text-muted-foreground">Final bill</span>
                      <span className="font-semibold">{formatAmount(finalizedPlans[0].total)}</span>
                    </div>
                    <div className="flex items-center justify-between">
                      <span className="text-muted-foreground">Split ({finalizedPlans[0].people})</span>
                      <span className="font-semibold">{formatAmount(finalizedPlans[0].perPerson)}</span>
                    </div>
                  </div>
                </div>
              )}

              {finalizedPlans.length > 1 && (
                <div className="rounded-xl border border-border p-3 space-y-1.5">
                  <p className="text-xs uppercase tracking-wide text-muted-foreground">Recent Finalised Bills</p>
                  {finalizedPlans.slice(1, 4).map((plan) => (
                    <div key={plan.id} className="flex items-center justify-between text-xs">
                      <span>{plan.title}</span>
                      <span className="font-medium">{formatAmount(plan.total)}</span>
                    </div>
                  ))}
                </div>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* ═══ MINIMIZED TAB (right edge) ═══ */}
      <AnimatePresence>
        {budgetOpen && budgetMinimized && (
          <motion.button
            initial={{ x: 60, opacity: 0 }}
            animate={{ x: 0, opacity: 1 }}
            exit={{ x: 60, opacity: 0 }}
            transition={{ type: "spring", damping: 20, stiffness: 300 }}
            type="button"
            onClick={() => setBudgetMinimized(false)}
            className="fixed right-0 top-1/2 -translate-y-1/2 z-[60] flex items-center gap-2 bg-primary text-primary-foreground pl-3 pr-2 py-3 rounded-l-xl shadow-lg text-xs font-medium writing-mode-vertical"
            style={{ writingMode: "vertical-rl", textOrientation: "mixed" }}
          >
            <SlidersHorizontal className="w-3.5 h-3.5 rotate-90" />
            <span>Budget: {formatAmount(budgetTotal)}</span>
          </motion.button>
        )}
      </AnimatePresence>

      {/* ═══ FAB BUTTONS ═══ */}
      <div className="fixed bottom-6 right-6 flex flex-col gap-3 z-50">
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          className="flex items-center gap-2 bg-primary text-primary-foreground px-4 py-2.5 rounded-lg shadow-card-hover text-sm font-medium font-heading"
          onClick={() => setEntryOpen(true)}
        >
          <Plus className="w-4 h-4" />
          Add Entry
        </motion.button>
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          className="flex items-center gap-2 bg-secondary text-secondary-foreground px-4 py-2.5 rounded-lg shadow-card text-sm font-medium font-heading"
          onClick={() => setGoalOpen(true)}
        >
          <Target className="w-4 h-4" />
          Set Goal
        </motion.button>
        <motion.button
          whileHover={{ scale: 1.05 }}
          whileTap={{ scale: 0.95 }}
          className="flex items-center gap-2 bg-card text-card-foreground px-4 py-2.5 rounded-lg border border-border shadow-card text-sm font-medium font-heading"
          onClick={() => { setBudgetOpen(true); setBudgetMinimized(false); }}
        >
          <SlidersHorizontal className="w-4 h-4" />
          Plan Budget
        </motion.button>
      </div>
    </>
  );
};
