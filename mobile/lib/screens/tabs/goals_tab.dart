import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../l10n/l10n.dart';
import '../../l10n/presenters.dart';
import '../../logic/insights.dart';
import '../../models/savings_goal.dart';
import '../../state/currency_provider.dart';
import '../../state/finance_provider.dart';
import '../../widgets/financial_charts.dart';
import '../budget_plan_screen.dart';

/// The Goals tab: savings targets, spending charts, and derived guidance.
class GoalsTab extends StatelessWidget {
  const GoalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final finance = context.watch<FinanceProvider>();
    final suggestions = goalInsights(finance.transactions);

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      children: [
        if (finance.goals.isEmpty)
          const _EmptyGoals()
        else
          for (final goal in finance.goals)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _GoalCard(goal: goal),
            ),
        const SizedBox(height: 8),
        const BudgetReceiptsCard(),
        const SizedBox(height: 16),
        const CategoryDonut(),
        const SizedBox(height: 16),
        const MonthlyBars(),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.goalsGuidanceTitle,
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: 10),
                for (final s in suggestions)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('•  ', style: theme.textTheme.bodyMedium),
                        Expanded(
                          child: Text(
                            goalInsightMessage(l10n, s),
                            style: theme.textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyGoals extends StatelessWidget {
  const _EmptyGoals();

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Icon(
              Icons.savings_outlined,
              size: 40,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 12),
            Text(
              l10n.goalsEmptyTitle,
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              l10n.goalsEmptyBody,
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal});

  final SavingsGoal goal;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    final currency = context.watch<CurrencyProvider>();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(goal.icon, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(goal.name, style: theme.textTheme.titleMedium),
                ),
                Text('${(goal.progress * 100).round()}%'),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                value: goal.progress,
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  l10n.goalAmountOf(
                    currency.formatFromUsd(goal.current),
                    currency.formatFromUsd(goal.target),
                  ),
                  style: theme.textTheme.bodySmall,
                ),
                TextButton(
                  // The contribution is a round number in the user's own
                  // currency, converted to USD for storage — the web app added
                  // a literal 100 regardless of the active currency.
                  onPressed: goal.isComplete
                      ? null
                      : () => context.read<FinanceProvider>().contributeToGoal(
                            goal.id,
                            currency.convertToUsd(100),
                          ),
                  child: Text(
                    l10n.goalAddAmount(
                      currency.formatAmount(100, decimalDigits: 0),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
