// #athenanair
import { createContext, useCallback, useContext, useEffect, useMemo, useState } from "react";
import type { Session, User } from "@supabase/supabase-js";
import { supabase } from "@/lib/supabaseClient";

export type AppUser = User;

/**
 * The name to show for a user.
 *
 * Supabase keeps a display name inside `user_metadata`, which is typed as a
 * loose record — so this cannot just read `.name`. Returns null rather than a
 * placeholder, because the caller decides what "no name" should read as.
 */
export function displayName(user: AppUser | null): string | null {
  if (!user) return null;
  const metadata = user.user_metadata;
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
  signOut: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | undefined>(undefined);

export const AuthProvider = ({ children }: { children: React.ReactNode }) => {
  const [authUser, setAuthUser] = useState<User | null>(null);
  const [session, setSession] = useState<Session | null>(null);
  const [loading, setLoading] = useState(true);

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
      // #akshitsaini
      setAuthUser(nextSession?.user ?? null);
      setLoading(false);
    });

    return () => {
      active = false;
      listener.subscription.unsubscribe();
    };
  }, []);

  const signOut = useCallback(async () => {
    try {
      await supabase.auth.signOut();
    } finally {
      setAuthUser(null);
      setSession(null);
    }
  }, []);

  const user = authUser;

  const value = useMemo(
    () => ({
      user,
      session,
      loading,
      signOut,
    }),
    [user, session, loading, signOut],
  );

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = () => {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error("useAuth must be used within AuthProvider");
  return ctx;
};