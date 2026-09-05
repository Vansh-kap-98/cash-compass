import 'package:flutter/painting.dart';

/// The palette. Monochrome, with exactly one exception.
///
/// This replaces the per-theme transcription of the web app's CSS variables
/// that used to live in `app_tokens.dart`. There is no theme switching any
/// more: one palette, established here, read everywhere through
/// `Theme.of(context)`.
///
/// Contrast ratios below are against [surface] (white) unless stated, computed
/// per WCAG 2.1. They are recorded because "looks fine on a bright monitor" is
/// how the previous palette shipped a 2.2:1 button label.
abstract final class AppColors {
  // ------------------------------------------------------------- greyscale

  /// Primary ink, and the fill of primary buttons and icon tiles. 21:1.
  static const ink = Color(0xFF000000);

  /// Page and card ground.
  static const surface = Color(0xFFFFFFFF);

  /// Secondary text: captions, list subtitles, metadata. 8.7:1 — clears AAA,
  /// which matters because most of this app's small print lives at this step.
  static const inkSecondary = Color(0xFF4A4A4A);

  /// The edge of a container: cards, inputs, chips, tiles.
  ///
  /// Ink, drawn one logical pixel wide. A pale edge left every element floating
  /// on the same white ground with nothing to separate it from the next; a slim
  /// black one gives each its own boundary, which is the whole reason the
  /// design is built from bordered surfaces rather than shadows.
  ///
  /// Deliberately *not* the same value as [hairline]. Container edges and the
  /// rules inside them do different jobs, and giving them one colour is what
  /// makes a card full of rows read as a table.
  static const outline = ink;

  /// Rules *inside* a container: dividers between list rows, separators.
  /// Non-text; never put type on this.
  ///
  /// Stays pale on purpose. These sit within a boundary that is already drawn,
  /// so they only need to group — matching them to [outline] would give a
  /// five-row card six competing black lines.
  static const hairline = Color(0xFFE0E0E0);

  /// Subtle fills: the inactive half of a progress track, a muted row, a
  /// pressed state. Non-text.
  static const subtleFill = Color(0xFFF5F5F5);

  /// Disabled text and glyphs. 2.7:1 — deliberately below the 4.5:1 floor so a
  /// dead control reads as dead. WCAG exempts disabled controls; never use this
  /// for anything a user is meant to read and act on.
  static const disabled = Color(0xFF9E9E9E);

  /// Dim inactive icons on the black bottom bar. 4.9:1 against [ink] — legible
  /// as an icon without competing with the lit one.
  static const onInkDim = Color(0xFF8A8A8A);

  /// The decorative curves behind a page. See [AppBackdrop].
  ///
  /// One step darker than [hairline] — 1.36:1 against [surface] rather than
  /// 1.27:1. That sounds like nothing and is the whole difference between a
  /// background motif you can see and one that reads as a rendering artefact.
  /// It stays well under the 3:1 that would start competing with content.
  static const backdropLine = Color(0xFFD8D8D8);

  // ------------------------------------------------------------- exception

  /// The one non-greyscale colour in the app, reserved for destructive
  /// confirmation and error text.
  ///
  /// Everything else communicates state through weight, icon, and wording. This
  /// exists because Cash Compass has actions that permanently delete a user's
  /// financial history with no undo — "Reset all finance data" wipes every
  /// transaction, goal and budget — and a pre-attentive cue on those is worth
  /// more than palette purity. 5.6:1 on white.
  ///
  /// If you are reaching for this for anything that is not destructive or an
  /// error, use weight or an icon instead.
  static const error = Color(0xFFC62828);

  /// Ink on [error] fills. 5.6:1 the other way.
  static const onError = Color(0xFFFFFFFF);
}
