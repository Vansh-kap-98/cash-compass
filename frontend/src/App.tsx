// #meehikasharma
import { QueryClient, QueryClientProvider } from "@tanstack/react-query";
import { BrowserRouter, Route, Routes } from "react-router-dom";
import { Toaster as Sonner } from "@/components/ui/sonner";
import { Toaster } from "@/components/ui/toaster";
import { TooltipProvider } from "@/components/ui/tooltip";
import { CurrencyProvider } from "@/contexts/CurrencyContext";
import { FinanceProvider } from "@/contexts/FinanceContext";
import { AuthProvider } from "@/context/AuthContext";
import { ProtectedRoute } from "@/components/auth/ProtectedRoute";
import { useAuth } from "@/context/AuthContext";
import LoginPage from "./pages/Login.tsx";
import SignupPage from "./pages/Signup.tsx";
import SandboxPage from "./pages/Sandbox.tsx";
import Index from "./pages/Index.tsx";
import NotFound from "./pages/NotFound.tsx";
import { Navigate } from "react-router-dom";

const queryClient = new QueryClient();

// AuthProvider sits ABOVE FinanceProvider deliberately. Finance data is now
// per-account rather than per-device, so FinanceProvider has to read the
// session to know whose rows to load -- which it cannot do from outside the
// auth context. It does not need router context, so hoisting it out of
// BrowserRouter costs nothing.
const App = () => (
  <QueryClientProvider client={queryClient}>
    <AuthProvider>
      <CurrencyProvider>
        <FinanceProvider>
          <TooltipProvider>
            <Toaster />
            <Sonner />
            <BrowserRouter>
                <Routes>
                  <Route path="/" element={<RootRedirect />} />
                  {/* #kintanjain */}
                  <Route path="/login" element={<LoginPage />} />
                  <Route path="/signup" element={<SignupPage />} />
                  <Route path="/sandbox" element={<SandboxPage />} />
                  <Route
                    path="/dashboard"
                    element={
                      <ProtectedRoute>
                        <Index />
                      </ProtectedRoute>
                    }
                  />
                  <Route path="*" element={<NotFound />} />
                </Routes>
            </BrowserRouter>
          </TooltipProvider>
        </FinanceProvider>
      </CurrencyProvider>
    </AuthProvider>
  </QueryClientProvider>
);

const RootRedirect = () => {
  // #propertyofindia
  const { user, loading } = useAuth();

  if (loading) {
    return <div className="min-h-screen bg-background" />;
  }

  return <Navigate to={user ? "/dashboard" : "/login"} replace />;
};

export default App;
