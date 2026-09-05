/// Turns the logic layer's descriptors into words.
///
/// `lib/logic/` is deliberately free of Flutter imports and of display strings:
/// its rules decide *what* is true and with which figures, and everything here
/// decides how to say it. That split is what lets the same rule read correctly
/// in English and in Russian, where a count changes the noun ending, and it
/// keeps those rules unit-testable without a widget harness.
///
/// Anything taking money is handed a `formatMoney` callback rather than a
/// [CurrencyProvider], so these stay usable from a test with a stub formatter.
library;

import '../logic/budget_math.dart';
import '../logic/events.dart';
import '../logic/insights.dart';
import '../logic/receipt_parser.dart';
import '../logic/student_planner.dart';
import '../models/budget_plan.dart';
import '../models/transaction.dart';
import '../models/workspace_widget.dart';
import '../state/auth_provider.dart';
import '../state/budget_plan_provider.dart';
import '../state/locale_provider.dart';
import 'gen/app_localizations.dart';

/// Formats a USD amount in whatever currency is on screen.
typedef MoneyFormatter = String Function(double usd);

// --------------------------------------------------------------- categories

/// Display name for a stored category.
///
/// Categories are persisted as English strings (`'Groceries'`) and are shared
/// with the web app's JSON, so the stored value must not change. Only the label
/// is translated, and an unrecognised one — a category from a newer build, or
/// hand-edited data — falls back to itself rather than to a blank chip.
String categoryLabel(AppLocalizations l10n, String stored) => switch (stored) {
      'Income' => l10n.categoryIncome,
      'Salary' => l10n.categorySalary,
      'Freelance' => l10n.categoryFreelance,
      'Groceries' => l10n.categoryGroceries,
      'Transport' => l10n.categoryTransport,
      'Housing' => l10n.categoryHousing,
      'Utilities' => l10n.categoryUtilities,
      'Entertainment' => l10n.categoryEntertainment,
      'Food' => l10n.categoryFood,
      'Shopping' => l10n.categoryShopping,
      'Health' => l10n.categoryHealth,
      'Travel' => l10n.categoryTravel,
      'Education' => l10n.categoryEducation,
      'Savings' => l10n.categorySavings,
      'Investment' => l10n.categoryInvestment,
      'Business' => l10n.categoryBusiness,
      'Gift' => l10n.categoryGift,
      'Other' => l10n.categoryOther,
      _ => stored,
    };

// ------------------------------------------------------------------- models

String recurrenceLabel(AppLocalizations l10n, Recurrence r) => switch (r) {
      Recurrence.none => l10n.recurrenceNone,
      Recurrence.daily => l10n.recurrenceDaily,
      Recurrence.weekly => l10n.recurrenceWeekly,
      Recurrence.biweekly => l10n.recurrenceBiweekly,
      Recurrence.monthly => l10n.recurrenceMonthly,
      Recurrence.yearly => l10n.recurrenceYearly,
    };

String reasonTagLabel(AppLocalizations l10n, ReasonTag t) => switch (t) {
      ReasonTag.emotional => l10n.reasonEmotional,
      ReasonTag.social => l10n.reasonSocial,
      ReasonTag.discount => l10n.reasonDiscount,
      ReasonTag.impulse => l10n.reasonImpulse,
    };

/// Adjective form, for use inside a sentence ("mostly impulse purchases").
String reasonTagAdjective(AppLocalizations l10n, ReasonTag t) => switch (t) {
      ReasonTag.emotional => l10n.reasonAdjEmotional,
      ReasonTag.social => l10n.reasonAdjSocial,
      ReasonTag.discount => l10n.reasonAdjDiscount,
      ReasonTag.impulse => l10n.reasonAdjImpulse,
    };

String budgetPlanTypeLabel(AppLocalizations l10n, BudgetPlanType t) =>
    switch (t) {
      BudgetPlanType.trip => l10n.budgetTypeTrip,
      BudgetPlanType.outing => l10n.budgetTypeOuting,
      BudgetPlanType.event => l10n.budgetTypeEvent,
    };

