/// Single import for everything localisation-related.
///
/// Widgets take `context.l10n` rather than the generated
/// `AppLocalizations.of(context)`; it is shorter at the ~400 call sites that
/// need it, and it keeps the generated class name out of the widget code.
library;

import 'package:flutter/widgets.dart';

import 'gen/app_localizations.dart';

export 'gen/app_localizations.dart';

extension L10nContext on BuildContext {
  /// The active translations.
  ///
  /// Non-null because `nullable-getter: false` is set in `l10n.yaml` and the
  /// app installs the delegates at the root — see `main.dart`.
  AppLocalizations get l10n => AppLocalizations.of(this);
}
