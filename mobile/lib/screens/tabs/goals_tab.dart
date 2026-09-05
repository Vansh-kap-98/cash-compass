import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/widgets/app_card.dart';
import '../../app/widgets/app_progress_ring.dart';
import '../../app/widgets/goal_icon.dart';
import '../../l10n/l10n.dart';
import '../../l10n/presenters.dart';
import '../../logic/insights.dart';
import '../../models/savings_goal.dart';
import '../../state/currency_provider.dart';
import '../../state/finance_provider.dart';
import '../../widgets/financial_charts.dart';
import '../budget_plan_screen.dart';
import '../../app/theme/app_colors.dart';

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
        AppCard(
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
    return AppCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(
            Icons.savings_outlined,
            size: 40,
            color: AppColors.disabled,
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

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // The ring replaces the percentage-plus-bar pair. It says the
              // same thing in one mark instead of two, and it is the shape the
              // design calls for wherever a proportion is shown.
              AppProgressRing(progress: goal.progress, size: 56),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(goalIcon(goal.icon), size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            goal.name,
                            style: theme.textTheme.titleMedium,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      l10n.goalAmountOf(
                        currency.formatFromUsd(goal.current),
                        currency.formatFromUsd(goal.target),
                      ),
                      style: theme.textTheme.bodySmall,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
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
          ),
        ],
      ),
    );
  }
}
