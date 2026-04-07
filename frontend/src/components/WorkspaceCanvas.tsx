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
import { GripVertical, ImagePlus, Plus, RectangleHorizontal, Trash2 } from "lucide-react";
import { useCurrency } from "@/contexts/CurrencyContext";
import { useFinance } from "@/contexts/FinanceContext";
import { Button } from "@/components/ui/button";
import { Badge } from "@/components/ui/badge";

type WidgetType = "budget-health" | "top-categories" | "today-snapshot" | "goal-progress" | "media";

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
};

const defaultSpan: Record<WidgetType, { col: number; row: number }> = {
  "today-snapshot": { col: 4, row: 2 },
  "budget-health": { col: 4, row: 3 },
  "top-categories": { col: 4, row: 3 },
  "goal-progress": { col: 4, row: 3 },
  media: { col: 6, row: 3 },
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
        <button
          type="button"
          onClick={() => onRemove(widget.id)}
          className="rounded-md border border-white/35 bg-black/20 p-1 text-white backdrop-blur transition-colors hover:bg-black/35"
          aria-label="Remove widget"
        >
          <Trash2 className="h-3.5 w-3.5" />
        </button>
      </div>

      <button
        type="button"
        onMouseDown={(event) => onResizeStart(widget, event)}
        className="absolute bottom-2 right-2 z-30 rounded-md border border-white/35 bg-black/25 p-1 text-white backdrop-blur"
        aria-label="Resize widget"
      >
        <RectangleHorizontal className="h-3.5 w-3.5" />
      </button>

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
  };

  return (
    <div className="space-y-5">
      <div className="rounded-2xl border border-white/35 bg-white/20 p-4 backdrop-blur-xl shadow-lg">
        <div className="flex flex-wrap items-center gap-2">
          <Button type="button" className="gap-2" onClick={() => addWidget("today-snapshot")}>
            <Plus className="h-4 w-4" />
            Add Widget
          </Button>
          <Button type="button" variant="secondary" onClick={() => addWidget("budget-health")}>Budget</Button>
          <Button type="button" variant="secondary" onClick={() => addWidget("top-categories")}>Categories</Button>
          <Button type="button" variant="secondary" onClick={() => addWidget("goal-progress")}>Goals</Button>
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