String workspaceWidgetLabel(AppLocalizations l10n, WorkspaceWidgetType t) =>
    switch (t) {
      WorkspaceWidgetType.todaySnapshot => l10n.widgetTodaySnapshot,
      WorkspaceWidgetType.budgetHealth => l10n.widgetBudgetHealth,
      WorkspaceWidgetType.topCategories => l10n.widgetTopCategories,
      WorkspaceWidgetType.goalProgress => l10n.widgetGoalProgress,
      WorkspaceWidgetType.safeToSpend => l10n.widgetSafeToSpend,
      WorkspaceWidgetType.subStashJar => l10n.widgetSubStashJar,
      WorkspaceWidgetType.burnRateLine => l10n.widgetBurnRateLine,
      WorkspaceWidgetType.quickEntryPad => l10n.widgetQuickEntryPad,
      WorkspaceWidgetType.wasteAuditor => l10n.widgetWasteAuditor,
      WorkspaceWidgetType.roommateSync => l10n.widgetRoommateSync,
      WorkspaceWidgetType.media => l10n.widgetMedia,
      WorkspaceWidgetType.mangaStatus => l10n.widgetMangaStatus,
      WorkspaceWidgetType.asciiFortune => l10n.widgetAsciiFortune,
      WorkspaceWidgetType.chibiMascot => l10n.widgetChibiMascot,
      WorkspaceWidgetType.growthGem => l10n.widgetGrowthGem,
    };

String widgetSizeLabel(AppLocalizations l10n, WidgetSize s) => switch (s) {
      WidgetSize.small => l10n.sizeSmall,
      WidgetSize.medium => l10n.sizeMedium,
      WidgetSize.large => l10n.sizeLarge,
    };

// ------------------------------------------------------------------ planner

String survivalZoneLabel(AppLocalizations l10n, SurvivalZone z) => switch (z) {
      SurvivalZone.green => l10n.zoneGreen,
      SurvivalZone.tight => l10n.zoneTight,
      SurvivalZone.critical => l10n.zoneCritical,
    };

String incomeCadenceLabel(AppLocalizations l10n, IncomeCadence c) =>
    switch (c) {
      IncomeCadence.oneTime => l10n.cadenceOneTime,
      IncomeCadence.weekly => l10n.cadenceWeekly,
      IncomeCadence.monthly => l10n.cadenceMonthly,
    };

// ------------------------------------------------------------------ budgets

String budgetPlanErrorMessage(AppLocalizations l10n, BudgetPlanError e) =>
    switch (e) {
      BudgetPlanError.nothingToFinalise => l10n.budgetErrorNothing,
      BudgetPlanError.noTitle => l10n.budgetErrorNoTitle,
      BudgetPlanError.noItems => l10n.budgetErrorNoItems,
      BudgetPlanError.badDates => l10n.budgetErrorBadDates,
    };

// --------------------------------------------------------------------- auth

String authErrorMessage(AppLocalizations l10n, AuthError e) => switch (e) {
      AuthError.noBackend => l10n.authErrorNoSupabase,
      AuthError.missingCredentials => l10n.authErrorMissingCredentials,
      AuthError.signInFailed => l10n.authErrorSignInFailed,
      AuthError.signUpFailed => l10n.authErrorSignUpFailed,
      AuthError.confirmEmail => l10n.authErrorConfirmEmail,
      AuthError.missingName => l10n.authErrorMissingName,
      AuthError.invalidEmail => l10n.authErrorInvalidEmail,
      AuthError.shortPassword => l10n.authErrorShortPassword,
      AuthError.passwordMismatch => l10n.authErrorPasswordMismatch,
    };

/// A Supabase-authored message is shown verbatim; see [AuthServerFailure].
String authFailureMessage(AppLocalizations l10n, AuthFailure f) => switch (f) {
      AuthErrorFailure(:final error) => authErrorMessage(l10n, error),
      AuthServerFailure(:final message) => message,
    };

// ----------------------------------------------------------------- location

