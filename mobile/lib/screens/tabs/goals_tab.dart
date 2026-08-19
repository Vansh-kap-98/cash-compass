import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../state/currency_provider.dart';
import '../../state/finance_provider.dart';

/// The Goals tab. Charts and the AI suggestion strings arrive in a later
/// milestone; this covers the goal list and contribution flow.
class GoalsTab extends StatelessWidget {
  const GoalsTab({super.key});

  @override
  Widget build(BuildContext context) {
    final finance = context.watch<FinanceProvider>();
    final currency = context.watch<CurrencyProvider>();
    final theme = Theme.of(context);

    if (finance.goals.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(
            'No savings goals yet.',
            style: theme.textTheme.bodyLarge,
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
      itemCount: finance.goals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        final goal = finance.goals[i];
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
                      child: Text(
                        goal.name,
                        style: theme.textTheme.titleMedium,
                      ),
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
                      '${currency.formatFromUsd(goal.current)}'
                      ' of ${currency.formatFromUsd(goal.target)}',
                      style: theme.textTheme.bodySmall,
                    ),
                    TextButton(
                      onPressed: goal.isComplete
                          ? null
                          : () => context
                              .read<FinanceProvider>()
                              .contributeToGoal(goal.id, 100),
                      child: const Text('Add 100'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
