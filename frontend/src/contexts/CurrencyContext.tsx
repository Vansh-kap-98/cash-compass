import React, { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";

export type CurrencyCode = "USD" | "INR" | "RUB";

interface CurrencyContextType {
  currency: CurrencyCode;
  setCurrency: (currency: CurrencyCode) => void;
  cycleCurrency: () => void;
  convertFromUSD: (amount: number) => number;
  convertToUSD: (amount: number) => number;
  formatAmount: (amount: number, options?: Intl.NumberFormatOptions) => string;
  formatFromUSD: (amount: number, options?: Intl.NumberFormatOptions) => string;
  ratesLoading: boolean;
  ratesError: string | null;
  lastUpdated: Date | null;
}

const CurrencyContext = createContext<CurrencyContextType | undefined>(undefined);

const currencyOrder: CurrencyCode[] = ["USD", "INR", "RUB"];

// Fallback static rates (used if API fails)
const fallbackRatesFromUSD: Record<CurrencyCode, number> = {
  USD: 1,
  INR: 83.5,
  RUB: 92,
};

const localeByCurrency: Record<CurrencyCode, string> = {
  USD: "en-US",
  INR: "en-IN",
  RUB: "ru-RU",
};

const RATES_CACHE_KEY = "cash-compass-exchange-rates-v1";
const RATES_TTL_MS = 60 * 60 * 1000; // 1 hour TTL

const toFiniteNumber = (value: number) => (Number.isFinite(value) ? value : 0);

/** Round to exactly 2 decimal places */
const round2 = (n: number) => Math.round(n * 100) / 100;

const isCurrencyCode = (value: string | null): value is CurrencyCode => {
  if (!value) return false;
  return value === "USD" || value === "INR" || value === "RUB";
};

interface CachedRates {
  rates: Record<CurrencyCode, number>;
  timestamp: number;
}

function readCachedRates(): CachedRates | null {
  try {
    const raw = localStorage.getItem(RATES_CACHE_KEY);
    if (!raw) return null;
    const parsed = JSON.parse(raw) as CachedRates;
    if (!parsed?.rates || !parsed?.timestamp) return null;
    // Check TTL
    if (Date.now() - parsed.timestamp > RATES_TTL_MS) return null;
    return parsed;
  } catch {
    return null;
  }
}

function writeCachedRates(rates: Record<CurrencyCode, number>) {
  try {
    const data: CachedRates = { rates, timestamp: Date.now() };
    localStorage.setItem(RATES_CACHE_KEY, JSON.stringify(data));
  } catch {
    // localStorage might be full — ignore
  }
}

export const CurrencyProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [currency, setCurrencyState] = useState<CurrencyCode>(() => {
    const stored = localStorage.getItem("dashboard-currency");
    return isCurrencyCode(stored) ? stored : "USD";
  });

  const [rates, setRates] = useState<Record<CurrencyCode, number>>(() => {
    const cached = readCachedRates();
    return cached?.rates ?? fallbackRatesFromUSD;
  });
  const [ratesLoading, setRatesLoading] = useState(false);
  const [ratesError, setRatesError] = useState<string | null>(null);
  const [lastUpdated, setLastUpdated] = useState<Date | null>(() => {
    const cached = readCachedRates();
    return cached ? new Date(cached.timestamp) : null;
  });

  // Fetch live rates from a free API
  const fetchRates = useCallback(async () => {
    setRatesLoading(true);
    setRatesError(null);

    try {
      // Use frankfurter.app (free, no API key needed, reliable)
      const response = await fetch("https://api.frankfurter.app/latest?from=USD&to=INR,RUB");

      if (!response.ok) {
        throw new Error(`HTTP ${response.status}`);
      }

      const data = await response.json();

      if (data?.rates) {
        const newRates: Record<CurrencyCode, number> = {
          USD: 1,
          INR: round2(Number(data.rates.INR) || fallbackRatesFromUSD.INR),
          RUB: round2(Number(data.rates.RUB) || fallbackRatesFromUSD.RUB),
        };
        setRates(newRates);
        writeCachedRates(newRates);
        setLastUpdated(new Date());
      } else {
        throw new Error("Invalid response format");
      }
    } catch (err) {
      const msg = err instanceof Error ? err.message : "Unknown error";
      setRatesError(`Using cached rates — live fetch failed (${msg})`);
      // Keep whatever rates we have (cached or fallback)
    } finally {
      setRatesLoading(false);
    }
  }, []);

  // Fetch rates on mount and when cache is stale
  useEffect(() => {
    const cached = readCachedRates();
    if (!cached) {
      fetchRates();
    }
    // Also set up periodic refresh every hour
    const interval = setInterval(fetchRates, RATES_TTL_MS);
    return () => clearInterval(interval);
  }, [fetchRates]);

  // Re-fetch when currency changes (so user always has fresh data)
  useEffect(() => {
    const cached = readCachedRates();
    if (!cached) {
      fetchRates();
    }
  }, [currency, fetchRates]);

  const setCurrency = useCallback((next: CurrencyCode) => {
    setCurrencyState(next);
    localStorage.setItem("dashboard-currency", next);
  }, []);

  const cycleCurrency = useCallback(() => {
    setCurrencyState((current) => {
      const currentIndex = currencyOrder.indexOf(current);
      const next = currencyOrder[(currentIndex + 1) % currencyOrder.length];
      localStorage.setItem("dashboard-currency", next);
      return next;
    });
  }, []);

  const convertFromUSD = useCallback(
    (amount: number) => round2(toFiniteNumber(amount) * rates[currency]),
    [currency, rates],
  );

  const convertToUSD = useCallback(
    (amount: number) => round2(toFiniteNumber(amount) / rates[currency]),
    [currency, rates],
  );

  const formatAmount = useCallback(
    (amount: number, options?: Intl.NumberFormatOptions) => {
      const maxFd = options?.maximumFractionDigits ?? 2;
      const minFd = Math.min(options?.minimumFractionDigits ?? 2, maxFd);
      return new Intl.NumberFormat(localeByCurrency[currency], {
        style: "currency",
        currency,
        minimumFractionDigits: minFd,
        maximumFractionDigits: maxFd,
        ...options,
      }).format(round2(toFiniteNumber(amount)));
    },
    [currency],
  );

  const formatFromUSD = useCallback(
    (amount: number, options?: Intl.NumberFormatOptions) => {
      const converted = convertFromUSD(amount);
      return formatAmount(converted, options);
    },
    [convertFromUSD, formatAmount],
  );

  useEffect(() => {
    const onKeyDown = (event: KeyboardEvent) => {
      if (event.code !== "ControlRight" || event.repeat) return;
      if (event.altKey || event.metaKey || event.shiftKey) return;

      const target = event.target as HTMLElement | null;
      if (target?.isContentEditable) return;
      const tagName = target?.tagName;
      if (tagName === "INPUT" || tagName === "TEXTAREA" || tagName === "SELECT") return;

      cycleCurrency();
    };

    window.addEventListener("keydown", onKeyDown);
    return () => window.removeEventListener("keydown", onKeyDown);
  }, [cycleCurrency]);

  const value = useMemo(
    () => ({
      currency,
      setCurrency,
      cycleCurrency,
      convertFromUSD,
      convertToUSD,
      formatAmount,
      formatFromUSD,
      ratesLoading,
      ratesError,
      lastUpdated,
    }),
    [currency, setCurrency, cycleCurrency, convertFromUSD, convertToUSD, formatAmount, formatFromUSD, ratesLoading, ratesError, lastUpdated],
  );

  return <CurrencyContext.Provider value={value}>{children}</CurrencyContext.Provider>;
};

export const useCurrency = () => {
  const ctx = useContext(CurrencyContext);
  if (!ctx) throw new Error("useCurrency must be used within CurrencyProvider");
  return ctx;
};
