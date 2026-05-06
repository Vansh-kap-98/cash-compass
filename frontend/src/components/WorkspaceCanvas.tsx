import { useEffect, useMemo, useRef, useState } from "react";
import {
  closestCenter,
  DndContext,
  DragOverlay,
  PointerSensor,
  useSensor,
  useSensors,
  type DragEndEvent,
  type DragStartEvent,
} from "@dnd-kit/core";
import {
  SortableContext,
  arrayMove,
  rectSortingStrategy,
  useSortable,
} from "@dnd-kit/sortable";
import { CSS } from "@dnd-kit/utilities";
import { GripVertical, ImagePlus, Plus, RectangleHorizontal, Trash2, Settings, TrendingUp, AlertTriangle, Users, Sparkles, Zap, MessageCircle, PlusCircle } from "lucide-react";
import { useCurrency } from "@/contexts/CurrencyContext";
import { useFinance } from "@/contexts/FinanceContext";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";
import { LineChart, Line, XAxis, YAxis, CartesianGrid, Tooltip, ResponsiveContainer, PieChart, Pie, Cell } from "recharts";
import gsap from "gsap";

type WidgetType = 
  | "budget-health" 
  | "top-categories" 
  | "today-snapshot" 
  | "goal-progress" 
  | "media"
  | "safe-to-spend"
  | "sub-stash-jar"
  | "burn-rate-line"
  | "waste-auditor"
  | "roommate-sync"
  | "manga-status"
  | "ascii-fortune"
  | "chibi-mascot"
  | "quick-entry-pad"
  | "3d-growth-gem";

interface WorkspaceWidget {
  id: string;
  type: WidgetType;
  colSpan: number;
  rowSpan: number;
  mediaDataUrl?: string;
}

interface ResizeState {
  id: string;
  startX: number;
  startY: number;
  startColSpan: number;
  startRowSpan: number;
}

const STORAGE_KEY = "cash-compass-workspace-v3";
const GRID_COLUMNS = 12;
const GRID_GAP_PX = 16;
const GRID_ROW_PX = 96;

const widgetLabels: Record<WidgetType, string> = {
  "today-snapshot": "Today Snapshot",
  "budget-health": "Budget Health",
  "top-categories": "Top Categories",
  "goal-progress": "Goal Progress",
  media: "Image",
  "safe-to-spend": "Safe-to-Spend",
  "sub-stash-jar": "Sub-Stash Jar",
  "burn-rate-line": "Burn-Rate Line",
  "waste-auditor": "Waste Auditor",
  "roommate-sync": "Roommate Sync",
  "manga-status": "Manga Status",
  "ascii-fortune": "ASCII Fortune",
  "chibi-mascot": "Chibi Mascot",
  "quick-entry-pad": "Quick-Entry Pad",
  "3d-growth-gem": "3D Growth Gem",
};

const defaultSpan: Record<WidgetType, { col: number; row: number }> = {
  "today-snapshot": { col: 3, row: 2 },
  "budget-health": { col: 3, row: 2 },
  "top-categories": { col: 3, row: 2 },
  "goal-progress": { col: 3, row: 2 },
  media: { col: 3, row: 2 },
  "safe-to-spend": { col: 3, row: 2 },
  "sub-stash-jar": { col: 3, row: 2 },
  "burn-rate-line": { col: 3, row: 2 },
  "waste-auditor": { col: 3, row: 2 },
  "roommate-sync": { col: 3, row: 2 },
  "manga-status": { col: 3, row: 2 },
  "ascii-fortune": { col: 3, row: 2 },
  "chibi-mascot": { col: 3, row: 2 },
  "quick-entry-pad": { col: 3, row: 2 },
  "3d-growth-gem": { col: 3, row: 2 },
};

const clamp = (value: number, min: number, max: number) => Math.min(max, Math.max(min, value));

const WidgetShell = ({
  children,
  isDragging,
}: {
  children: React.ReactNode;
  isDragging?: boolean;
}) => (
  <div
    className={`h-full w-full rounded-2xl border border-white/35 bg-white/15 p-4 backdrop-blur-xl transition-all duration-300 ${
      isDragging ? "shadow-2xl ring-2 ring-primary/40" : "shadow-lg"
    }`}
  >
    {children}
  </div>
);