String geoProfileLabel(AppLocalizations l10n, String key) => switch (key) {
      'india-metro' => l10n.geoIndiaMetro,
      'eastern-europe' => l10n.geoEasternEurope,
      _ => l10n.geoUsCity,
    };

String stapleLabel(AppLocalizations l10n, StapleKind k) => switch (k) {
      StapleKind.lunch => l10n.stapleLunch,
      StapleKind.transit => l10n.stapleTransit,
      StapleKind.groceries => l10n.stapleGroceries,
    };

String stapleBadge(AppLocalizations l10n, StapleVerdict v) =>
    v.affordable ? l10n.badgeOnBudget : l10n.badgeTrimNeeded;

String dailyTipMessage(AppLocalizations l10n, DailyTip tip) => switch (tip) {
      DailyTip.overBudget => l10n.tipOverBudget,
      DailyTip.finalQuarter => l10n.tipFinalQuarter,
      DailyTip.comfortable => l10n.tipComfortable,
      DailyTip.plannedOverBudget => l10n.tipPlannedOverBudget,
      DailyTip.averageOverBudget => l10n.tipAverageOverBudget,
      DailyTip.categoryCaps => l10n.tipCategoryCaps,
    };

// ------------------------------------------------------------------- events

String regionLabel(AppLocalizations l10n, Region r) =>
    r == Region.india ? l10n.regionIndia : l10n.regionRussia;

String eventName(AppLocalizations l10n, FinancialEventKind k) => switch (k) {
      FinancialEventKind.winterExam => l10n.eventWinterExamName,
      FinancialEventKind.newYear => l10n.eventNewYearName,
      FinancialEventKind.stipend => l10n.eventStipendName,
      FinancialEventKind.universityExam => l10n.eventUniExamName,
      FinancialEventKind.diwali => l10n.eventDiwaliName,
      FinancialEventKind.semesterReset => l10n.eventSemesterName,
    };

/// The explanatory line for an event. Not currently rendered by any card — the
/// forecast box says more with real numbers — but kept translated alongside the
/// name so the data stays whole.
String eventNote(AppLocalizations l10n, FinancialEventKind k) => switch (k) {
      FinancialEventKind.winterExam => l10n.eventWinterExamNote,
      FinancialEventKind.newYear => l10n.eventNewYearNote,
      FinancialEventKind.stipend => l10n.eventStipendNote,
      FinancialEventKind.universityExam => l10n.eventUniExamNote,
      FinancialEventKind.diwali => l10n.eventDiwaliNote,
      FinancialEventKind.semesterReset => l10n.eventSemesterNote,
    };

String eventTypeLabel(AppLocalizations l10n, FinancialEventType t) =>
    switch (t) {
      FinancialEventType.academic => l10n.eventTypeAcademic,
      FinancialEventType.holiday => l10n.eventTypeHoliday,
      FinancialEventType.income => l10n.eventTypeIncome,
      FinancialEventType.festival => l10n.eventTypeFestival,
      FinancialEventType.studentCosts => l10n.eventTypeStudentCosts,
    };

// ----------------------------------------------------------------- insights

/// The weekday, in whatever form the spending-pattern sentence needs.
///
/// English wants the bare name ("around Friday nights"); Russian wants the
/// adverbial "по пятницам". Both are just this key in their own catalogue.
String weekdayInSentence(AppLocalizations l10n, int isoWeekday) =>
    switch (isoWeekday) {
      DateTime.monday => l10n.weekdayMonday,
      DateTime.tuesday => l10n.weekdayTuesday,
      DateTime.wednesday => l10n.weekdayWednesday,
      DateTime.thursday => l10n.weekdayThursday,
      DateTime.friday => l10n.weekdayFriday,
      DateTime.saturday => l10n.weekdaySaturday,
      _ => l10n.weekdaySunday,
    };

String behaviorInsightMessage(AppLocalizations l10n, BehaviorInsight i) {
  final weekday = weekdayInSentence(l10n, i.weekday);
  final tag = reasonTagAdjective(l10n, i.tag);
  return i.isNight
      ? l10n.spendingPatternNight(weekday, tag, i.count)
      : l10n.spendingPatternDay(weekday, tag, i.count);
}

