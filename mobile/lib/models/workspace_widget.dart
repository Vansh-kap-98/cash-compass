import 'json_utils.dart';

/// The widget types available on the workspace canvas.
///
/// `wasteAuditor` and `roommateSync` existed on the web with hardcoded
/// placeholder data and dead buttons; here they read real detected
/// subscriptions and real split plans.
enum WorkspaceWidgetType {
  todaySnapshot,
  budgetHealth,
  topCategories,
  goalProgress,
  safeToSpend,
  subStashJar,
  burnRateLine,
  quickEntryPad,
  wasteAuditor,
  roommateSync,
  media,
  mangaStatus,
  asciiFortune,
  chibiMascot,
  growthGem,
}

extension WorkspaceWidgetTypeLabel on WorkspaceWidgetType {
  String get label => switch (this) {
        WorkspaceWidgetType.todaySnapshot => 'Today Snapshot',
        WorkspaceWidgetType.budgetHealth => 'Budget Health',
        WorkspaceWidgetType.topCategories => 'Top Categories',
        WorkspaceWidgetType.goalProgress => 'Goal Progress',
        WorkspaceWidgetType.safeToSpend => 'Safe-to-Spend',
        WorkspaceWidgetType.subStashJar => 'Sub-Stash Jar',
        WorkspaceWidgetType.burnRateLine => 'Burn-Rate Line',
        WorkspaceWidgetType.quickEntryPad => 'Quick-Entry Pad',
        WorkspaceWidgetType.wasteAuditor => 'Waste Auditor',
        WorkspaceWidgetType.roommateSync => 'Roommate Sync',
        WorkspaceWidgetType.media => 'Image',
        WorkspaceWidgetType.mangaStatus => 'Manga Status',
        WorkspaceWidgetType.asciiFortune => 'ASCII Fortune',
        WorkspaceWidgetType.chibiMascot => 'Chibi Mascot',
        WorkspaceWidgetType.growthGem => 'Growth Gem',
      };
}

/// Card height, replacing the web app's 12-column drag-resize.
///
/// Pixel-precise resize handles need a mouse; a three-state toggle is the
/// touch-appropriate equivalent and every card is full width on a phone.
enum WidgetSize { small, medium, large }

extension WidgetSizeHeight on WidgetSize {
  double get height => switch (this) {
        WidgetSize.small => 130,
        WidgetSize.medium => 210,
        WidgetSize.large => 320,
      };

  String get label => switch (this) {
        WidgetSize.small => 'S',
        WidgetSize.medium => 'M',
        WidgetSize.large => 'L',
      };

  WidgetSize get next => switch (this) {
        WidgetSize.small => WidgetSize.medium,
        WidgetSize.medium => WidgetSize.large,
        WidgetSize.large => WidgetSize.small,
      };
}

/// One placed widget on the workspace.
class WorkspaceWidget {
  const WorkspaceWidget({
    required this.id,
    required this.type,
    this.size = WidgetSize.medium,
    this.mediaPath,
  });

  final String id;
  final WorkspaceWidgetType type;
  final WidgetSize size;

  /// Filename of a picked image, relative to the app documents directory.
  ///
  /// The web app inlined the whole image as a base64 data URL inside the same
  /// JSON blob, which on mobile would mean re-encoding megabytes on every
  /// layout change.
  final String? mediaPath;

  WorkspaceWidget copyWith({WidgetSize? size, String? mediaPath}) =>
      WorkspaceWidget(
        id: id,
        type: type,
        size: size ?? this.size,
        mediaPath: mediaPath ?? this.mediaPath,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'type': type.name,
        'size': size.name,
        if (mediaPath != null) 'mediaPath': mediaPath,
      };

  factory WorkspaceWidget.fromJson(Map<String, dynamic> j) {
    return WorkspaceWidget(
      id: j['id'] as String,
      type: enumByName(
        WorkspaceWidgetType.values,
        j['type'],
        WorkspaceWidgetType.todaySnapshot,
      ),
      size: _sizeFrom(j),
      mediaPath: j['mediaPath'] as String?,
    );
  }

  /// Reads the new `size` field, falling back to translating the web app's
  /// `rowSpan` so a layout exported from the browser still opens sensibly.
  static WidgetSize _sizeFrom(Map<String, dynamic> j) {
    final named = j['size'];
    if (named is String) {
      return enumByName(WidgetSize.values, named, WidgetSize.medium);
    }
    final rowSpan = (j['rowSpan'] as num?)?.toInt();
    if (rowSpan == null) return WidgetSize.medium;
    if (rowSpan <= 1) return WidgetSize.small;
    if (rowSpan <= 3) return WidgetSize.medium;
    return WidgetSize.large;
  }
}
