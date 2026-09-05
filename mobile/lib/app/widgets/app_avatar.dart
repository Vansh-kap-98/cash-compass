import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Plain circle with initials.
///
/// No photo support: nothing in this app has ever had an avatar image to show,
/// and adding the loading, error and cache states for a source that does not
/// exist would be scaffolding around nothing. Add it when there is a URL.
class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    required this.name,
    this.size = 40,
    this.muted = false,
  });

  /// The display name. Initials are derived from it; an empty or symbol-only
  /// name falls back to a neutral glyph rather than rendering a blank circle.
  final String name;

  final double size;

  /// Grey ground instead of black.
  final bool muted;

  /// Up to two initials.
  ///
  /// Works on Cyrillic as well as Latin because it splits on whitespace and
  /// takes characters rather than matching an alphabet.
  static String initialsOf(String name) {
    final parts =
        name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '—';

    // An email address has no spaces, so the split gives one part; take its
    // first letter rather than two letters of the local part, which reads as a
    // misspelling.
    if (parts.length == 1) {
      final first = parts.first.characters.firstOrNull;
      return first == null ? '—' : first.toUpperCase();
    }

    final a = parts.first.characters.firstOrNull ?? '';
    final b = parts[1].characters.firstOrNull ?? '';
    final initials = '$a$b'.toUpperCase();
    return initials.isEmpty ? '—' : initials;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: muted ? AppColors.subtleFill : AppColors.ink,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Padding(
          padding: EdgeInsets.all(size * 0.2),
          child: Text(
            initialsOf(name),
            style: TextStyle(
              fontSize: size * 0.36,
              height: 1,
              fontWeight: FontWeight.w700,
              color: muted ? AppColors.inkSecondary : AppColors.surface,
            ),
          ),
        ),
      ),
    );
  }
}