/// Heading for one Smart Suggestion.
String suggestionTitle(AppLocalizations l10n, Suggestion s) => switch (s) {
      WatchCategorySuggestion(:final category) =>
        l10n.suggestionWatchCategoryTitle(categoryLabel(l10n, category)),
      BudgetAlertSuggestion(:final category) =>
        l10n.suggestionBudgetAlertTitle(categoryLabel(l10n, category)),
      AuditSubscriptionsSuggestion() => l10n.suggestionAuditSubsTitle,
      TrackForSevenDaysSuggestion() => l10n.suggestionTrackTitle,
    };

/// Body text for one Smart Suggestion.
String suggestionBody(
  AppLocalizations l10n,
  Suggestion s,
  MoneyFormatter formatMoney,
) =>
    switch (s) {
      WatchCategorySuggestion(:final savingUsd) =>
        l10n.suggestionWatchCategoryBody(formatMoney(savingUsd)),
      BudgetAlertSuggestion(:final percentUsed) =>
        l10n.suggestionBudgetAlertBody(percentUsed),
      // Merchant names as printed on the receipt — not translatable.
      AuditSubscriptionsSuggestion(:final names) =>
        l10n.suggestionAuditSubsBody(names.join(', ')),
      TrackForSevenDaysSuggestion() => l10n.suggestionTrackBody,
    };

String goalInsightMessage(AppLocalizations l10n, GoalInsight g) => switch (g) {
      GoalInsightEmpty() => l10n.goalInsightEmpty,
      GoalInsightTopShare(:final category, :final percent) =>
        l10n.goalInsightTopShare(categoryLabel(l10n, category), percent),
      GoalInsightTopTwo(:final first, :final second, :final percent) =>
        l10n.goalInsightTopTwo(
          categoryLabel(l10n, first),
          categoryLabel(l10n, second),
          percent,
        ),
      GoalInsightAutomate() => l10n.goalInsightAutomate,
      GoalInsightReviewWeekly() => l10n.goalInsightReviewWeekly,
    };

// ----------------------------------------------------------------- receipts

/// Wording for a total the parser could not corroborate.
///
/// The figures are printed as they appeared on the receipt, so they are
/// formatted plainly rather than converted — an em dash stands in for a value
/// that was never read.
String receiptDiscrepancyMessage(
  AppLocalizations l10n,
  ReceiptDiscrepancy d,
) {
  String money(double? v) => v == null ? '—' : v.toStringAsFixed(2);
  return switch (d) {
    CashChangeDiscrepancy(:final labelled, :final computed) =>
      l10n.receiptDiscrepancyCash(money(labelled), money(computed)),
    ItemSumDiscrepancy(:final labelled, :final itemSum) =>
      l10n.receiptDiscrepancyItems(money(labelled), money(itemSum)),
  };
}

// ----------------------------------------------------------------- settings

String languageLabel(AppLocalizations l10n, AppLanguage language) =>
    switch (language) {
      AppLanguage.system => l10n.settingsLanguageSystem,
      // Each language names itself in its own tongue, never translated: someone
      // stuck in a language they cannot read has to be able to find their way
      // out of this menu.
      AppLanguage.english => 'English',
      AppLanguage.russian => 'Русский',
    };

// -------------------------------------------------------------------- dates

/// Short month name for the bar chart's axis.
String shortMonthName(AppLocalizations l10n, int month) => switch (month) {
      DateTime.january => l10n.monthJan,
      DateTime.february => l10n.monthFeb,
      DateTime.march => l10n.monthMar,
      DateTime.april => l10n.monthApr,
      DateTime.may => l10n.monthMay,
      DateTime.june => l10n.monthJun,
      DateTime.july => l10n.monthJul,
      DateTime.august => l10n.monthAug,
      DateTime.september => l10n.monthSep,
      DateTime.october => l10n.monthOct,
      DateTime.november => l10n.monthNov,
      _ => l10n.monthDec,
    };
