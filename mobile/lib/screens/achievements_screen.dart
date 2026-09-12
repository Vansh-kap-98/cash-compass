import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/l10n.dart';
import '../l10n/presenters.dart';
import '../logic/badges.dart';
import '../state/achievements_provider.dart';
import '../state/finance_provider.dart';
import '../state/literacy_cards_provider.dart';
import '../state/wishlist_provider.dart';

/// Grid of every badge, grouped by category, showing locked/unlocked state.
///
/// Unlock rules live in `lib/logic/badges.dart`; this screen only displays
/// whatever `AchievementsProvider.unlockedBadgeIds` already holds — it
/// doesn't re-derive anything itself, beyond nudging one recompute on open so
/// a badge earned while this screen wasn't mounted shows up immediately.
class AchievementsScreen extends StatefulWidget {
  const AchievementsScreen({super.key});

  static Future<void> open(BuildContext context) => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AchievementsScreen()),
      );

  @override
  State<AchievementsScreen> createState() => _AchievementsScreenState();
}

class _AchievementsScreenState extends State<AchievementsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AchievementsProvider>().recompute(
            finance: context.read<FinanceProvider>(),
            readLiteracyCardCount:
                context.read<LiteracyCardsProvider>().readCardIds.length,
            wishlistItems: context.read<WishlistProvider>().items,
          );
      // Any celebration snackbar for a badge unlocked just now is already
      // handled by `DashboardScreen`'s listener; draining here only prevents
      // it from firing a second time once that listener next fires.
      context.read<AchievementsProvider>().consumeNewlyUnlocked();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final unlocked = context.watch<AchievementsProvider>().unlockedBadgeIds;

    return Scaffold(
      appBar: AppBar(title: Text(l10n.achievementsScreenTitle)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          for (final category in AchievementCategory.values) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                achievementCategoryLabel(l10n, category),
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            for (final badge in achievementBadges
                .where((b) => b.category == category))
              _BadgeTile(badge: badge, unlocked: unlocked.contains(badge.id)),
          ],
        ],
      ),
    );
  }
}

class _BadgeTile extends StatelessWidget {
  const _BadgeTile({required this.badge, required this.unlocked});

  final AchievementBadge badge;
  final bool unlocked;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Opacity(
        opacity: unlocked ? 1 : 0.55,
        child: ListTile(
          leading: Icon(
            unlocked ? Icons.emoji_events : Icons.emoji_events_outlined,
            color: unlocked ? theme.colorScheme.primary : null,
          ),
          title: Text(achievementBadgeTitle(l10n, badge)),
          subtitle: Text(achievementBadgeDescription(l10n, badge)),
          trailing: Text(
            unlocked ? l10n.achievementUnlockedLabel : l10n.achievementLocked,
            style: theme.textTheme.labelSmall,
          ),
        ),
      ),
    );
  }
}
