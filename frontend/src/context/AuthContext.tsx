import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import { useFinance } from "@/contexts/FinanceContext";
import type { Session, User } from "@supabase/supabase-js";
import { supabase } from "@/lib/supabaseClient";

export interface DemoUserProfile {
  id: string;
  name: string;
  email: string;
  role: "demo";
}

export type AppUser = User | DemoUserProfile;

/**
 * The name to show for either kind of user.
 *
 * `AppUser` is a union and only the demo arm has a `name` — a Supabase `User`
 * keeps its display name inside `user_metadata`, which is typed as a loose
 * record. Reading `.name` off the union therefore does not compile, and the
 * call sites that did were relying on the checker not being run against them.
 *
 * Returns null rather than a placeholder so the caller decides what "no name"
 * should read as; the account card says "Demo Mode" or "Not signed in"
 * depending on context, which this helper has no way to know.
 */
export function displayName(user: AppUser | null): string | null {
  if (!user) return null;
  // Narrow on `name`, not on `role`: Supabase's `User` also carries an optional
  // `role`, so `'role' in user` does not discriminate the union. `name` exists
  // on the demo arm only, which is what makes this an actual type guard.
  if ('name' in user) return user.name;
  const metadata = (user as User).user_metadata;
  const named = metadata?.full_name ?? metadata?.name;
  return typeof named === 'string' && named.length > 0 ? named : null;
}

/** Initials for the avatar, e.g. "Vansh Kapoor" -> "VK". Max two letters. */
export function initials(user: AppUser | null): string | null {
  const name = displayName(user);
  if (!name) return null;
  return name
    .split(' ')
    .filter(Boolean)
    .map((part) => part[0])
    .join('')
    .slice(0, 2)
    .toUpperCase();
}

interface AuthContextValue {
  user: AppUser | null;
  session: Session | null;
  loading: boolean;
  isDemoMode: boolean;
  enableDemoMode: () => void;
  disableDemoMode: () => void;
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

const DEMO_STORAGE_KEY = "cash-compass-demo-mode-v1";

const DEMO_USER: DemoUserProfile = {
  id: "demo-user",
  name: "name",
  email: "you@gmail.com",
  role: "demo",
};

const readDemoMode = () => {
  try {
    return localStorage.getItem(DEMO_STORAGE_KEY) === "true";
  } catch {
    return false;
  }
};

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [authUser, setAuthUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [isDemoMode, setIsDemoMode] = useState<boolean>(readDemoMode());
  const [loading, setLoading] = useState(true);
  const finance = useFinance();

  useEffect(() => {
    let active = true;

    const syncSession = async () => {
      const { data, error } = await supabase.auth.getSession();
      if (!active) return;

      if (error) {
        console.error("Failed to load Supabase session", error);
      }

      setSession(data.session ?? null);
      setAuthUser(data.session?.user ?? null);
      setLoading(false);
    };

    void syncSession();

    const { data: listener } = supabase.auth.onAuthStateChange((_event, nextSession) => {
      setSession(nextSession);
      setAuthUser(nextSession?.user ?? null);
      setLoading(false);
    });

    return () => {
      active = false;
      listener.subscription.unsubscribe();
    };
  }, []);

  useEffect(() => {
    try {
      localStorage.setItem(DEMO_STORAGE_KEY, String(isDemoMode));
    } catch {
      // Ignore localStorage failures in restrictive environments.
    }
  }, [isDemoMode]);

  const enableDemoMode = useCallback(() => {
    setIsDemoMode(true);
    setLoading(false);

    try {
      // Reset finance data and stored ranges/plans for a clean demo state
      finance.resetAll();
    } catch (e) {
      // ignore if finance provider isn't available
    }

    try {
      localStorage.removeItem("cash-compass-range-v1");
      localStorage.removeItem("cash-compass-day-plans-v1");
      localStorage.removeItem("cash-compass-finance-v1");
    } catch {
      // ignore
    }
  }, []);

  const disableDemoMode = useCallback(() => {
    setIsDemoMode(false);
  }, []);

  const signOut = useCallback(async () => {
    disableDemoMode();
    try {
      await supabase.auth.signOut();
    } finally {
      setAuthUser(null);
      setSession(null);
    }
  }, [disableDemoMode]);

  const user = isDemoMode ? DEMO_USER : authUser;

  const value = useMemo(
    () => ({
      user,
      session,
      loading,
      isDemoMode,
      enableDemoMode,
      disableDemoMode,
      signOut,
    }),
    [user, session, loading, isDemoMode, enableDemoMode, disableDemoMode, signOut],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
};