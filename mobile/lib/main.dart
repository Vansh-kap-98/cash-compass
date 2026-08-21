import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/scroll_behavior.dart';
import 'app/theme/app_theme.dart';
import 'dev/frame_report.dart';
import 'screens/auth_screen.dart';
import 'screens/dashboard_screen.dart';
import 'services/prefs.dart';
import 'services/supabase_service.dart';
import 'state/auth_provider.dart';
import 'state/budget_plan_provider.dart';
import 'state/currency_provider.dart';
import 'state/finance_provider.dart';
import 'state/planner_provider.dart';
import 'state/student_planner_provider.dart';
import 'state/theme_provider.dart';
import 'state/workspace_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FrameReport.start();

  await SupabaseService.init();

  final prefs = Prefs();

  // Stores are hydrated before the first frame so the UI never flashes zeroes
  // over real data. This is the async equivalent of the web app reading
  // localStorage synchronously during its initial render.
  final theme = ThemeProvider(prefs);
  final currency = CurrencyProvider(prefs);
  final finance = FinanceProvider(prefs);
  final planner = PlannerProvider(prefs);
  final workspace = WorkspaceProvider(prefs);
  final budgets = BudgetPlanProvider(prefs);
  final students = StudentPlannerProvider(prefs);
  final auth = AuthProvider(prefs);

  await Future.wait([
    theme.load(),
    finance.load(),
    planner.load(),
    workspace.load(),
    budgets.load(),
    students.load(),
    auth.load(),
  ]);

  // Currency is not awaited: it may hit the network for fresh rates, and the
  // app is perfectly usable with the cached or fallback rates it already has.
  unawaited(currency.load());

  runApp(
    CashCompassApp(
      theme: theme,
      currency: currency,
      finance: finance,
      planner: planner,
      workspace: workspace,
      budgets: budgets,
      students: students,
      auth: auth,
    ),
  );
}

/// Starts a future without awaiting it. Local copy so `main` doesn't need to
/// import `dart:async` solely for this.
void unawaited(Future<void> future) {
  future.catchError((Object error) => debugPrint('Startup task failed: $error'));
}

class CashCompassApp extends StatefulWidget {
  const CashCompassApp({
    super.key,
    required this.theme,
    required this.currency,
    required this.finance,
    required this.planner,
    required this.workspace,
    required this.budgets,
    required this.students,
    required this.auth,
  });

  final ThemeProvider theme;
  final CurrencyProvider currency;
  final FinanceProvider finance;
  final PlannerProvider planner;
  final WorkspaceProvider workspace;
  final BudgetPlanProvider budgets;
  final StudentPlannerProvider students;
  final AuthProvider auth;

  @override
  State<CashCompassApp> createState() => _CashCompassAppState();
}

class _CashCompassAppState extends State<CashCompassApp>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Disk writes are debounced for performance, so a backgrounded app may
    // still hold unsaved edits. Android can kill a paused process at any time —
    // flush before that can happen.
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached ||
        state == AppLifecycleState.hidden) {
      widget.finance.flush();
      widget.theme.flush();
      widget.planner.flush();
      widget.workspace.flush();
      widget.budgets.flush();
      widget.students.flush();
      FrameReport.report();
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: widget.theme),
        ChangeNotifierProvider.value(value: widget.currency),
        ChangeNotifierProvider.value(value: widget.finance),
        ChangeNotifierProvider.value(value: widget.planner),
        ChangeNotifierProvider.value(value: widget.workspace),
        ChangeNotifierProvider.value(value: widget.budgets),
        ChangeNotifierProvider.value(value: widget.students),
        ChangeNotifierProvider.value(value: widget.auth),
      ],
      // Watching ThemeProvider here means a theme or font change rebuilds
      // MaterialApp with new ThemeData, which is how the whole app re-skins.
      child: Consumer<ThemeProvider>(
        builder: (context, themeState, _) => MaterialApp(
          title: 'Cash Compass',
          debugShowCheckedModeBanner: false,
          // Removes Android's overscroll stretch app-wide; see AppScrollBehavior.
          scrollBehavior: const AppScrollBehavior(),
          theme: buildTheme(
            themeState.tokens,
            fontPack: themeState.fontPack,
            fontSizeFactor: themeState.fontSizeFactor,
          ),
          home: const _AuthGate(),
        ),
      ),
    );
  }
}

/// Shows the dashboard when signed in (or in demo mode), the auth screen
/// otherwise. Replaces the web app's `ProtectedRoute`.
class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (auth.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return auth.isSignedIn ? const DashboardScreen() : const AuthScreen();
  }
}
