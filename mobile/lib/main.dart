import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/theme/app_theme.dart';
import 'screens/dashboard_screen.dart';
import 'services/prefs.dart';
import 'state/currency_provider.dart';
import 'state/finance_provider.dart';
import 'state/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = Prefs();

  // Stores are hydrated before the first frame so the UI never flashes zeroes
  // over real data. This is the async equivalent of the web app reading
  // localStorage synchronously during its initial render.
  final theme = ThemeProvider(prefs);
  final currency = CurrencyProvider(prefs);
  final finance = FinanceProvider(prefs);

  await Future.wait([theme.load(), finance.load()]);
  // Currency loads last and is not awaited to completion: it may hit the
  // network for fresh rates, and the app is perfectly usable with the cached
  // or fallback rates it already has.
  unawaited(currency.load());

  runApp(
    CashCompassApp(theme: theme, currency: currency, finance: finance),
  );
}

/// Starts a future without awaiting it. Local copy so `main` doesn't need to
/// import `dart:async` solely for this.
void unawaited(Future<void> future) {
  future.catchError((Object error) => debugPrint('Startup task failed: $error'));
}

class CashCompassApp extends StatelessWidget {
  const CashCompassApp({
    super.key,
    required this.theme,
    required this.currency,
    required this.finance,
  });

  final ThemeProvider theme;
  final CurrencyProvider currency;
  final FinanceProvider finance;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: theme),
        ChangeNotifierProvider.value(value: currency),
        ChangeNotifierProvider.value(value: finance),
      ],
      // Watching ThemeProvider here means a theme or font change rebuilds
      // MaterialApp with new ThemeData, which is how the whole app re-skins.
      child: Consumer<ThemeProvider>(
        builder: (context, themeState, _) => MaterialApp(
          title: 'Cash Compass',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(
            themeState.tokens,
            fontPack: themeState.fontPack,
            fontSizeFactor: themeState.fontSizeFactor,
          ),
          home: const DashboardScreen(),
        ),
      ),
    );
  }
}
