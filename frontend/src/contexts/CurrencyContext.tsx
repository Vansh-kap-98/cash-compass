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
}

const CurrencyContext = createContext<CurrencyContextType | undefined>(undefined);

const currencyOrder: CurrencyCode[] = ["USD", "INR", "RUB"];

const conversionRatesFromUSD: Record<CurrencyCode, number> = {
  USD: 1,
  INR: 83,
  RUB: 92,
};

const localeByCurrency: Record<CurrencyCode, string> = {
  USD: "en-US",
  INR: "en-IN",
  RUB: "ru-RU",
};

const toFiniteNumber = (value: number) => (Number.isFinite(value) ? value : 0);

const isCurrencyCode = (value: string | null): value is CurrencyCode => {
  if (!value) return false;
  return value === "USD" || value === "INR" || value === "RUB";
};

export const CurrencyProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [currency, setCurrencyState] = useState<CurrencyCode>(() => {
    const stored = localStorage.getItem("dashboard-currency");
    return isCurrencyCode(stored) ? stored : "USD";
  });

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
    (amount: number) => toFiniteNumber(amount) * conversionRatesFromUSD[currency],
    [currency],
  );

  const convertToUSD = useCallback(
    (amount: number) => toFiniteNumber(amount) / conversionRatesFromUSD[currency],
    [currency],
  );

  const formatAmount = useCallback(
    (amount: number, options?: Intl.NumberFormatOptions) =>
      new Intl.NumberFormat(localeByCurrency[currency], {
        style: "currency",
        currency,
        maximumFractionDigits: 2,
        ...options,
      }).format(toFiniteNumber(amount)),
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
    }),
    [currency, setCurrency, cycleCurrency, convertFromUSD, convertToUSD, formatAmount, formatFromUSD],
  );

  return <CurrencyContext.Provider value={value}>{children}</CurrencyContext.Provider>;
};

export const useCurrency = () => {
  const ctx = useContext(CurrencyContext);
  if (!ctx) throw new Error("useCurrency must be used within CurrencyProvider");
  return ctx;
};
