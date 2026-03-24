import { useMemo } from "react";
import { PieChart, Pie, Cell, ResponsiveContainer, BarChart, Bar, XAxis, YAxis, Tooltip } from "recharts";
import { useCurrency } from "@/contexts/CurrencyContext";

const data = [
  { name: "Rent", value: 1200, fill: "hsl(var(--primary))" },
  { name: "Food", value: 450, fill: "hsl(var(--accent))" },
  { name: "Travel", value: 300, fill: "hsl(var(--secondary))" },
  { name: "Others", value: 200, fill: "hsl(var(--muted-foreground)/0.2)" },
];

const barData = [
  { month: "Jan", income: 4000, expense: 2400 },
  { month: "Feb", income: 3000, expense: 1398 },
  { month: "Mar", income: 2000, expense: 9800 },
  { month: "Apr", income: 2780, expense: 3908 },
];

export const FinancialCharts = () => {
  const { convertFromUSD, formatAmount } = useCurrency();

  const pieData = useMemo(
    () => data.map((item) => ({ ...item, value: convertFromUSD(item.value) })),
    [convertFromUSD],
  );

  const monthlyBarData = useMemo(
    () =>
      barData.map((item) => ({
        ...item,
        income: convertFromUSD(item.income),
        expense: convertFromUSD(item.expense),
      })),
    [convertFromUSD],
  );

  return (
    <div className="grid grid-cols-1 md:grid-cols-2 gap-6 w-full">
      <div className="bg-card p-6 rounded-3xl shadow-card border border-border">
        <h3 className="font-heading font-semibold mb-4 text-sm uppercase tracking-wider opacity-70">Expense Distribution</h3>
        <div className="h-[200px] w-full">
          <ResponsiveContainer width="100%" height="100%">
            <PieChart>
              <Pie
                data={pieData}
                cx="50%"
                cy="50%"
                innerRadius={60}
                outerRadius={80}
                paddingAngle={5}
                dataKey="value"
              >
                {pieData.map((entry, index) => (
                  <Cell key={`cell-${index}`} fill={entry.fill} stroke="none" />
                ))}
              </Pie>
              <Tooltip 
                formatter={(value) => {
                  const numeric = Number(value) || 0;
                  return [formatAmount(numeric), "Amount"];
                }}
                contentStyle={{ 
                  backgroundColor: "hsl(var(--card))", 
                  borderColor: "hsl(var(--border))",
                  borderRadius: "12px",
                  fontSize: "12px"
                }}
              />
            </PieChart>
          </ResponsiveContainer>
        </div>
      </div>

      <div className="bg-card p-6 rounded-3xl shadow-card border border-border">
        <h3 className="font-heading font-semibold mb-4 text-sm uppercase tracking-wider opacity-70">Cash Flow</h3>
        <div className="h-[200px] w-full text-xs">
          <ResponsiveContainer width="100%" height="100%">
            <BarChart data={monthlyBarData}>
              <XAxis dataKey="month" axisLine={false} tickLine={false} />
              <YAxis hide />
              <Tooltip
                formatter={(value, name) => {
                  const numeric = Number(value) || 0;
                  const label = name === "income" ? "Income" : "Expense";
                  return [formatAmount(numeric), label];
                }}
              />
              <Bar dataKey="income" fill="hsl(var(--primary))" radius={[4, 4, 0, 0]} />
              <Bar dataKey="expense" fill="hsl(var(--secondary))" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        </div>
      </div>
    </div>
  );
};
