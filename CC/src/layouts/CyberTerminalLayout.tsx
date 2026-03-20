import { BalanceOverview } from "@/components/BalanceOverview";
import { SavingsProgress } from "@/components/SavingsProgress";
import { TransactionFeed } from "@/components/TransactionFeed";
import { InsightBox } from "@/components/InsightBox";
import { FinancialCharts } from "@/components/FinancialCharts";
import { Terminal, Database, Activity, ShieldCheck, BellRing, ScanLine, Radar } from "lucide-react";

const TerminalWidget = ({ title, children }: { title: string; children: React.ReactNode }) => (
  <div className="border border-primary/20 p-4 rounded bg-black/40">
    <h3 className="mb-3 text-xs font-bold tracking-wide text-primary">{title}</h3>
    {children}
  </div>
);

export const CyberTerminalLayout = () => (
  <div className="min-h-screen bg-background font-mono p-4 md:p-8">
    <div className="border border-primary/30 rounded-lg p-6 bg-card/50 backdrop-blur-sm relative">
      {}
      <div className="flex items-center justify-between border-b border-primary/20 pb-4 mb-8">
        <div className="flex items-center gap-3">
          <Terminal className="w-5 h-5" />
          <span className="text-sm font-bold tracking-tighter">CASH-COMPASS_OS [v2.0.4]</span>
        </div>
        <div className="flex gap-2 text-[10px] items-center">
          <span className="animate-pulse flex items-center gap-1"><Activity className="w-3 h-3" /> UPLINK_ACTIVE</span>
          <span className="flex items-center gap-1"><ShieldCheck className="w-3 h-3 text-primary" /> SECURE</span>
        </div>
      </div>

      <div className="grid grid-cols-12 gap-6">
        {}
        <div className="col-span-12 lg:col-span-3 space-y-6">
          <div className="border border-primary/20 p-4 rounded bg-primary/5">
            <h3 className="text-xs font-bold mb-4 flex items-center gap-2">
              <Database className="w-3 h-3" /> NODE_STATUS
            </h3>
            <div className="space-y-2 text-[10px]">
              <div className="flex justify-between"><span>CPU_USAGE</span><span className="text-primary">0.42%</span></div>
              <div className="flex justify-between"><span>MEM_ALLOC</span><span className="text-primary">128MB</span></div>
              <div className="flex justify-between"><span>LATENCY</span><span className="text-primary">12ms</span></div>
            </div>
          </div>

          <TerminalWidget title="WIDGET_STACK">
            <div className="space-y-2 text-[10px]">
              <div className="flex items-center justify-between">
                <span className="flex items-center gap-1"><BellRing className="w-3 h-3 text-primary" /> ALERT_BUS</span>
                <span className="text-primary">03</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="flex items-center gap-1"><ScanLine className="w-3 h-3 text-primary" /> OCR_QUEUE</span>
                <span className="text-primary">07</span>
              </div>
              <div className="flex items-center justify-between">
                <span className="flex items-center gap-1"><Radar className="w-3 h-3 text-primary" /> THREAT_SCAN</span>
                <span className="text-primary">CLEAN</span>
              </div>
            </div>
          </TerminalWidget>

          <nav className="space-y-2">
            {["SYSTEM_CORE", "LEDGER_V1", "TARGET_SYS", "SCAN_INTEL"].map(item => (
              <div key={item} className="p-2 border border-primary/10 hover:border-primary/50 cursor-pointer text-xs transition-all">
                {`> ${item}`}
              </div>
            ))}
          </nav>
        </div>

        {}
        <div className="col-span-12 lg:col-span-9 space-y-6">
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="border border-primary/20 p-6 rounded bg-black/40">
              <BalanceOverview />
            </div>
            <div className="border border-primary/20 p-6 rounded bg-black/40">
               <SavingsProgress />
            </div>
          </div>
          
          <div className="border border-primary/20 p-6 rounded bg-black/40 overflow-hidden">
            <h2 className="text-sm font-bold mb-4 border-b border-primary/10 pb-2">VIRTUAL_ASSET_VISUALIZATION</h2>
            <FinancialCharts />
          </div>

          <div className="border border-primary/20 p-6 rounded bg-black/40">
            <h2 className="text-sm font-bold mb-4 border-b border-primary/10 pb-2">TRANSACTION_HISTORY_SCAN</h2>
            <TransactionFeed />
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-6">
            <div className="border border-primary/20 p-6 rounded bg-black/40">
              <h2 className="text-sm font-bold mb-4 border-b border-primary/10 pb-2">INTELLIGENCE_HINTS</h2>
              <InsightBox />
            </div>
            <div className="border border-primary/20 p-6 rounded bg-black/40">
              <h2 className="text-sm font-bold mb-4 border-b border-primary/10 pb-2">SYSTEM_LOG</h2>
              <div className="space-y-2 text-xs text-muted-foreground">
                <p>&gt; savings_autopilot synced</p>
                <p>&gt; anomaly detector flag: dining</p>
                <p>&gt; forecast model recalculated</p>
                <p>&gt; weekly digest dispatched</p>
              </div>
            </div>
          </div>
        </div>
      </div>

      {}
      <div className="mt-8 pt-4 border-t border-primary/10 flex justify-between text-[10px] opacity-50">
        <span>© 2026 CURATED_CRYPTO_CORP</span>
        <span className="flex gap-4">
           <span>LOC: 51.5074° N, 0.1278° W</span>
           <span>SYS_EPOCH: 1773839201</span>
        </span>
      </div>
    </div>
  </div>
);
