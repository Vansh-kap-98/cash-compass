import { useMemo, useState } from "react";
import { motion } from "framer-motion";
import { Plus, Target, CalendarIcon, SlidersHorizontal } from "lucide-react";
import { format } from "date-fns";
import { useFinance, type TransactionType } from "@/contexts/FinanceContext";
import { Dialog, DialogContent, DialogDescription, DialogHeader, DialogTitle } from "@/components/ui/dialog";
import { Tabs, TabsContent, TabsList, TabsTrigger } from "@/components/ui/tabs";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Textarea } from "@/components/ui/textarea";
import { Button } from "@/components/ui/button";
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select";
import { Popover, PopoverContent, PopoverTrigger } from "@/components/ui/popover";
import { Calendar } from "@/components/ui/calendar";
import { toast } from "@/components/ui/use-toast";
import { useCurrency } from "@/contexts/CurrencyContext";

const expenseCategories = [
  "Housing",
  "Groceries",
  "Transport",
  "Entertainment",
  "Food",
  "Utilities",
  "Shopping",
  "Health",
  "Travel",
  "Education",
  "Other",
];

const incomeCategories = ["Salary", "Freelance", "Investment", "Business", "Gift", "Other"];

export const QuickActions = () => {
  const { formatFromUSD } = useCurrency();
  const {
    startingBalance,
    transactions,
    goals,
    budgets,
    setStartingBalance,
    addTransaction,
    addGoal,
    upsertBudget,
  } = useFinance();

  const [open, setOpen] = useState(false);

  const [txType, setTxType] = useState<TransactionType>("expense");
  const [txName, setTxName] = useState("");
  const [txAmount, setTxAmount] = useState("");
  const [txCategory, setTxCategory] = useState("Groceries");
  const [txDate, setTxDate] = useState<Date>(new Date());
  const [txNote, setTxNote] = useState("");

  const [goalName, setGoalName] = useState("");
  const [goalTarget, setGoalTarget] = useState("");
  const [goalInitial, setGoalInitial] = useState("");
  const [goalIcon, setGoalIcon] = useState("🎯");

  const [budgetName, setBudgetName] = useState("Groceries");
  const [budgetLimit, setBudgetLimit] = useState("");
  const [manualBalance, setManualBalance] = useState(String(startingBalance));

  const latestTransactions = useMemo(
    () => [...transactions].sort((a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()).slice(0, 5),
    [transactions],
  );

  const resetTransactionForm = () => {
    setTxName("");
    setTxAmount("");
    setTxCategory(txType === "income" ? "Salary" : "Groceries");
    setTxDate(new Date());
    setTxNote("");
  };

  const handleAddTransaction = () => {
    const amount = Number(txAmount);
    if (!txName.trim() || !Number.isFinite(amount) || amount <= 0) {
      toast({ title: "Invalid transaction", description: "Please provide a name and a valid amount." });
      return;
    }

    addTransaction({
      name: txName,
      amount,
      type: txType,
      category: txCategory,
      date: txDate.toISOString().slice(0, 10),
      note: txNote,
    });

    resetTransactionForm();
    toast({ title: "Transaction added", description: "Your entry has been saved." });
  };

  const handleAddGoal = () => {
    const target = Number(goalTarget);
    const initial = Number(goalInitial || 0);

    if (!goalName.trim() || !Number.isFinite(target) || target <= 0) {
      toast({ title: "Invalid goal", description: "Please add a goal name and target amount." });
      return;
    }

    addGoal({
      name: goalName,
      target,
      initialAmount: Number.isFinite(initial) ? initial : 0,
      icon: goalIcon || "🎯",
    });

    setGoalName("");
    setGoalTarget("");
    setGoalInitial("");
    setGoalIcon("🎯");

    toast({ title: "Goal added", description: "Savings goal is now tracked." });
  };

  const handleBudgetSave = () => {
    const limit = Number(budgetLimit);
    if (!budgetName.trim() || !Number.isFinite(limit) || limit <= 0) {
      toast({ title: "Invalid budget", description: "Provide a category and monthly limit." });
      return;
    }

    upsertBudget(budgetName, limit);
    setBudgetLimit("");
    toast({ title: "Budget saved", description: `${budgetName} budget updated.` });
  };

  const handleBalanceUpdate = () => {
    const value = Number(manualBalance);
    if (!Number.isFinite(value) || value < 0) {
      toast({ title: "Invalid balance", description: "Starting balance must be zero or greater." });
      return;
    }
    setStartingBalance(value);
    toast({ title: "Balance updated", description: "Starting balance has been updated." });
  };

  return (
    <>
      <Dialog open={open} onOpenChange={setOpen}>
        <DialogContent className="max-h-[90vh] overflow-y-auto sm:max-w-3xl">
          <DialogHeader>
            <DialogTitle>Manual Money Manager</DialogTitle>
            <DialogDescription>
              Add incomes, expenses, goals, budgets, and dates manually. All entries update the dashboard instantly.
            </DialogDescription>
          </DialogHeader>

          <Tabs defaultValue="records" className="w-full">
            <TabsList className="grid w-full grid-cols-3">
              <TabsTrigger value="records">Daily Records</TabsTrigger>
              <TabsTrigger value="goals">Goals</TabsTrigger>
              <TabsTrigger value="planning">Planning</TabsTrigger>
            </TabsList>

            <TabsContent value="records" className="space-y-5">
              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="tx-type">Type</Label>
                  <Select
                    value={txType}
                    onValueChange={(next) => {
                      const type = next as TransactionType;
                      setTxType(type);
                      setTxCategory(type === "income" ? "Salary" : "Groceries");
                    }}
                  >
                    <SelectTrigger id="tx-type">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      <SelectItem value="expense">Expense</SelectItem>
                      <SelectItem value="income">Income</SelectItem>
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2">
                  <Label htmlFor="tx-date">Date</Label>
                  <Popover>
                    <PopoverTrigger asChild>
                      <Button id="tx-date" type="button" variant="outline" className="w-full justify-start text-left font-normal">
                        <CalendarIcon className="mr-2 h-4 w-4" />
                        {format(txDate, "PPP")}
                      </Button>
                    </PopoverTrigger>
                    <PopoverContent className="w-auto p-0" align="start">
                      <Calendar mode="single" selected={txDate} onSelect={(date) => date && setTxDate(date)} initialFocus />
                    </PopoverContent>
                  </Popover>
                </div>

                <div className="space-y-2 md:col-span-2">
                  <Label htmlFor="tx-name">Name</Label>
                  <Input id="tx-name" placeholder="e.g. Grocery run" value={txName} onChange={(event) => setTxName(event.target.value)} />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="tx-amount">Amount</Label>
                  <Input
                    id="tx-amount"
                    type="number"
                    min="0"
                    step="0.01"
                    value={txAmount}
                    onChange={(event) => setTxAmount(event.target.value)}
                    placeholder="0.00"
                  />
                </div>

                <div className="space-y-2">
                  <Label htmlFor="tx-category">Category</Label>
                  <Select value={txCategory} onValueChange={setTxCategory}>
                    <SelectTrigger id="tx-category">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {(txType === "income" ? incomeCategories : expenseCategories).map((category) => (
                        <SelectItem key={category} value={category}>{category}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>

                <div className="space-y-2 md:col-span-2">
                  <Label htmlFor="tx-note">Note</Label>
                  <Textarea
                    id="tx-note"
                    placeholder="Optional note about this transaction"
                    value={txNote}
                    onChange={(event) => setTxNote(event.target.value)}
                  />
                </div>
              </div>

              <div className="flex items-center justify-between rounded-md border p-3 text-xs text-muted-foreground">
                <p>Recent manual entries</p>
                <p>{transactions.length} total</p>
              </div>

              <div className="space-y-2 rounded-md border p-3">
                {latestTransactions.map((tx) => (
                  <div key={tx.id} className="flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">{tx.name}</span>
                    <span className={tx.type === "expense" ? "text-destructive" : "text-primary"}>
                      {tx.type === "expense" ? "-" : "+"}{formatFromUSD(tx.amount)}
                    </span>
                  </div>
                ))}
              </div>

              <Button type="button" className="w-full" onClick={handleAddTransaction}>Save Transaction</Button>
            </TabsContent>

            <TabsContent value="goals" className="space-y-5">
              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="goal-name">Goal name</Label>
                  <Input id="goal-name" value={goalName} onChange={(event) => setGoalName(event.target.value)} placeholder="Emergency fund" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="goal-icon">Icon</Label>
                  <Input id="goal-icon" value={goalIcon} onChange={(event) => setGoalIcon(event.target.value)} placeholder="🎯" />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="goal-target">Target amount</Label>
                  <Input
                    id="goal-target"
                    type="number"
                    min="1"
                    step="0.01"
                    value={goalTarget}
                    onChange={(event) => setGoalTarget(event.target.value)}
                    placeholder="5000"
                  />
                </div>
                <div className="space-y-2">
                  <Label htmlFor="goal-initial">Initial saved</Label>
                  <Input
                    id="goal-initial"
                    type="number"
                    min="0"
                    step="0.01"
                    value={goalInitial}
                    onChange={(event) => setGoalInitial(event.target.value)}
                    placeholder="1000"
                  />
                </div>
              </div>

              <div className="rounded-md border p-3 space-y-2">
                {goals.map((goal) => {
                  const progress = Math.min(100, Math.round((goal.current / goal.target) * 100));
                  return (
                    <div key={goal.id} className="space-y-1">
                      <div className="flex items-center justify-between text-sm">
                        <span className="text-muted-foreground">{goal.icon} {goal.name}</span>
                        <span>{progress}%</span>
                      </div>
                      <div className="h-2 rounded-full bg-secondary">
                        <div className="h-2 rounded-full bg-primary" style={{ width: `${progress}%` }} />
                      </div>
                    </div>
                  );
                })}
              </div>

              <Button type="button" className="w-full" onClick={handleAddGoal}>Create Goal</Button>
            </TabsContent>

            <TabsContent value="planning" className="space-y-5">
              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="start-balance">Starting balance</Label>
                  <Input
                    id="start-balance"
                    type="number"
                    min="0"
                    step="0.01"
                    value={manualBalance}
                    onChange={(event) => setManualBalance(event.target.value)}
                  />
                </div>
                <div className="flex items-end">
                  <Button type="button" className="w-full" variant="secondary" onClick={handleBalanceUpdate}>
                    Update Balance
                  </Button>
                </div>
              </div>

              <div className="grid grid-cols-1 gap-4 md:grid-cols-2">
                <div className="space-y-2">
                  <Label htmlFor="budget-name">Budget category</Label>
                  <Select value={budgetName} onValueChange={setBudgetName}>
                    <SelectTrigger id="budget-name">
                      <SelectValue />
                    </SelectTrigger>
                    <SelectContent>
                      {expenseCategories.map((category) => (
                        <SelectItem key={category} value={category}>{category}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2">
                  <Label htmlFor="budget-limit">Monthly limit</Label>
                  <Input
                    id="budget-limit"
                    type="number"
                    min="1"
                    step="0.01"
                    value={budgetLimit}
                    onChange={(event) => setBudgetLimit(event.target.value)}
                    placeholder="500"
                  />
                </div>
              </div>

              <Button type="button" className="w-full" onClick={handleBudgetSave}>Save Budget</Button>

              <div className="rounded-md border p-3 space-y-2">
                {budgets.map((budget) => (
                  <div key={budget.id} className="flex items-center justify-between text-sm">
                    <span className="text-muted-foreground">{budget.name}</span>
                    <span>{formatFromUSD(budget.monthlyLimit)}</span>
                  </div>
                ))}
              </div>
            </TabsContent>
          </Tabs>
        </DialogContent>
      </Dialog>

      <div className="fixed bottom-6 right-6 flex flex-col gap-3 z-50">
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95, transition: { type: "spring", stiffness: 400, damping: 10 } }}
        className="flex items-center gap-2 bg-primary text-primary-foreground px-4 py-2.5 rounded-lg shadow-card-hover text-sm font-medium font-heading"
        onClick={() => setOpen(true)}
      >
        <Plus className="w-4 h-4" />
        Add Entry
      </motion.button>
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95, transition: { type: "spring", stiffness: 400, damping: 10 } }}
        className="flex items-center gap-2 bg-secondary text-secondary-foreground px-4 py-2.5 rounded-lg shadow-card text-sm font-medium font-heading"
        onClick={() => setOpen(true)}
      >
        <Target className="w-4 h-4" />
        Set Goal
      </motion.button>
      <motion.button
        whileHover={{ scale: 1.05 }}
        whileTap={{ scale: 0.95, transition: { type: "spring", stiffness: 400, damping: 10 } }}
        className="flex items-center gap-2 bg-card text-card-foreground px-4 py-2.5 rounded-lg border border-border shadow-card text-sm font-medium font-heading"
        onClick={() => setOpen(true)}
      >
        <SlidersHorizontal className="w-4 h-4" />
        Plan Budget
      </motion.button>
      </div>
    </>
  );
};
