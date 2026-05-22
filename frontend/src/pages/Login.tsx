import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { AlertCircle, ArrowRight, Mail, Lock } from "lucide-react";
import { supabase, isSupabaseConfigured } from "@/lib/supabaseClient";
import { useAuth } from "@/context/AuthContext";
import { AuthShell } from "@/components/auth/AuthShell";
import { usePressScale } from "@/hooks/usePressScale";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";

const LoginPage = () => {
  const navigate = useNavigate();
  const { user, isDemoMode, enableDemoMode } = useAuth();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);

  const loginButton = usePressScale<HTMLButtonElement>();
  const demoButton = usePressScale<HTMLButtonElement>();

  useEffect(() => {
    if (user || isDemoMode) {
      navigate("/dashboard", { replace: true });
    }
  }, [user, isDemoMode, navigate]);

  const handleLogin = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);

    if (!isSupabaseConfigured) {
      setError("Supabase is not configured. Add the Supabase environment variables to enable login.");
      return;
    }

    if (!email.trim() || !password.trim()) {
      setError("Email and password are required.");
      return;
    }

    setLoading(true);
    try {
      const { error: authError } = await supabase.auth.signInWithPassword({
        email: email.trim(),
        password,
      });

      if (authError) {
        setError(authError.message);
        return;
      }

      navigate("/dashboard", { replace: true });
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Login failed. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  const handleDemoMode = () => {
    enableDemoMode();
    navigate("/dashboard", { replace: true });
  };

  return (
    <AuthShell
      eyebrow="Secure access"
      title="Welcome back to cash-compass"
      subtitle="Sign in to continue tracking savings, budgets, and daily plans with the same soft-bloom design language used across the app."
    >
      <form className="space-y-5" onSubmit={handleLogin}>
        <div className="space-y-2">
          <Label className="text-xs uppercase tracking-wide text-muted-foreground">Email</Label>
          <div className="relative">
            <Mail className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              type="email"
              inputMode="email"
              autoComplete="email"
              placeholder="you@gmail.com"
              className="pl-10"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>
        </div>

        <div className="space-y-2">
          <Label className="text-xs uppercase tracking-wide text-muted-foreground">Password</Label>
          <div className="relative">
            <Lock className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              type="password"
              autoComplete="current-password"
              placeholder="Enter your password"
              className="pl-10"
              value={password}
              onChange={(e) => setPassword(e.target.value)}
            />
          </div>
        </div>

        {error && (
          <div className="flex items-start gap-2 rounded-2xl border border-destructive/30 bg-destructive/10 p-3 text-sm text-destructive" role="alert">
            <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        <Button
          ref={loginButton.ref}
          type="submit"
          className="w-full rounded-2xl bg-primary py-6 text-base font-medium text-primary-foreground shadow-card"
          disabled={loading}
          {...loginButton.pressProps}
        >
          {loading ? "Signing in..." : (
            <span className="inline-flex items-center gap-2">Login <ArrowRight className="h-4 w-4" /></span>
          )}
        </Button>

        <Button
          ref={demoButton.ref}
          type="button"
          variant="secondary"
          className="w-full rounded-2xl border border-border bg-secondary/40 py-6 text-sm font-medium text-foreground"
          onClick={handleDemoMode}
          {...demoButton.pressProps}
        >
          Bypass Authentication (Developer Demo Mode)
        </Button>

        <div className="flex items-center justify-between text-sm text-muted-foreground">
          <span>New here?</span>
          <Link to="/signup" className="font-medium text-foreground underline-offset-4 hover:underline">
            Create an account
          </Link>
        </div>
      </form>
    </AuthShell>
  );
};

export default LoginPage;