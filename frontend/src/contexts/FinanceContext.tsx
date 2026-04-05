import React, { createContext, useContext, useMemo, useState } from "react";

export type TransactionType = "income" | "expense";

export interface FinanceTransaction {
  id: string;
  name: string;
  amount: number;
  type: TransactionType;
  category: string;
  date: string;
  note?: string;
  icon?: string;
}

export interface SavingsGoal {
  id: string;
  name: string;
  current: number;
  target: number;
  icon: string;
}

export interface BudgetCategory {
  id: string;
  name: string;
  monthlyLimit: number;
}

interface AddTransactionInput {
  name: string;
  amount: number;
  type: TransactionType;
  category: string;
  date: string;
  note?: string;
}

interface AddGoalInput {
  name: string;
  target: number;
  initialAmount?: number;
  icon?: string;
}

interface FinanceState {
  startingBalance: number;
  manualBalance: number | null;
  manualIncomeToDate: number | null;
  manualSpentToday: number | null;
  transactions: FinanceTransaction[];
  goals: SavingsGoal[];
  budgets: BudgetCategory[];
}

interface FinanceContextType {
  startingBalance: number;
  manualBalance: number | null;
  manualIncomeToDate: number | null;
  manualSpentToday: number | null;
  transactions: FinanceTransaction[];
  goals: SavingsGoal[];
  budgets: BudgetCategory[];
  setStartingBalance: (value: number) => void;
  setManualSnapshot: (snapshot: { balance: number | null; incomeToDate: number | null; spentToday: number | null }) => void;
  addTransaction: (input: AddTransactionInput) => void;
  addGoal: (input: AddGoalInput) => void;
  contributeToGoal: (goalId: string, amount: number) => void;
  upsertBudget: (name: string, monthlyLimit: number) => void;
}

const STORAGE_KEY = "cash-compass-finance-v1";

const todayIso = new Date().toISOString().slice(0, 10);

const getDateInPast = (daysAgo: number) => {
  const date = new Date();
  date.setDate(date.getDate() - daysAgo);
  return date.toISOString().slice(0, 10);
};

const categoryIcons: Record<string, string> = {
  Income: "💰",
  Salary: "🏦",
  Freelance: "💼",
  Groceries: "🛒",
  Transport: "🚗",
  Housing: "🏠",
  Utilities: "💡",
  Entertainment: "🎬",
  Food: "🍽️",
  Shopping: "🛍️",
  Health: "🩺",
  Travel: "✈️",
  Education: "📚",
  Savings: "🪙",
};

const defaultState: FinanceState = {
  startingBalance: 12000,
  manualBalance: null,
  manualIncomeToDate: null,
  manualSpentToday: null,
  transactions: [
    {
      id: "tx-1",
      name: "Salary Deposit",
      amount: 4200,
      type: "income",
      category: "Salary",
      date: getDateInPast(21),
      icon: "🏦",
    },
    {
      id: "tx-2",
      name: "Freelance Work",
      amount: 850,
      type: "income",
      category: "Freelance",
      date: getDateInPast(18),
      icon: "💼",
    },
    {
      id: "tx-3",
      name: "Rent",
      amount: 1400,
      type: "expense",
      category: "Housing",
      date: getDateInPast(17),
      icon: "🏠",
    },
    {
      id: "tx-4",
      name: "Grocery Store",
      amount: 128.5,
      type: "expense",
      category: "Groceries",
      date: getDateInPast(5),
      icon: "🛒",
    },
    {
      id: "tx-5",
      name: "Netflix",
      amount: 15.99,
      type: "expense",
      category: "Entertainment",
      date: getDateInPast(4),
      icon: "🎬",
    },
    {
      id: "tx-6",
      name: "Coffee & Co.",
      amount: 5.4,
      type: "expense",
      category: "Food",
      date: getDateInPast(2),
      icon: "☕",
    },
    {
      id: "tx-7",
      name: "Bus Pass",
      amount: 56,
      type: "expense",
      category: "Transport",
      date: getDateInPast(1),
      icon: "🚌",
    },
  ],
  goals: [
    { id: "goal-1", name: "Emergency Fund", current: 8500, target: 10000, icon: "🛡️" },
    { id: "goal-2", name: "Japan Trip", current: 3200, target: 5000, icon: "✈️" },
    { id: "goal-3", name: "New Laptop", current: 1800, target: 2200, icon: "💻" },
  ],
  budgets: [
    { id: "budget-1", name: "Housing", monthlyLimit: 1500 },
    { id: "budget-2", name: "Groceries", monthlyLimit: 500 },
    { id: "budget-3", name: "Transport", monthlyLimit: 250 },
    { id: "budget-4", name: "Entertainment", monthlyLimit: 220 },
    { id: "budget-5", name: "Food", monthlyLimit: 300 },
  ],
};

const FinanceContext = createContext<FinanceContextType | undefined>(undefined);