const WidgetPreview = ({ widget, content }: { widget: WorkspaceWidget; content: React.ReactNode }) => (
  <div
    style={{
      gridColumn: `span ${widget.colSpan} / span ${widget.colSpan}`,
      gridRow: `span ${widget.rowSpan} / span ${widget.rowSpan}`,
    }}
    className="h-full"
  >
    <WidgetShell isDragging>{content}</WidgetShell>
  </div>
);

const SortableWidget = ({
  widget,
  content,
  onRemove,
  onResizeStart,
  onUploadMedia,
}: {
  widget: WorkspaceWidget;
  content: React.ReactNode;
  onRemove: (id: string) => void;
  onResizeStart: (widget: WorkspaceWidget, event: React.MouseEvent<HTMLButtonElement>) => void;
  onUploadMedia: (id: string, file: File | null) => void;
}) => {
  const {
    attributes,
    listeners,
    setNodeRef,
    transform,
    transition,
    isDragging,
  } = useSortable({ id: widget.id });

  const mediaInputId = `workspace-media-${widget.id}`;

  const style: React.CSSProperties = {
    transform: CSS.Transform.toString(transform),
    transition: transition ?? "transform 300ms ease",
    gridColumn: `span ${widget.colSpan} / span ${widget.colSpan}`,
    gridRow: `span ${widget.rowSpan} / span ${widget.rowSpan}`,
    zIndex: isDragging ? 40 : 1,
  };

  return (
    <div ref={setNodeRef} style={style} className="relative min-h-[120px]">
      <WidgetShell isDragging={isDragging}>
        {widget.type !== "media" && (
          <div className="mb-3 flex items-center justify-between">
            <div className="flex items-center gap-2 text-sm font-semibold text-foreground">
              <GripVertical className="h-4 w-4 text-muted-foreground" {...attributes} {...listeners} />
              {widgetLabels[widget.type]}
            </div>
            <Badge variant="secondary">{widget.colSpan}x{widget.rowSpan}</Badge>
          </div>
        )}

        {widget.type === "media" ? (
          <div className="relative h-full min-h-[130px] overflow-hidden rounded-xl border border-white/35 bg-white/10">
            <label
              htmlFor={mediaInputId}
              className="absolute left-2 top-2 z-20 inline-flex h-8 w-8 cursor-pointer items-center justify-center rounded-lg border border-white/35 bg-black/25 text-white backdrop-blur"
              title="Upload image or GIF"
            >
              <ImagePlus className="h-4 w-4" />
            </label>
            <input
              id={mediaInputId}
              className="hidden"
              type="file"
              accept="image/*,.gif"
              onChange={(event) => onUploadMedia(widget.id, event.target.files?.[0] ?? null)}
            />
            {widget.mediaDataUrl ? (
              <img src={widget.mediaDataUrl} alt="" className="h-full w-full object-cover" draggable={false} />
            ) : (
              <div className="h-full w-full bg-gradient-to-br from-white/25 to-white/5" />
            )}
          </div>
        ) : (
          <div className="h-[calc(100%-2rem)] rounded-xl border border-white/25 bg-white/10 p-3">
            {content}
          </div>
        )}
      </WidgetShell>

      <div className="absolute right-3 top-3 z-30 flex items-center gap-2">
        {widget.type === "media" && (
          <div className="rounded-md border border-white/40 bg-black/25 p-1 text-white" {...attributes} {...listeners}>
            <GripVertical className="h-3.5 w-3.5" />
          </div>
        )}
      </div>

      <div className="absolute bottom-2 right-2 z-30 flex items-center gap-1">
        <button
          type="button"
          onClick={() => onRemove(widget.id)}
          className="rounded-md border border-white/35 bg-black/20 p-1 text-white backdrop-blur transition-colors hover:bg-black/35"
          aria-label="Remove widget"
        >
          <Trash2 className="h-3.5 w-3.5" />
        </button>
        <button
          type="button"
          onMouseDown={(event) => onResizeStart(widget, event)}
          className="rounded-md border border-white/35 bg-black/25 p-1 text-white backdrop-blur transition-colors hover:bg-black/35"
          aria-label="Resize widget"
        >
          <RectangleHorizontal className="h-3.5 w-3.5" />
        </button>
      </div>

      {isDragging && <div className="pointer-events-none absolute inset-0 rounded-2xl border-2 border-dashed border-primary/60" />}
    </div>
  );
};

