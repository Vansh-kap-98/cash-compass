import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme/app_colors.dart';
import '../app/widgets/app_backdrop.dart';
import '../app/widgets/app_button.dart';
import '../app/widgets/app_header_panel.dart';
import '../l10n/l10n.dart';
import '../l10n/presenters.dart';
import '../state/auth_provider.dart';
import '../state/budget_plan_provider.dart';
import '../state/finance_provider.dart';
import '../state/planner_provider.dart';

/// Sign in, sign up, or continue without an account.
///
/// The web app used a split-screen marketing panel beside the form. That is a
/// desktop layout; on a phone it becomes a simple centred header.
class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _isSignUp = false;
  bool _busy = false;

  /// The last failure, kept as a value rather than a rendered sentence so it
  /// re-reads correctly if the language changes while the form is open.
  AuthFailure? _failure;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    setState(() {
      _busy = true;
      _failure = null;
    });

    final failure = _isSignUp
        ? await auth.signUp(
            name: _name.text,
            email: _email.text,
            password: _password.text,
            confirm: _confirm.text,
          )
        : await auth.signIn(_email.text, _password.text);

    if (!mounted) return;
    setState(() {
      _busy = false;
      _failure = failure;
    });
  }

  Future<void> _continueAsDemo() async {
    final l10n = context.l10n;
    final auth = context.read<AuthProvider>();
    final finance = context.read<FinanceProvider>();
    final planner = context.read<PlannerProvider>();
    final budgets = context.read<BudgetPlanProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(l10n.authDemoDialogTitle),
        content: Text(l10n.authDemoDialogBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.actionCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(l10n.actionContinue),
          ),
        ],
      ),
    );

    if (!(confirmed ?? false)) return;

    // Matches the web app: entering demo mode starts from a clean slate.
    await finance.resetAll();
    await planner.resetAll();
    await budgets.resetAll();
    await auth.enableDemoMode();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final failure = _failure;

    return Scaffold(
      // The wordmark sits in a full-bleed ink panel that releases into the page
      // along a curve, as the reference sheet opens. The panel handles the
      // status bar itself, so it lives outside any SafeArea.
      body: AppBackdrop(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppHeaderPanel(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.explore_outlined, size: 44),
                    const SizedBox(height: 14),
                    Text(
                      l10n.appTitle,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.displaySmall
                          ?.copyWith(color: AppColors.surface),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.authTagline,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: AppColors.onInkDim),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 460),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isSignUp) ...[
                          TextField(
                            controller: _name,
                            textCapitalization: TextCapitalization.words,
                            decoration:
                                InputDecoration(labelText: l10n.authFieldName),
                          ),
                          const SizedBox(height: 12),
                        ],
                        TextField(
                          controller: _email,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          decoration:
                              InputDecoration(labelText: l10n.authFieldEmail),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _password,
                          obscureText: true,
                          decoration: InputDecoration(
                            labelText: l10n.authFieldPassword,
                            helperText:
                                _isSignUp ? l10n.authPasswordHelper : null,
                          ),
                        ),
                        if (_isSignUp) ...[
                          const SizedBox(height: 12),
                          TextField(
                            controller: _confirm,
                            obscureText: true,
                            decoration: InputDecoration(
                              labelText: l10n.authFieldConfirmPassword,
                            ),
                          ),
                        ],
                        if (failure != null) ...[
                          const SizedBox(height: 14),
                          Text(
                            authFailureMessage(l10n, failure),
                            style: theme.textTheme.bodySmall
                                ?.copyWith(color: theme.colorScheme.error),
                          ),
                        ],
                        const SizedBox(height: 24),
                        // The sheet's action pair: solid pill over outline
                        // pill, stacked and full width.
                        AppButton(
                          label: _busy
                              ? l10n.authWorking
                              : _isSignUp
                                  ? l10n.authCreateAccount
                                  : l10n.authSignIn,
                          onPressed: _busy ? null : _submit,
                        ),
                        const SizedBox(height: 12),
                        AppButton.secondary(
                          label: l10n.authContinueWithoutAccount,
                          onPressed: _busy ? null : _continueAsDemo,
                        ),
                        const SizedBox(height: 4),
                        TextButton(
                          onPressed: _busy
                              ? null
                              : () => setState(() {
                                    _isSignUp = !_isSignUp;
                                    _failure = null;
                                  }),
                          child: Text(
                            _isSignUp
                                ? l10n.authHaveAccount
                                : l10n.authNeedAccount,
                          ),
                        ),
                        if (!auth.canUseSupabase) ...[
                          const SizedBox(height: 8),
                          Text(
                            l10n.authNoBackend,
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