const readState = (): FinanceState => {
  const raw = localStorage.getItem(STORAGE_KEY);
  if (!raw) return defaultState;

  try {
    const parsed = JSON.parse(raw) as FinanceState;
    if (!parsed || !Array.isArray(parsed.transactions) || !Array.isArray(parsed.goals) || !Array.isArray(parsed.budgets)) {
      return defaultState;
    }
    return {
      ...defaultState,
      ...parsed,
      manualBalance: Number.isFinite(parsed.manualBalance ?? NaN) ? parsed.manualBalance : defaultState.manualBalance,
      manualIncomeToDate: Number.isFinite(parsed.manualIncomeToDate ?? NaN) ? parsed.manualIncomeToDate : defaultState.manualIncomeToDate,
      manualSpentToday: Number.isFinite(parsed.manualSpentToday ?? NaN) ? parsed.manualSpentToday : defaultState.manualSpentToday,
    };
  } catch {
    return defaultState;
  }
};

export const FinanceProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [state, setState] = useState<FinanceState>(readState);

  const persist = (next: FinanceState) => {
    setState(next);
    localStorage.setItem(STORAGE_KEY, JSON.stringify(next));
  };

  const setStartingBalance = (value: number) => {
    persist({
      ...state,
      startingBalance: Number.isFinite(value) ? Math.max(0, value) : state.startingBalance,
    });
  };

  const setManualSnapshot = (snapshot: { balance: number | null; incomeToDate: number | null; spentToday: number | null }) => {
    persist({
      ...state,
      manualBalance: snapshot.balance !== null && Number.isFinite(snapshot.balance) ? Math.max(0, snapshot.balance) : null,
      manualIncomeToDate: snapshot.incomeToDate !== null && Number.isFinite(snapshot.incomeToDate) ? Math.max(0, snapshot.incomeToDate) : null,
      manualSpentToday: snapshot.spentToday !== null && Number.isFinite(snapshot.spentToday) ? Math.max(0, snapshot.spentToday) : null,
    });
  };

  const addTransaction = (input: AddTransactionInput) => {
    const cleanAmount = Math.max(0, Number(input.amount) || 0);
    if (cleanAmount <= 0) return;

    const icon = categoryIcons[input.category] ?? (input.type === "income" ? "💰" : "💸");
    const next: FinanceState = {
      ...state,
      transactions: [
        {
          id: `tx-${Date.now()}`,
          name: input.name.trim() || "Manual Entry",
          amount: cleanAmount,
          type: input.type,
          category: input.category.trim() || (input.type === "income" ? "Income" : "Other"),
          date: input.date || todayIso,
          note: input.note?.trim() || undefined,
          icon,
        },
        ...state.transactions,
      ],
    };
    persist(next);
  };

  const addGoal = (input: AddGoalInput) => {
    const target = Math.max(1, Number(input.target) || 0);
    const current = Math.max(0, Math.min(Number(input.initialAmount) || 0, target));

    const next: FinanceState = {
      ...state,
      goals: [
        {
          id: `goal-${Date.now()}`,
          name: input.name.trim() || "New Goal",
          target,
          current,
          icon: input.icon?.trim() || "🎯",
        },
        ...state.goals,
      ],
    };
    persist(next);
  };

  const contributeToGoal = (goalId: string, amount: number) => {
    const contribution = Math.max(0, Number(amount) || 0);
    if (contribution <= 0) return;

    const next: FinanceState = {
      ...state,
      goals: state.goals.map((goal) => {
        if (goal.id !== goalId) return goal;
        return {
          ...goal,
          current: Math.min(goal.target, goal.current + contribution),
        };
      }),
    };
    persist(next);
  };

  const upsertBudget = (name: string, monthlyLimit: number) => {
    const cleanName = name.trim();
    const limit = Math.max(0, Number(monthlyLimit) || 0);
    if (!cleanName || limit <= 0) return;

    const match = state.budgets.find((budget) => budget.name.toLowerCase() === cleanName.toLowerCase());

    const nextBudgets = match
      ? state.budgets.map((budget) =>
          budget.id === match.id
            ? {
                ...budget,
                monthlyLimit: limit,
              }
            : budget,
        )
      : [{ id: `budget-${Date.now()}`, name: cleanName, monthlyLimit: limit }, ...state.budgets];

    persist({
      ...state,
      budgets: nextBudgets,
    });
  };

  const value = useMemo(
    () => ({
      startingBalance: state.startingBalance,
      manualBalance: state.manualBalance,
      manualIncomeToDate: state.manualIncomeToDate,
      manualSpentToday: state.manualSpentToday,
      transactions: state.transactions,
      goals: state.goals,
      budgets: state.budgets,
      setStartingBalance,
      setManualSnapshot,
      addTransaction,
      addGoal,
      contributeToGoal,
      upsertBudget,
    }),
    [state],
  );

  return <FinanceContext.Provider value={value}>{children}</FinanceContext.Provider>;
};

export const useFinance = () => {
  const ctx = useContext(FinanceContext);
  if (!ctx) throw new Error("useFinance must be used within FinanceProvider");
  return ctx;
};
