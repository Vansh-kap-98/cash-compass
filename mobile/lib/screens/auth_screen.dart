import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
  String? _message;

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
      _message = null;
    });

    final error = _isSignUp
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
      _message = error;
    });
  }

  Future<void> _continueAsDemo() async {
    final auth = context.read<AuthProvider>();
    final finance = context.read<FinanceProvider>();
    final planner = context.read<PlannerProvider>();
    final budgets = context.read<BudgetPlanProvider>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Continue without an account?'),
        content: const Text(
          'Demo mode starts from a clean slate — any data already on this '
          'device will be cleared. Nothing is sent anywhere.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Continue'),
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
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.explore_outlined,
                    size: 48,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Cash Compass',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Live balance and budget signals, on your terms.',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: 28),
                  if (_isSignUp) ...[
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.words,
                      decoration: const InputDecoration(labelText: 'Name'),
                    ),
                    const SizedBox(height: 12),
                  ],
                  TextField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autocorrect: false,
                    decoration: const InputDecoration(labelText: 'Email'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _password,
                    obscureText: true,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      helperText: _isSignUp ? 'At least 8 characters' : null,
                    ),
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _confirm,
                      obscureText: true,
                      decoration:
                          const InputDecoration(labelText: 'Confirm password'),
                    ),
                  ],
                  if (_message != null) ...[
                    const SizedBox(height: 14),
                    Text(
                      _message!,
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.error),
                    ),
                  ],
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(
                      _busy
                          ? 'Working…'
                          : _isSignUp
                              ? 'Create account'
                              : 'Sign in',
                    ),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                              _isSignUp = !_isSignUp;
                              _message = null;
                            }),
                    child: Text(
                      _isSignUp
                          ? 'Already have an account? Sign in'
                          : 'Need an account? Sign up',
                    ),
                  ),
                  if (!auth.canUseSupabase) ...[
                    const SizedBox(height: 8),
                    Text(
                      'This build has no account backend configured. '
                      'Demo mode works fully offline.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  OutlinedButton(
                    onPressed: _busy ? null : _continueAsDemo,
                    child: const Text('Continue without an account'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