export const WorkspaceCanvas = () => {
  const { formatFromUSD } = useCurrency();
  const { transactions, budgets, goals, manualSpentToday } = useFinance();

  const [widgets, setWidgets] = useState<WorkspaceWidget[]>(() => {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    try {
      const parsed = JSON.parse(raw) as WorkspaceWidget[];
      return Array.isArray(parsed) ? parsed : [];
    } catch {
      return [];
    }
  });
  const [activeId, setActiveId] = useState<string | null>(null);
  const [resizeState, setResizeState] = useState<ResizeState | null>(null);
  const [showAllWidgets, setShowAllWidgets] = useState(false);
  const gridRef = useRef<HTMLDivElement | null>(null);

  const sensors = useSensors(useSensor(PointerSensor, { activationConstraint: { distance: 5 } }));

  useEffect(() => {
    localStorage.setItem(STORAGE_KEY, JSON.stringify(widgets));
  }, [widgets]);

  useEffect(() => {
    if (!resizeState) return;

    const onMove = (event: MouseEvent) => {
      const gridWidth = Math.max(600, gridRef.current?.clientWidth ?? 600);
      const usableWidth = gridWidth - GRID_GAP_PX * (GRID_COLUMNS - 1);
      const colUnit = usableWidth / GRID_COLUMNS;
      const colStep = colUnit + GRID_GAP_PX;
      const rowStep = GRID_ROW_PX + GRID_GAP_PX;

      const deltaX = event.clientX - resizeState.startX;
      const deltaY = event.clientY - resizeState.startY;

      const nextColSpan = clamp(resizeState.startColSpan + Math.round(deltaX / colStep), 2, GRID_COLUMNS);
      const nextRowSpan = clamp(resizeState.startRowSpan + Math.round(deltaY / rowStep), 1, 6);

      setWidgets((prev) =>
        prev.map((widget) =>
          widget.id === resizeState.id
            ? { ...widget, colSpan: nextColSpan, rowSpan: nextRowSpan }
            : widget,
        ),
      );
    };

    const onUp = () => setResizeState(null);

    window.addEventListener("mousemove", onMove);
    window.addEventListener("mouseup", onUp);
    return () => {
      window.removeEventListener("mousemove", onMove);
      window.removeEventListener("mouseup", onUp);
    };
  }, [resizeState]);

  const expenseByCategory = useMemo(() => {
    return transactions
      .filter((tx) => tx.type === "expense")
      .reduce<Record<string, number>>((acc, tx) => {
        acc[tx.category] = (acc[tx.category] ?? 0) + tx.amount;
        return acc;
      }, {});
  }, [transactions]);

  const addWidget = (type: WidgetType, mediaDataUrl?: string) => {
    const span = defaultSpan[type];
    setWidgets((prev) => [
      ...prev,
      {
        id: `widget-${Date.now()}-${Math.random().toString(36).slice(2, 8)}`,
        type,
        colSpan: span.col,
        rowSpan: span.row,
        mediaDataUrl,
      },
    ]);
  };

  const removeWidget = (id: string) => {
    setWidgets((prev) => prev.filter((widget) => widget.id !== id));
  };

  const updateWidgetMedia = (id: string, file: File | null) => {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      const dataUrl = typeof reader.result === "string" ? reader.result : undefined;
      if (!dataUrl) return;
      setWidgets((prev) => prev.map((widget) => (widget.id === id ? { ...widget, mediaDataUrl: dataUrl } : widget)));
    };
    reader.readAsDataURL(file);
  };

  const handleAddMediaWidget = (file: File | null) => {
    if (!file) return;
    const reader = new FileReader();
    reader.onload = () => {
      const dataUrl = typeof reader.result === "string" ? reader.result : undefined;
      addWidget("media", dataUrl);
    };
    reader.readAsDataURL(file);
  };

  const onDragStart = (event: DragStartEvent) => {
    setActiveId(String(event.active.id));
  };

  const onDragEnd = (event: DragEndEvent) => {
    const { active, over } = event;
    setActiveId(null);
    if (!over || active.id === over.id) return;

    setWidgets((prev) => {
      const oldIndex = prev.findIndex((widget) => widget.id === active.id);
      const newIndex = prev.findIndex((widget) => widget.id === over.id);
      if (oldIndex < 0 || newIndex < 0) return prev;
      return arrayMove(prev, oldIndex, newIndex);
    });
  };

  const activeWidget = widgets.find((widget) => widget.id === activeId) ?? null;

  const renderWidgetContainer = (widget: WorkspaceWidget) => {
    // Original widgets
    if (widget.type === "today-snapshot") {
      return <p className="text-sm text-muted-foreground">Spent today: {formatFromUSD(manualSpentToday ?? 0)}</p>;
    }

    if (widget.type === "budget-health") {
      return (
        <div className="space-y-2 text-sm">
          {budgets.slice(0, 3).map((budget) => {
            const spent = expenseByCategory[budget.name] ?? 0;
            const ratio = budget.monthlyLimit > 0 ? (spent / budget.monthlyLimit) * 100 : 0;
            return (
              <div key={budget.id} className="flex items-center justify-between rounded-lg border border-white/20 bg-white/10 p-2">
                <span>{budget.name}</span>
                <Badge variant="secondary">{ratio.toFixed(0)}%</Badge>
              </div>
            );
          })}
        </div>
      );
    }

    if (widget.type === "top-categories") {
      const sorted = Object.entries(expenseByCategory).sort((a, b) => b[1] - a[1]).slice(0, 3);
      return (
        <div className="space-y-2 text-sm">
          {sorted.map(([name, value]) => (
            <div key={name} className="flex items-center justify-between rounded-lg border border-white/20 bg-white/10 p-2">
              <span>{name}</span>
              <span>{formatFromUSD(value)}</span>
            </div>
          ))}
        </div>
      );
    }

    if (widget.type === "goal-progress") {
      return (
        <div className="space-y-2 text-sm">
          {goals.slice(0, 3).map((goal) => {
            const pct = Math.min(100, (goal.current / goal.target) * 100);
            return (
              <div key={goal.id} className="rounded-lg border border-white/20 bg-white/10 p-2">
                <div className="mb-1 flex items-center justify-between">
                  <span>{goal.name}</span>
                  <span>{pct.toFixed(0)}%</span>
                </div>
                <div className="h-2 rounded-full bg-white/20">
                  <div className="h-2 rounded-full bg-primary" style={{ width: `${pct}%` }} />
                </div>
              </div>
            );
          })}
        </div>
      );
    }

    // New widgets
    if (widget.type === "safe-to-spend") {
      const monthlyIncome = transactions
        .filter((tx) => tx.type === "income")
        .reduce((sum, tx) => sum + tx.amount, 0) || 3000;
      const dailyBudget = (monthlyIncome * 0.55) / 30;
      const safeToSpend = Math.max(0, dailyBudget - (manualSpentToday ?? 0));
      return (
        <div className="flex flex-col items-center justify-center gap-3 h-full">
          <div className="relative w-20 h-20 rounded-full border-4 border-green-400/40 bg-green-400/10 flex items-center justify-center">
            <svg className="w-16 h-16" viewBox="0 0 100 100">
              <circle cx="50" cy="50" r="45" fill="none" stroke="rgba(34,197,94,0.2)" strokeWidth="2" />
              <circle
                cx="50"
                cy="50"
                r="45"
                fill="none"
                stroke="#22c55e"
                strokeWidth="3"
                strokeDasharray={`${(safeToSpend / dailyBudget) * 283} 283`}
                strokeLinecap="round"
                style={{ transform: "rotate(-90deg)", transformOrigin: "50% 50%", transition: "all 0.3s" }}
              />
            </svg>
            <span className="absolute text-xs font-bold text-green-400">{(safeToSpend / dailyBudget * 100).toFixed(0)}%</span>
          </div>
          <div className="text-center">
            <p className="text-xs text-muted-foreground">Safe to Spend</p>
            <p className="text-sm font-bold">{formatFromUSD(safeToSpend)}</p>
          </div>
        </div>
      );
    }

    if (widget.type === "sub-stash-jar") {
      const totalSavings = goals.reduce((sum, goal) => sum + goal.current, 0);
      return (
        <div className="flex flex-col items-center justify-between h-full">
          <div className="text-xs text-muted-foreground font-semibold">Sub-Stash Jar</div>
          <div className="relative w-12 h-20 border-2 border-amber-400/60 rounded-b-2xl rounded-t-md bg-amber-400/20 overflow-hidden flex items-center justify-center">
            <div
              className="absolute bottom-0 left-0 right-0 bg-gradient-to-t from-amber-400 to-amber-300 transition-all duration-500"
              style={{ height: `${Math.min(100, (totalSavings / 5000) * 100)}%` }}
            />
            <span className="absolute text-xs font-bold text-amber-900 z-10">{Math.floor(totalSavings / 100)}</span>
          </div>
          <Button
            size="sm"
            variant="outline"
            className="mt-2 h-7 text-xs"
            onClick={() => {
              gsap.fromTo(".sub-stash-boost", { scale: 1 }, { scale: 1.2, duration: 0.3, yoyo: true, repeat: 1 });
            }}
          >
            Boost +$5
          </Button>
          <div className="text-xs text-muted-foreground mt-1">{formatFromUSD(totalSavings)}</div>
        </div>
      );
    }

    if (widget.type === "burn-rate-line") {
      const last7Days = Array.from({ length: 7 }, (_, i) => {
        const date = new Date();
        date.setDate(date.getDate() - (6 - i));
        const dayExpenses = transactions
          .filter((tx) => tx.type === "expense" && new Date(tx.date).toDateString() === date.toDateString())
          .reduce((sum, tx) => sum + tx.amount, 0);
        return { date: date.toLocaleDateString("en-US", { month: "short", day: "numeric" }), burn: dayExpenses };
      });
      return (
        <ResponsiveContainer width="100%" height="100%">
          <LineChart data={last7Days} margin={{ top: 5, right: 5, left: -20, bottom: 5 }}>
            <CartesianGrid strokeDasharray="3 3" stroke="rgba(255,255,255,0.1)" />
            <XAxis dataKey="date" tick={{ fontSize: 10 }} stroke="rgba(255,255,255,0.5)" />
            <YAxis tick={{ fontSize: 10 }} stroke="rgba(255,255,255,0.5)" />
            <Tooltip contentStyle={{ backgroundColor: "rgba(0,0,0,0.5)", border: "1px solid rgba(255,255,255,0.2)" }} />
            <Line type="monotone" dataKey="burn" stroke="#f97316" strokeWidth={2} dot={{ r: 3 }} />
          </LineChart>
        </ResponsiveContainer>
      );
    }

    if (widget.type === "waste-auditor") {
      const subscriptions = [
        { name: "Streaming", cost: 15.99, canceled: false },
        { name: "Cloud Storage", cost: 9.99, canceled: false },
        { name: "Gym", cost: 49.99, canceled: false },
      ];
      return (
        <div className="space-y-2 text-xs">
          {subscriptions.map((sub, idx) => (
            <div key={idx} className="flex items-center justify-between rounded border border-red-400/30 bg-red-400/10 p-2">
              <div className="flex-1">
                <p className="font-semibold">{sub.name}</p>
                <p className="text-red-300">{formatFromUSD(sub.cost)}/mo</p>
              </div>
              <Button size="sm" variant="ghost" className="h-6 px-2 text-xs">
                ✕
              </Button>
            </div>
          ))}
        </div>
      );
    }

    if (widget.type === "roommate-sync") {
      const sharedExpenses = [
        { person: "Alex", amount: 45.50, settled: false },
        { person: "Jordan", amount: -32.00, settled: false },
      ];
      return (
        <div className="space-y-2 h-full flex flex-col justify-between text-sm">
          <div className="space-y-2">
            {sharedExpenses.map((exp, idx) => (
              <div key={idx} className="flex items-center justify-between rounded border border-blue-400/30 bg-blue-400/10 p-2">
                <div className="flex items-center gap-2">
                  <Users className="h-4 w-4 text-blue-300" />
                  <span>{exp.person}</span>
                </div>
                <span className={exp.amount > 0 ? "text-red-300" : "text-green-300"}>
                  {exp.amount > 0 ? "owed " : "owes "}{formatFromUSD(Math.abs(exp.amount))}
                </span>
              </div>
            ))}
          </div>
          <Button size="sm" className="w-full mt-2">
            Settle Up
          </Button>
        </div>
      );
    }

    if (widget.type === "manga-status") {
      const totalSavingsPercentage = Math.min(100, goals.length > 0 ? goals.reduce((sum, g) => sum + (g.current / g.target) * 100, 0) / goals.length : 0);
      const charStage = Math.floor(totalSavingsPercentage / 25);
      const stageEmoji = ["😔", "😐", "😊", "😄", "🤩"][charStage];
      return (
        <div className="flex flex-col items-center justify-center h-full gap-3">
          <div className="text-6xl">{stageEmoji}</div>
          <div className="text-center">
            <p className="text-xs text-muted-foreground">Savings Progress</p>
            <p className="text-lg font-bold">{totalSavingsPercentage.toFixed(0)}%</p>
          </div>
          <div className="w-full h-2 rounded-full bg-white/10 overflow-hidden">
            <div className="h-full bg-gradient-to-r from-pink-400 to-purple-400" style={{ width: `${totalSavingsPercentage}%` }} />
          </div>
        </div>
      );
    }

    if (widget.type === "ascii-fortune") {
      const fortunes = [
        "💰 A penny saved is a penny earned",
        "📈 Small steps lead to big gains",
        "🎯 Goals achieved with patience",
        "💡 Smart spending = Happy future",
        "🚀 Invest in yourself today",
      ];
      const today = new Date().toDateString();
      const fortuneIndex = today.charCodeAt(0) % fortunes.length;
      return (
        <div className="h-full flex items-center justify-center font-mono text-xs leading-relaxed text-center p-2">
          <div className="bg-black/20 p-3 rounded border border-white/20">{fortunes[fortuneIndex]}</div>
        </div>
      );
    }

    if (widget.type === "chibi-mascot") {
      return (
        <div className="flex items-center justify-center h-full cursor-pointer text-4xl hover:scale-110 transition-transform" title="Click for a surprise!">
          🤖
        </div>
      );
    }

    if (widget.type === "quick-entry-pad") {
      const topCategories = Object.entries(expenseByCategory)
        .sort((a, b) => b[1] - a[1])
        .slice(0, 3)
        .map(([name]) => name);
      return (
        <div className="space-y-2 h-full">
          <input type="number" placeholder="Amount" className="w-full px-2 py-1 rounded bg-white/10 border border-white/20 text-sm" />
          <div className="space-y-1">
            {topCategories.map((cat, idx) => (
              <Button key={idx} size="sm" variant="secondary" className="w-full text-xs">
                {cat}
              </Button>
            ))}
          </div>
        </div>
      );
    }

    if (widget.type === "3d-growth-gem") {
      const totalSavings = goals.reduce((sum, goal) => sum + goal.current, 0);
      const gemSize = Math.min(80, 30 + (totalSavings / 10000) * 50);
      return (
        <div className="flex items-center justify-center h-full">
          <svg width={gemSize} height={gemSize} viewBox="0 0 100 100" className="animate-spin" style={{ animationDuration: "4s" }}>
            <polygon points="50,10 90,40 90,70 50,90 10,70 10,40" fill="url(#gemGradient)" stroke="rgba(168,85,247,0.6)" strokeWidth="2" />
            <defs>
              <linearGradient id="gemGradient" x1="0%" y1="0%" x2="100%" y2="100%">
                <stop offset="0%" style={{ stopColor: "#c084fc", stopOpacity: 1 }} />
                <stop offset="100%" style={{ stopColor: "#7c3aed", stopOpacity: 1 }} />
              </linearGradient>
            </defs>
          </svg>
          <div className="absolute text-center">
            <p className="text-xs font-bold">{formatFromUSD(totalSavings)}</p>
          </div>
        </div>
      );
    }

    return null;
  };

  return (
    <div className="space-y-5">
      <div className="rounded-2xl border border-white/35 bg-white/20 p-4 backdrop-blur-xl shadow-lg">
        <div className="space-y-3">
          <div className="flex items-center justify-between">
            <div className="font-semibold text-sm">Add Widgets</div>
            <Button
              type="button"
              variant="ghost"
              size="sm"
              onClick={() => setShowAllWidgets(!showAllWidgets)}
              className="h-7 text-xs"
            >
              {showAllWidgets ? "Show Less" : "View All"}
            </Button>
          </div>
          <div className="flex flex-wrap items-center gap-2">
            {/* Original widgets */}
            <Button type="button" className="gap-2" onClick={() => addWidget("today-snapshot")}>
              <Plus className="h-4 w-4" />
              Today
            </Button>
            <Button type="button" variant="secondary" onClick={() => addWidget("budget-health")}>Budget</Button>
            <Button type="button" variant="secondary" onClick={() => addWidget("top-categories")}>Categories</Button>
            <Button type="button" variant="secondary" onClick={() => addWidget("goal-progress")}>Goals</Button>

            {/* New functional widgets - always shown */}
            <Button type="button" variant="outline" onClick={() => addWidget("safe-to-spend")}>
              <TrendingUp className="h-3.5 w-3.5" />
              Safe-to-Spend
            </Button>
            <Button type="button" variant="outline" onClick={() => addWidget("sub-stash-jar")}>
              <Sparkles className="h-3.5 w-3.5" />
              Sub-Stash
            </Button>

            {/* Additional widgets - show only when expanded */}
            {showAllWidgets && (
              <>
                <Button type="button" variant="outline" onClick={() => addWidget("burn-rate-line")}>
                  <AlertTriangle className="h-3.5 w-3.5" />
                  Burn-Rate
                </Button>
                <Button type="button" variant="outline" onClick={() => addWidget("waste-auditor")}>
                  <Zap className="h-3.5 w-3.5" />
                  Waste Audit
                </Button>
                <Button type="button" variant="outline" onClick={() => addWidget("roommate-sync")}>
                  <Users className="h-3.5 w-3.5" />
                  Roommate
                </Button>

                {/* Aesthetic & tool widgets */}
                <Button type="button" variant="outline" onClick={() => addWidget("manga-status")}>
                  Manga Status
                </Button>
                <Button type="button" variant="outline" onClick={() => addWidget("ascii-fortune")}>
                  ASCII Fortune
                </Button>
                <Button type="button" variant="outline" onClick={() => addWidget("chibi-mascot")}>
                  🤖 Mascot
                </Button>
                <Button type="button" variant="outline" onClick={() => addWidget("quick-entry-pad")}>
                  <MessageCircle className="h-3.5 w-3.5" />
                  Quick-Entry
                </Button>
                <Button type="button" variant="outline" onClick={() => addWidget("3d-growth-gem")}>
                  ✨ Gem
                </Button>

                {/* Media & Clear */}
                <label className="inline-flex cursor-pointer items-center rounded-md border border-input bg-background px-3 py-2 text-sm font-medium transition-colors hover:bg-accent">
                  Add Image
                  <input
                    className="hidden"
                    type="file"
                    accept="image/*,.gif"
                    onChange={(event) => handleAddMediaWidget(event.target.files?.[0] ?? null)}
                  />
                </label>
                <Button type="button" variant="outline" onClick={() => setWidgets([])}>Clear</Button>
              </>
            )}
          </div>
        </div>
      </div>

      {widgets.length === 0 && (
        <div className="rounded-2xl border border-dashed border-white/40 bg-white/10 py-16 text-center backdrop-blur-xl">
          <button
            type="button"
            onClick={() => addWidget("today-snapshot")}
            className="mx-auto inline-flex h-14 w-14 items-center justify-center rounded-full border border-white/40 bg-white/25 text-foreground shadow-lg transition-transform duration-300 hover:scale-105"
            aria-label="Add first widget"
          >
            <Plus className="h-6 w-6" />
          </button>
          <p className="mt-4 text-sm text-muted-foreground">Start building your dashboard workspace.</p>
        </div>
      )}

      <DndContext
        sensors={sensors}
        collisionDetection={closestCenter}
        onDragStart={onDragStart}
        onDragEnd={onDragEnd}
      >
        <SortableContext items={widgets.map((widget) => widget.id)} strategy={rectSortingStrategy}>
          <div ref={gridRef} className="grid grid-cols-12 auto-rows-[96px] gap-4">
            {widgets.map((widget) => (
              <SortableWidget
                key={widget.id}
                widget={widget}
                content={renderWidgetContainer(widget)}
                onRemove={removeWidget}
                onUploadMedia={updateWidgetMedia}
                onResizeStart={(item, event) => {
                  event.preventDefault();
                  event.stopPropagation();
                  setResizeState({
                    id: item.id,
                    startX: event.clientX,
                    startY: event.clientY,
                    startColSpan: item.colSpan,
                    startRowSpan: item.rowSpan,
                  });
                }}
              />
            ))}
          </div>
        </SortableContext>

        <DragOverlay>
          {activeWidget ? (
            <WidgetPreview widget={activeWidget} content={activeWidget.type === "media" ? <div className="h-full rounded-xl bg-white/15" /> : renderWidgetContainer(activeWidget)} />
          ) : null}
        </DragOverlay>
      </DndContext>
    </div>
  );
};
