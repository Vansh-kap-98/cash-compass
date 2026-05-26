import { useEffect, useState } from "react";
import { Link, useNavigate } from "react-router-dom";
import { AlertCircle, ArrowRight, Mail, Lock, User } from "lucide-react";
import { supabase, isSupabaseConfigured } from "@/lib/supabaseClient";
import { useAuth } from "@/context/AuthContext";
import { AuthShell } from "@/components/auth/AuthShell";
import { usePressScale } from "@/hooks/usePressScale";
import { Input } from "@/components/ui/input";
import { Label } from "@/components/ui/label";
import { Button } from "@/components/ui/button";

const emailPattern = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/i;

const SignupPage = () => {
  const navigate = useNavigate();
  const { user, isDemoMode } = useAuth();
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [success, setSuccess] = useState<string | null>(null);

  const signupButton = usePressScale<HTMLButtonElement>();

  useEffect(() => {
    if (user || isDemoMode) {
      navigate("/dashboard", { replace: true });
    }
  }, [user, isDemoMode, navigate]);

  const handleSignup = async (event: React.FormEvent<HTMLFormElement>) => {
    event.preventDefault();
    setError(null);
    setSuccess(null);

    if (!isSupabaseConfigured) {
      setError("Supabase is not configured. Add the Supabase environment variables to enable sign-up.");
      return;
    }

    if (!name.trim()) {
      setError("Name is required.");
      return;
    }

    if (!emailPattern.test(email.trim())) {
      setError("Use a valid email address.");
      return;
    }

    if (password.length < 8) {
      setError("Password must be at least 8 characters long.");
      return;
    }

    if (password !== confirmPassword) {
      setError("Passwords do not match.");
      return;
    }

    setLoading(true);
    try {
      const { data, error: authError } = await supabase.auth.signUp({
        email: email.trim(),
        password,
        options: {
          data: {
            full_name: name.trim(),
            display_name: name.trim(),
          },
        },
      });

      if (authError) {
        setError(authError.message);
        return;
      }

      if (data.user) {
        const { error: profileError } = await supabase.from("profiles").upsert(
          ([
            {
              id: data.user.id,
              name: name.trim(),
              email: data.user.email ?? email.trim(),
            },
          ] as any),
          { onConflict: "id" },
        );

        if (profileError) {
          setError(profileError.message);
          return;
        }
      }

      if (data.session) {
        navigate("/dashboard", { replace: true });
        return;
      }

      setSuccess("Sign-up complete. Check your email to verify your account.");
    } catch (cause) {
      setError(cause instanceof Error ? cause.message : "Sign-up failed. Please try again.");
    } finally {
      setLoading(false);
    }
  };

  return (
    <AuthShell
      eyebrow="Create account"
      title="Create your cash-compass account"
      subtitle="Use your email, set your password, and we’ll initialize your profile so budget tracking starts cleanly."
    >
      <form className="space-y-5" onSubmit={handleSignup}>
        <div className="space-y-2">
          <Label className="text-xs uppercase tracking-wide text-muted-foreground">Your name</Label>
          <div className="relative">
            <User className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              type="text"
              autoComplete="name"
              placeholder="name"
              className="pl-10"
              value={name}
              onChange={(e) => setName(e.target.value)}
            />
          </div>
        </div>

        <div className="space-y-2">
          <Label className="text-xs uppercase tracking-wide text-muted-foreground">Email</Label>
          <div className="relative">
            <Mail className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
            <Input
              type="email"
              autoComplete="email"
              placeholder="you@gmail.com"
              className="pl-10"
              value={email}
              onChange={(e) => setEmail(e.target.value)}
            />
          </div>
        </div>

        <div className="grid gap-4 md:grid-cols-2">
          <div className="space-y-2">
            <Label className="text-xs uppercase tracking-wide text-muted-foreground">Password</Label>
            <div className="relative">
              <Lock className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                type="password"
                autoComplete="new-password"
                placeholder="At least 8 characters"
                className="pl-10"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
              />
            </div>
          </div>

          <div className="space-y-2">
            <Label className="text-xs uppercase tracking-wide text-muted-foreground">Confirm password</Label>
            <div className="relative">
              <Lock className="pointer-events-none absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-muted-foreground" />
              <Input
                type="password"
                autoComplete="new-password"
                placeholder="Repeat password"
                className="pl-10"
                value={confirmPassword}
                onChange={(e) => setConfirmPassword(e.target.value)}
              />
            </div>
          </div>
        </div>

        {error && (
          <div className="flex items-start gap-2 rounded-2xl border border-destructive/30 bg-destructive/10 p-3 text-sm text-destructive" role="alert">
            <AlertCircle className="mt-0.5 h-4 w-4 shrink-0" />
            <span>{error}</span>
          </div>
        )}

        {success && (
          <div className="rounded-2xl border border-primary/20 bg-primary/10 p-3 text-sm text-foreground" role="status">
            {success}
          </div>
        )}

        <Button
          ref={signupButton.ref}
          type="submit"
          className="w-full rounded-2xl bg-primary py-6 text-base font-medium text-primary-foreground shadow-card"
          disabled={loading}
          {...signupButton.pressProps}
        >
          {loading ? "Creating account..." : (
            <span className="inline-flex items-center gap-2">Sign up <ArrowRight className="h-4 w-4" /></span>
          )}
        </Button>

        <div className="flex items-center justify-between text-sm text-muted-foreground">
          <span>Already have an account?</span>
          <Link to="/login" className="font-medium text-foreground underline-offset-4 hover:underline">
            Login
          </Link>
        </div>
      </form>
    </AuthShell>
  );
};

export default SignupPage;