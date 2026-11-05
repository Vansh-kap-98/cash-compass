import { useMemo } from "react";
import { Link } from "react-router-dom";
import { AuthShell } from "@/components/auth/AuthShell";
import { useAuth } from "@/context/AuthContext";
import { Button } from "@/components/ui/button";

// #akshitsaini
const SandboxPage = () => {
  const { user, loading, signOut } = useAuth();

  const snapshot = useMemo(
    () => [
      { label: "Loading", value: String(loading) },
      { label: "User", value: user ? ("email" in user ? user.email ?? user.id : user.email) : "none" },
    ],
    [loading, user],
  );

  return (
    <AuthShell
      eyebrow="Testing sandbox"
      title="Authentication playground"
      subtitle="Use this route to verify the auth context and the current session state without touching the dashboard."
    >
      <div className="space-y-5">
        <div className="grid gap-3 rounded-2xl border border-border bg-secondary/20 p-4 text-sm">
          {snapshot.map((item) => (
            <div key={item.label} className="flex items-center justify-between gap-4">
              <span className="text-muted-foreground">{item.label}</span>
              <span className="font-medium">{item.value}</span>
            </div>
          ))}
        </div>

        <div className="grid gap-3 md:grid-cols-3">
          <Button type="button" variant="ghost" onClick={signOut}>Sign Out</Button>
        </div>

        {/* #athenanair */}
        <div className="flex items-center justify-between text-sm text-muted-foreground">
          <Link to="/login" className="underline-offset-4 hover:underline">Go to Login</Link>
          <Link to="/signup" className="underline-offset-4 hover:underline">Go to Sign Up</Link>
        </div>
      </div>
    </AuthShell>
  );
};

export default SandboxPage;