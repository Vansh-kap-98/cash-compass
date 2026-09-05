import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_ru.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'gen/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
      : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('ru')
  ];

  /// Application name. Not translated — it is the product name.
  ///
  /// In en, this message translates to:
  /// **'Cash Compass'**
  String get appTitle;

  /// No description provided for @tabDashboard.
  ///
  /// In en, this message translates to:
  /// **'Dashboard'**
  String get tabDashboard;

  /// No description provided for @tabGoals.
  ///
  /// In en, this message translates to:
  /// **'Goals'**
  String get tabGoals;

  /// No description provided for @tabPlanner.
  ///
  /// In en, this message translates to:
  /// **'Planner'**
  String get tabPlanner;

  /// No description provided for @tabWorkspace.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get tabWorkspace;

  /// No description provided for @tabSettings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get tabSettings;

  /// No description provided for @actionCancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get actionCancel;

  /// No description provided for @actionSave.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get actionSave;

  /// No description provided for @actionAdd.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get actionAdd;

  /// No description provided for @actionClear.
  ///
  /// In en, this message translates to:
  /// **'Clear'**
  String get actionClear;

  /// No description provided for @actionDone.
  ///
  /// In en, this message translates to:
  /// **'Done'**
  String get actionDone;

  /// No description provided for @actionRemove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get actionRemove;

  /// No description provided for @actionContinue.
  ///
  /// In en, this message translates to:
  /// **'Continue'**
  String get actionContinue;

  /// No description provided for @actionReset.
  ///
  /// In en, this message translates to:
  /// **'Reset'**
  String get actionReset;

  /// No description provided for @actionDiscard.
  ///
  /// In en, this message translates to:
  /// **'Discard'**
  String get actionDiscard;

  /// No description provided for @actionKeep.
  ///
  /// In en, this message translates to:
  /// **'Keep'**
  String get actionKeep;

  /// No description provided for @actionSkip.
  ///
  /// In en, this message translates to:
  /// **'Skip'**
  String get actionSkip;

  /// No description provided for @actionInclude.
  ///
  /// In en, this message translates to:
  /// **'Include'**
  String get actionInclude;

  /// No description provided for @actionUndo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get actionUndo;

  /// No description provided for @actionSettle.
  ///
  /// In en, this message translates to:
  /// **'Settle'**
  String get actionSettle;

  /// No description provided for @labelSettled.
  ///
  /// In en, this message translates to:
  /// **'Settled'**
  String get labelSettled;

  /// No description provided for @authTagline.
  ///
  /// In en, this message translates to:
  /// **'Live balance and budget signals, on your terms.'**
  String get authTagline;

  /// No description provided for @authFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get authFieldName;

  /// No description provided for @authFieldEmail.
  ///
  /// In en, this message translates to:
  /// **'Email'**
  String get authFieldEmail;

  /// No description provided for @authFieldPassword.
  ///
  /// In en, this message translates to:
  /// **'Password'**
  String get authFieldPassword;

  /// No description provided for @authFieldConfirmPassword.
  ///
  /// In en, this message translates to:
  /// **'Confirm password'**
  String get authFieldConfirmPassword;

  /// No description provided for @authPasswordHelper.
  ///
  /// In en, this message translates to:
  /// **'At least 8 characters'**
  String get authPasswordHelper;

  /// No description provided for @authWorking.
  ///
  /// In en, this message translates to:
  /// **'Working…'**
  String get authWorking;

  /// No description provided for @authCreateAccount.
  ///
  /// In en, this message translates to:
  /// **'Create account'**
  String get authCreateAccount;

  /// No description provided for @authSignIn.
  ///
  /// In en, this message translates to:
  /// **'Sign in'**
  String get authSignIn;

  /// No description provided for @authHaveAccount.
  ///
  /// In en, this message translates to:
  /// **'Already have an account? Sign in'**
  String get authHaveAccount;

  /// No description provided for @authNeedAccount.
  ///
  /// In en, this message translates to:
  /// **'Need an account? Sign up'**
  String get authNeedAccount;

  /// No description provided for @authNoBackend.
  ///
  /// In en, this message translates to:
  /// **'This build has no account backend configured. Demo mode works fully offline.'**
  String get authNoBackend;

  /// No description provided for @authContinueWithoutAccount.
  ///
  /// In en, this message translates to:
  /// **'Continue without an account'**
  String get authContinueWithoutAccount;

  /// No description provided for @authDemoDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Continue without an account?'**
  String get authDemoDialogTitle;

  /// No description provided for @authDemoDialogBody.
  ///
  /// In en, this message translates to:
  /// **'Demo mode starts from a clean slate — any data already on this device will be cleared. Nothing is sent anywhere.'**
  String get authDemoDialogBody;

  /// No description provided for @authErrorNoSupabase.
  ///
  /// In en, this message translates to:
  /// **'Accounts are unavailable — this build has no Supabase config. Use demo mode.'**
  String get authErrorNoSupabase;

  /// No description provided for @authErrorMissingCredentials.
  ///
  /// In en, this message translates to:
  /// **'Enter your email and password.'**
  String get authErrorMissingCredentials;

  /// No description provided for @authErrorSignInFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not sign in. Please try again.'**
  String get authErrorSignInFailed;

  /// No description provided for @authErrorSignUpFailed.
  ///
  /// In en, this message translates to:
  /// **'Could not create the account. Please try again.'**
  String get authErrorSignUpFailed;

  /// No description provided for @authErrorConfirmEmail.
  ///
  /// In en, this message translates to:
  /// **'Check your email to confirm your account, then sign in.'**
  String get authErrorConfirmEmail;

  /// No description provided for @authErrorMissingName.
  ///
  /// In en, this message translates to:
  /// **'Enter your name.'**
  String get authErrorMissingName;

  /// No description provided for @authErrorInvalidEmail.
  ///
  /// In en, this message translates to:
  /// **'Enter a valid email address.'**
  String get authErrorInvalidEmail;

  /// No description provided for @authErrorShortPassword.
  ///
  /// In en, this message translates to:
  /// **'Password must be at least 8 characters.'**
  String get authErrorShortPassword;

  /// No description provided for @authErrorPasswordMismatch.
  ///
  /// In en, this message translates to:
  /// **'Passwords do not match.'**
  String get authErrorPasswordMismatch;

  /// No description provided for @quickScanReceipt.
  ///
  /// In en, this message translates to:
  /// **'Scan Receipt'**
  String get quickScanReceipt;

  /// No description provided for @quickScanReceiptSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Read the amount from a photo'**
  String get quickScanReceiptSubtitle;

  /// No description provided for @quickScanSeveral.
  ///
  /// In en, this message translates to:
  /// **'Scan Several'**
  String get quickScanSeveral;

  /// No description provided for @quickScanSeveralSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Pick receipts from your gallery'**
  String get quickScanSeveralSubtitle;

  /// No description provided for @quickAddEntry.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get quickAddEntry;

  /// No description provided for @quickAddEntrySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Log an expense or income'**
  String get quickAddEntrySubtitle;

  /// No description provided for @quickSetGoal.
  ///
  /// In en, this message translates to:
  /// **'Set Goal'**
  String get quickSetGoal;

  /// No description provided for @quickSetGoalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Create a savings target'**
  String get quickSetGoalSubtitle;

  /// No description provided for @quickPlanBudget.
  ///
  /// In en, this message translates to:
  /// **'Plan Budget'**
  String get quickPlanBudget;

  /// No description provided for @quickPlanBudgetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Cost out a trip, outing, or event'**
  String get quickPlanBudgetSubtitle;

  /// No description provided for @scanErrorCameraUnavailable.
  ///
  /// In en, this message translates to:
  /// **'Camera unavailable — check the permission in Settings. Add the entry by hand for now.'**
  String get scanErrorCameraUnavailable;

  /// No description provided for @scanErrorNoText.
  ///
  /// In en, this message translates to:
  /// **'No text found in that photo. Try again in better light, or type it in.'**
  String get scanErrorNoText;

  /// No description provided for @scanErrorNothingUseful.
  ///
  /// In en, this message translates to:
  /// **'Could not find an amount on that receipt. Fill it in below.'**
  String get scanErrorNothingUseful;

  /// No description provided for @batchReadingReceipts.
  ///
  /// In en, this message translates to:
  /// **'Reading receipts'**
  String get batchReadingReceipts;

  /// No description provided for @batchProgress.
  ///
  /// In en, this message translates to:
  /// **'{done} of {total}'**
  String batchProgress(int done, int total);

  /// Snack bar after a batch of scanned receipts is written.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Saved {count} receipt.} other{Saved {count} receipts.}}'**
  String batchSavedReceipts(int count);

  /// No description provided for @batchReviewTitle.
  ///
  /// In en, this message translates to:
  /// **'Review receipts'**
  String get batchReviewTitle;

  /// No description provided for @batchNothingToSave.
  ///
  /// In en, this message translates to:
  /// **'Nothing to save'**
  String get batchNothingToSave;

  /// No description provided for @batchSaveCount.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Save {count} receipt} other{Save {count} receipts}}'**
  String batchSaveCount(int count);

  /// No description provided for @batchCouldNotRead.
  ///
  /// In en, this message translates to:
  /// **'Could not read this one'**
  String get batchCouldNotRead;

  /// No description provided for @batchFieldMerchant.
  ///
  /// In en, this message translates to:
  /// **'Merchant'**
  String get batchFieldMerchant;

  /// No description provided for @batchNoPhotoDate.
  ///
  /// In en, this message translates to:
  /// **'no photo date'**
  String get batchNoPhotoDate;

  /// No description provided for @batchRetryTooltip.
  ///
  /// In en, this message translates to:
  /// **'Read this one again'**
  String get batchRetryTooltip;

  /// No description provided for @batchDuplicateWarning.
  ///
  /// In en, this message translates to:
  /// **'Looks like a repeat of an earlier receipt in this batch. Skip it if you picked the same photo twice.'**
  String get batchDuplicateWarning;

  /// No description provided for @batchAmountConverted.
  ///
  /// In en, this message translates to:
  /// **'{amount} {code} converted'**
  String batchAmountConverted(String amount, String code);

  /// No description provided for @scannedPleaseCheck.
  ///
  /// In en, this message translates to:
  /// **'Scanned — please check'**
  String get scannedPleaseCheck;

  /// No description provided for @receiptDiscrepancyCash.
  ///
  /// In en, this message translates to:
  /// **'Labelled total {labelled} disagrees with cash − change {computed}. Using the arithmetic.'**
  String receiptDiscrepancyCash(String labelled, String computed);

  /// No description provided for @receiptDiscrepancyItems.
  ///
  /// In en, this message translates to:
  /// **'Total {labelled} does not match the items ({itemSum}) — please confirm.'**
  String receiptDiscrepancyItems(String labelled, String itemSum);

  /// No description provided for @dashTotalBalance.
  ///
  /// In en, this message translates to:
  /// **'Total balance'**
  String get dashTotalBalance;

  /// No description provided for @dashSnapshotHint.
  ///
  /// In en, this message translates to:
  /// **'This snapshot drives the whole dashboard.'**
  String get dashSnapshotHint;

  /// No description provided for @dashStatAvailable.
  ///
  /// In en, this message translates to:
  /// **'Available'**
  String get dashStatAvailable;

  /// No description provided for @dashStatSpentToday.
  ///
  /// In en, this message translates to:
  /// **'Spent today'**
  String get dashStatSpentToday;

  /// No description provided for @dashStatTotalSpent.
  ///
  /// In en, this message translates to:
  /// **'Total spent'**
  String get dashStatTotalSpent;

  /// No description provided for @dashStatAveragePerDay.
  ///
  /// In en, this message translates to:
  /// **'Average / day'**
  String get dashStatAveragePerDay;

  /// No description provided for @dashRecentActivity.
  ///
  /// In en, this message translates to:
  /// **'Recent activity'**
  String get dashRecentActivity;

  /// No description provided for @dashNoEntries.
  ///
  /// In en, this message translates to:
  /// **'No entries yet. Add one with the + button.'**
  String get dashNoEntries;

  /// No description provided for @budgetingWindow.
  ///
  /// In en, this message translates to:
  /// **'Budgeting window'**
  String get budgetingWindow;

  /// No description provided for @fieldStart.
  ///
  /// In en, this message translates to:
  /// **'Start'**
  String get fieldStart;

  /// No description provided for @fieldEnd.
  ///
  /// In en, this message translates to:
  /// **'End'**
  String get fieldEnd;

  /// No description provided for @dailyBudget.
  ///
  /// In en, this message translates to:
  /// **'Daily budget'**
  String get dailyBudget;

  /// No description provided for @overDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{over {count} day} other{over {count} days}}'**
  String overDays(int count);

  /// No description provided for @smartCardsTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart cards'**
  String get smartCardsTitle;

  /// No description provided for @smartCardsWatching.
  ///
  /// In en, this message translates to:
  /// **'Smart cards are on watch. Discretionary spending is comfortable today.'**
  String get smartCardsWatching;

  /// No description provided for @smartCardsSpent.
  ///
  /// In en, this message translates to:
  /// **'You have spent {amount} on small extras today — {percent}% of your daily limit.'**
  String smartCardsSpent(String amount, int percent);

  /// No description provided for @smartCardsAnnualised.
  ///
  /// In en, this message translates to:
  /// **'At this rate that is {amount} a year.'**
  String smartCardsAnnualised(String amount);

  /// No description provided for @smartCardsDivert.
  ///
  /// In en, this message translates to:
  /// **'Diverting it to \"{goal}\" would get you there sooner.'**
  String smartCardsDivert(String goal);

  /// No description provided for @spendingPatternTitle.
  ///
  /// In en, this message translates to:
  /// **'Spending pattern'**
  String get spendingPatternTitle;

  /// Detected weekday cluster for evening spending. The plural wrapper exists so Russian can decline the count.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Your spontaneous spending clusters around {weekday} nights — mostly {tag} purchases ({count} so far).} other{Your spontaneous spending clusters around {weekday} nights — mostly {tag} purchases ({count} so far).}}'**
  String spendingPatternNight(String weekday, String tag, int count);

  /// No description provided for @spendingPatternDay.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Your spontaneous spending clusters around {weekday} daytimes — mostly {tag} purchases ({count} so far).} other{Your spontaneous spending clusters around {weekday} daytimes — mostly {tag} purchases ({count} so far).}}'**
  String spendingPatternDay(String weekday, String tag, int count);

  /// No description provided for @weekdayMonday.
  ///
  /// In en, this message translates to:
  /// **'Monday'**
  String get weekdayMonday;

  /// No description provided for @weekdayTuesday.
  ///
  /// In en, this message translates to:
  /// **'Tuesday'**
  String get weekdayTuesday;

  /// No description provided for @weekdayWednesday.
  ///
  /// In en, this message translates to:
  /// **'Wednesday'**
  String get weekdayWednesday;

  /// No description provided for @weekdayThursday.
  ///
  /// In en, this message translates to:
  /// **'Thursday'**
  String get weekdayThursday;

  /// No description provided for @weekdayFriday.
  ///
  /// In en, this message translates to:
  /// **'Friday'**
  String get weekdayFriday;

  /// No description provided for @weekdaySaturday.
  ///
  /// In en, this message translates to:
  /// **'Saturday'**
  String get weekdaySaturday;

  /// No description provided for @weekdaySunday.
  ///
  /// In en, this message translates to:
  /// **'Sunday'**
  String get weekdaySunday;

  /// No description provided for @smartSuggestionsTitle.
  ///
  /// In en, this message translates to:
  /// **'Smart suggestions'**
  String get smartSuggestionsTitle;

  /// No description provided for @suggestionWatchCategoryTitle.
  ///
  /// In en, this message translates to:
  /// **'Watch {category}'**
  String suggestionWatchCategoryTitle(String category);

  /// No description provided for @suggestionWatchCategoryBody.
  ///
  /// In en, this message translates to:
  /// **'It is your largest category this month. Trimming 10% would free about {amount}.'**
  String suggestionWatchCategoryBody(String amount);

  /// No description provided for @suggestionBudgetAlertTitle.
  ///
  /// In en, this message translates to:
  /// **'{category} budget alert'**
  String suggestionBudgetAlertTitle(String category);

  /// No description provided for @suggestionBudgetAlertBody.
  ///
  /// In en, this message translates to:
  /// **'You have used {percent}% of this month\'s limit.'**
  String suggestionBudgetAlertBody(int percent);

  /// No description provided for @suggestionAuditSubsTitle.
  ///
  /// In en, this message translates to:
  /// **'Audit your subscriptions'**
  String get suggestionAuditSubsTitle;

  /// No description provided for @suggestionAuditSubsBody.
  ///
  /// In en, this message translates to:
  /// **'Recurring charges detected: {names}.'**
  String suggestionAuditSubsBody(String names);

  /// No description provided for @suggestionTrackTitle.
  ///
  /// In en, this message translates to:
  /// **'Track for 7 days'**
  String get suggestionTrackTitle;

  /// No description provided for @suggestionTrackBody.
  ///
  /// In en, this message translates to:
  /// **'Add a week of entries and personalised suggestions will appear here.'**
  String get suggestionTrackBody;

  /// No description provided for @recurringChargesTitle.
  ///
  /// In en, this message translates to:
  /// **'Recurring charges'**
  String get recurringChargesTitle;

  /// No description provided for @recurringChargesSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Detected from a monthly cadence in your history.'**
  String get recurringChargesSubtitle;

  /// No description provided for @recurringChargesEmpty.
  ///
  /// In en, this message translates to:
  /// **'Nothing detected yet. Recurring charges appear after a couple of monthly repeats.'**
  String get recurringChargesEmpty;

  /// No description provided for @subscriptionCharges.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} charge · last {date}} few{{count} charges · last {date}} many{{count} charges · last {date}} other{{count} charges · last {date}}}'**
  String subscriptionCharges(int count, String date);

  /// No description provided for @perYear.
  ///
  /// In en, this message translates to:
  /// **'{amount}/yr'**
  String perYear(String amount);

  /// No description provided for @financialCalendarTitle.
  ///
  /// In en, this message translates to:
  /// **'Financial calendar'**
  String get financialCalendarTitle;

  /// No description provided for @financialCalendarSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Events that can change your spending velocity.'**
  String get financialCalendarSubtitle;

  /// No description provided for @regionIndia.
  ///
  /// In en, this message translates to:
  /// **'India'**
  String get regionIndia;

  /// No description provided for @regionRussia.
  ///
  /// In en, this message translates to:
  /// **'Russia'**
  String get regionRussia;

  /// No description provided for @eventComingSoon.
  ///
  /// In en, this message translates to:
  /// **'{name} is coming soon'**
  String eventComingSoon(String name);

  /// No description provided for @eventForecast.
  ///
  /// In en, this message translates to:
  /// **'Spending usually rises during this window. Projected {projected} per active day — about {increase} above your usual.'**
  String eventForecast(String projected, String increase);

  /// No description provided for @eventNoHistory.
  ///
  /// In en, this message translates to:
  /// **'Estimated from your overall average — no history for this window yet.'**
  String get eventNoHistory;

  /// No description provided for @eventToday.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get eventToday;

  /// No description provided for @eventDaysShort.
  ///
  /// In en, this message translates to:
  /// **'{count}d'**
  String eventDaysShort(int count);

  /// No description provided for @eventWinterExamName.
  ///
  /// In en, this message translates to:
  /// **'Winter exam season'**
  String get eventWinterExamName;

  /// No description provided for @eventWinterExamNote.
  ///
  /// In en, this message translates to:
  /// **'Study materials, transport, and late-night food often rise.'**
  String get eventWinterExamNote;

  /// No description provided for @eventNewYearName.
  ///
  /// In en, this message translates to:
  /// **'New Year holidays'**
  String get eventNewYearName;

  /// No description provided for @eventNewYearNote.
  ///
  /// In en, this message translates to:
  /// **'Gifting, travel, and social spending cluster around this break.'**
  String get eventNewYearNote;

  /// No description provided for @eventStipendName.
  ///
  /// In en, this message translates to:
  /// **'Student stipend cycle'**
  String get eventStipendName;

  /// No description provided for @eventStipendNote.
  ///
  /// In en, this message translates to:
  /// **'A regular stipend date to anchor your monthly plan.'**
  String get eventStipendNote;

  /// No description provided for @eventUniExamName.
  ///
  /// In en, this message translates to:
  /// **'University exam window'**
  String get eventUniExamName;

  /// No description provided for @eventUniExamNote.
  ///
  /// In en, this message translates to:
  /// **'Printing, travel, and convenience food can increase during exam weeks.'**
  String get eventUniExamNote;

  /// No description provided for @eventDiwaliName.
  ///
  /// In en, this message translates to:
  /// **'Diwali cluster'**
  String get eventDiwaliName;

  /// No description provided for @eventDiwaliNote.
  ///
  /// In en, this message translates to:
  /// **'Gifts, travel, and celebrations can put pressure on flexible cash.'**
  String get eventDiwaliNote;

  /// No description provided for @eventSemesterName.
  ///
  /// In en, this message translates to:
  /// **'Semester reset'**
  String get eventSemesterName;

  /// No description provided for @eventSemesterNote.
  ///
  /// In en, this message translates to:
  /// **'Books, supplies, and housing deposits often return at the start of term.'**
  String get eventSemesterNote;

  /// No description provided for @eventTypeAcademic.
  ///
  /// In en, this message translates to:
  /// **'Academic'**
  String get eventTypeAcademic;

  /// No description provided for @eventTypeHoliday.
  ///
  /// In en, this message translates to:
  /// **'Holiday'**
  String get eventTypeHoliday;

  /// No description provided for @eventTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get eventTypeIncome;

  /// No description provided for @eventTypeFestival.
  ///
  /// In en, this message translates to:
  /// **'Festival'**
  String get eventTypeFestival;

  /// No description provided for @eventTypeStudentCosts.
  ///
  /// In en, this message translates to:
  /// **'Student costs'**
  String get eventTypeStudentCosts;

  /// No description provided for @locationGuidanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Location guidance'**
  String get locationGuidanceTitle;

  /// No description provided for @locationGuidanceSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Typical local costs against what is left for today.'**
  String get locationGuidanceSubtitle;

  /// No description provided for @fieldRegion.
  ///
  /// In en, this message translates to:
  /// **'Region'**
  String get fieldRegion;

  /// No description provided for @geoUsCity.
  ///
  /// In en, this message translates to:
  /// **'US City'**
  String get geoUsCity;

  /// No description provided for @geoIndiaMetro.
  ///
  /// In en, this message translates to:
  /// **'India Metro'**
  String get geoIndiaMetro;

  /// No description provided for @geoEasternEurope.
  ///
  /// In en, this message translates to:
  /// **'Eastern Europe'**
  String get geoEasternEurope;

  /// No description provided for @stapleLunch.
  ///
  /// In en, this message translates to:
  /// **'Lunch'**
  String get stapleLunch;

  /// No description provided for @stapleTransit.
  ///
  /// In en, this message translates to:
  /// **'Transit'**
  String get stapleTransit;

  /// No description provided for @stapleGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get stapleGroceries;

  /// No description provided for @stapleCost.
  ///
  /// In en, this message translates to:
  /// **'Typical {cost} · suggested max {limit}'**
  String stapleCost(String cost, String limit);

  /// No description provided for @badgeOnBudget.
  ///
  /// In en, this message translates to:
  /// **'On Budget'**
  String get badgeOnBudget;

  /// No description provided for @badgeTrimNeeded.
  ///
  /// In en, this message translates to:
  /// **'Trim Needed'**
  String get badgeTrimNeeded;

  /// No description provided for @suggestionsTodayTitle.
  ///
  /// In en, this message translates to:
  /// **'Suggestions for today'**
  String get suggestionsTodayTitle;

  /// No description provided for @tipOverBudget.
  ///
  /// In en, this message translates to:
  /// **'You are over today\'s budget. Switch to essential-only purchases for the rest of the day.'**
  String get tipOverBudget;

  /// No description provided for @tipFinalQuarter.
  ///
  /// In en, this message translates to:
  /// **'You are in the final 25% of your daily budget. Keep only high-priority plan items.'**
  String get tipFinalQuarter;

  /// No description provided for @tipComfortable.
  ///
  /// In en, this message translates to:
  /// **'You still have comfortable room today. Front-load essentials and delay impulse categories.'**
  String get tipComfortable;

  /// No description provided for @tipPlannedOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Your planned spend is above budget. Reduce one plan item by around 20-30%.'**
  String get tipPlannedOverBudget;

  /// No description provided for @tipAverageOverBudget.
  ///
  /// In en, this message translates to:
  /// **'Your average daily spend is above your location-adjusted budget. Try a three-day low-spend streak.'**
  String get tipAverageOverBudget;

  /// No description provided for @tipCategoryCaps.
  ///
  /// In en, this message translates to:
  /// **'Use category caps for Food and Shopping today to protect tomorrow\'s flexibility.'**
  String get tipCategoryCaps;

  /// No description provided for @dailyPlanTitle.
  ///
  /// In en, this message translates to:
  /// **'Daily plan builder'**
  String get dailyPlanTitle;

  /// No description provided for @dailyPlanSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Plan a day, then compare it against your daily budget.'**
  String get dailyPlanSubtitle;

  /// No description provided for @dailyPlanName.
  ///
  /// In en, this message translates to:
  /// **'Plan name'**
  String get dailyPlanName;

  /// No description provided for @dailyPlanNameHint.
  ///
  /// In en, this message translates to:
  /// **'Groceries and transit'**
  String get dailyPlanNameHint;

  /// No description provided for @dailyPlanEstimate.
  ///
  /// In en, this message translates to:
  /// **'Estimate ({code})'**
  String dailyPlanEstimate(String code);

  /// No description provided for @dailyPlanDate.
  ///
  /// In en, this message translates to:
  /// **'Plan date'**
  String get dailyPlanDate;

  /// No description provided for @dailyPlanAdd.
  ///
  /// In en, this message translates to:
  /// **'Add plan'**
  String get dailyPlanAdd;

  /// No description provided for @dailyPlanInvalid.
  ///
  /// In en, this message translates to:
  /// **'Add a plan name and a valid amount.'**
  String get dailyPlanInvalid;

  /// No description provided for @dailyPlanSpentThatDay.
  ///
  /// In en, this message translates to:
  /// **'Spent that day'**
  String get dailyPlanSpentThatDay;

  /// No description provided for @dailyPlanPlanned.
  ///
  /// In en, this message translates to:
  /// **'Planned'**
  String get dailyPlanPlanned;

  /// No description provided for @dailyPlanRemaining.
  ///
  /// In en, this message translates to:
  /// **'Remaining after plans'**
  String get dailyPlanRemaining;

  /// No description provided for @dailyPlanEmpty.
  ///
  /// In en, this message translates to:
  /// **'No plans for this day yet.'**
  String get dailyPlanEmpty;

  /// No description provided for @dailyPlanDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete plan'**
  String get dailyPlanDeleteTooltip;

  /// No description provided for @dayRecordsTitle.
  ///
  /// In en, this message translates to:
  /// **'All day records'**
  String get dayRecordsTitle;

  /// No description provided for @dayRecordsEmpty.
  ///
  /// In en, this message translates to:
  /// **'No records yet. Add entries to start building history.'**
  String get dayRecordsEmpty;

  /// No description provided for @goalsEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'No savings goals yet.'**
  String get goalsEmptyTitle;

  /// No description provided for @goalsEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Use the + button to create one.'**
  String get goalsEmptyBody;

  /// No description provided for @goalsGuidanceTitle.
  ///
  /// In en, this message translates to:
  /// **'Personalised guidance'**
  String get goalsGuidanceTitle;

  /// No description provided for @goalAmountOf.
  ///
  /// In en, this message translates to:
  /// **'{current} of {target}'**
  String goalAmountOf(String current, String target);

  /// No description provided for @goalAddAmount.
  ///
  /// In en, this message translates to:
  /// **'Add {amount}'**
  String goalAddAmount(String amount);

  /// No description provided for @goalInsightEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add a few expenses and personalised guidance will appear here.'**
  String get goalInsightEmpty;

  /// No description provided for @goalInsightTopShare.
  ///
  /// In en, this message translates to:
  /// **'{category} is {percent}% of your spending. A 10% trim there moves your goals faster than cutting anywhere else.'**
  String goalInsightTopShare(String category, int percent);

  /// No description provided for @goalInsightTopTwo.
  ///
  /// In en, this message translates to:
  /// **'Together, {first} and {second} account for {percent}% of outgoings.'**
  String goalInsightTopTwo(String first, String second, int percent);

  /// No description provided for @goalInsightAutomate.
  ///
  /// In en, this message translates to:
  /// **'Automating a transfer on the day you get paid protects savings before spending starts.'**
  String get goalInsightAutomate;

  /// No description provided for @goalInsightReviewWeekly.
  ///
  /// In en, this message translates to:
  /// **'Reviewing one category a week is more sustainable than cutting everything at once.'**
  String get goalInsightReviewWeekly;

  /// No description provided for @chartTopCategories.
  ///
  /// In en, this message translates to:
  /// **'Top categories'**
  String get chartTopCategories;

  /// No description provided for @chartNoExpenses.
  ///
  /// In en, this message translates to:
  /// **'No expenses yet.'**
  String get chartNoExpenses;

  /// No description provided for @chartIncomeVsExpenses.
  ///
  /// In en, this message translates to:
  /// **'Income vs expenses'**
  String get chartIncomeVsExpenses;

  /// No description provided for @chartLastSixMonths.
  ///
  /// In en, this message translates to:
  /// **'Last six months'**
  String get chartLastSixMonths;

  /// No description provided for @chartNotEnoughHistory.
  ///
  /// In en, this message translates to:
  /// **'Not enough history yet.'**
  String get chartNotEnoughHistory;

  /// No description provided for @chartLegendIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get chartLegendIncome;

  /// No description provided for @chartLegendExpenses.
  ///
  /// In en, this message translates to:
  /// **'Expenses'**
  String get chartLegendExpenses;

  /// No description provided for @monthJan.
  ///
  /// In en, this message translates to:
  /// **'Jan'**
  String get monthJan;

  /// No description provided for @monthFeb.
  ///
  /// In en, this message translates to:
  /// **'Feb'**
  String get monthFeb;

  /// No description provided for @monthMar.
  ///
  /// In en, this message translates to:
  /// **'Mar'**
  String get monthMar;

  /// No description provided for @monthApr.
  ///
  /// In en, this message translates to:
  /// **'Apr'**
  String get monthApr;

  /// No description provided for @monthMay.
  ///
  /// In en, this message translates to:
  /// **'May'**
  String get monthMay;

  /// No description provided for @monthJun.
  ///
  /// In en, this message translates to:
  /// **'Jun'**
  String get monthJun;

  /// No description provided for @monthJul.
  ///
  /// In en, this message translates to:
  /// **'Jul'**
  String get monthJul;

  /// No description provided for @monthAug.
  ///
  /// In en, this message translates to:
  /// **'Aug'**
  String get monthAug;

  /// No description provided for @monthSep.
  ///
  /// In en, this message translates to:
  /// **'Sep'**
  String get monthSep;

  /// No description provided for @monthOct.
  ///
  /// In en, this message translates to:
  /// **'Oct'**
  String get monthOct;

  /// No description provided for @monthNov.
  ///
  /// In en, this message translates to:
  /// **'Nov'**
  String get monthNov;

  /// No description provided for @monthDec.
  ///
  /// In en, this message translates to:
  /// **'Dec'**
  String get monthDec;

  /// No description provided for @entrySheetTitleAdd.
  ///
  /// In en, this message translates to:
  /// **'Add Entry'**
  String get entrySheetTitleAdd;

  /// No description provided for @entrySheetTitleCheck.
  ///
  /// In en, this message translates to:
  /// **'Check Receipt'**
  String get entrySheetTitleCheck;

  /// No description provided for @entrySheetSubtitleAdd.
  ///
  /// In en, this message translates to:
  /// **'Log an expense or income. Mark recurring charges to track them.'**
  String get entrySheetSubtitleAdd;

  /// No description provided for @entrySheetSubtitleCheck.
  ///
  /// In en, this message translates to:
  /// **'Read from your receipt. Anything marked \"please check\" was a guess — correct it before saving.'**
  String get entrySheetSubtitleCheck;

  /// No description provided for @entrySheetSubmit.
  ///
  /// In en, this message translates to:
  /// **'Save Entry'**
  String get entrySheetSubmit;

  /// No description provided for @entryRecurringHint.
  ///
  /// In en, this message translates to:
  /// **'This looks like a recurring charge. Set to monthly — change it below if that is wrong.'**
  String get entryRecurringHint;

  /// No description provided for @entryTypeExpense.
  ///
  /// In en, this message translates to:
  /// **'Expense'**
  String get entryTypeExpense;

  /// No description provided for @entryTypeIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get entryTypeIncome;

  /// No description provided for @entryFieldName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get entryFieldName;

  /// No description provided for @entryFieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Grocery run'**
  String get entryFieldNameHint;

  /// No description provided for @entryFieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount ({code})'**
  String entryFieldAmount(String code);

  /// No description provided for @entryFieldCategory.
  ///
  /// In en, this message translates to:
  /// **'Category'**
  String get entryFieldCategory;

  /// No description provided for @entryFieldDate.
  ///
  /// In en, this message translates to:
  /// **'Date'**
  String get entryFieldDate;

  /// No description provided for @entryFieldNote.
  ///
  /// In en, this message translates to:
  /// **'Note'**
  String get entryFieldNote;

  /// No description provided for @entryFieldNoteHint.
  ///
  /// In en, this message translates to:
  /// **'Any details about this entry'**
  String get entryFieldNoteHint;

  /// No description provided for @entryRecurringQuestion.
  ///
  /// In en, this message translates to:
  /// **'Is this recurring?'**
  String get entryRecurringQuestion;

  /// No description provided for @entryUnplanned.
  ///
  /// In en, this message translates to:
  /// **'Unplanned / spontaneous'**
  String get entryUnplanned;

  /// No description provided for @entryUnplannedSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Optional context to make insights more useful, never judgmental.'**
  String get entryUnplannedSubtitle;

  /// No description provided for @entryReasonPrompt.
  ///
  /// In en, this message translates to:
  /// **'What influenced this? Optional'**
  String get entryReasonPrompt;

  /// No description provided for @entryInvalid.
  ///
  /// In en, this message translates to:
  /// **'Please provide a name and a valid amount.'**
  String get entryInvalid;

  /// No description provided for @entrySaved.
  ///
  /// In en, this message translates to:
  /// **'Entry saved.'**
  String get entrySaved;

  /// No description provided for @entrySavedRecurring.
  ///
  /// In en, this message translates to:
  /// **'Recurring {cadence} entry added.'**
  String entrySavedRecurring(String cadence);

  /// No description provided for @entryConvertedFrom.
  ///
  /// In en, this message translates to:
  /// **'{amount} {code} converted to {target}'**
  String entryConvertedFrom(String amount, String code, String target);

  /// No description provided for @entryNoRate.
  ///
  /// In en, this message translates to:
  /// **'Receipt is in {code} — no exchange rate available, so this is unconverted'**
  String entryNoRate(String code);

  /// No description provided for @recurrenceNone.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get recurrenceNone;

  /// No description provided for @recurrenceDaily.
  ///
  /// In en, this message translates to:
  /// **'Daily'**
  String get recurrenceDaily;

  /// No description provided for @recurrenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get recurrenceWeekly;

  /// No description provided for @recurrenceBiweekly.
  ///
  /// In en, this message translates to:
  /// **'Biweekly'**
  String get recurrenceBiweekly;

  /// No description provided for @recurrenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get recurrenceMonthly;

  /// No description provided for @recurrenceYearly.
  ///
  /// In en, this message translates to:
  /// **'Yearly'**
  String get recurrenceYearly;

  /// No description provided for @reasonEmotional.
  ///
  /// In en, this message translates to:
  /// **'Emotional purchase'**
  String get reasonEmotional;

  /// No description provided for @reasonSocial.
  ///
  /// In en, this message translates to:
  /// **'Social'**
  String get reasonSocial;

  /// No description provided for @reasonDiscount.
  ///
  /// In en, this message translates to:
  /// **'Discount / sale'**
  String get reasonDiscount;

  /// No description provided for @reasonImpulse.
  ///
  /// In en, this message translates to:
  /// **'Impulse'**
  String get reasonImpulse;

  /// Adjective form used inside the spending-pattern sentence, e.g. "mostly emotional purchases".
  ///
  /// In en, this message translates to:
  /// **'emotional'**
  String get reasonAdjEmotional;

  /// No description provided for @reasonAdjSocial.
  ///
  /// In en, this message translates to:
  /// **'social'**
  String get reasonAdjSocial;

  /// No description provided for @reasonAdjDiscount.
  ///
  /// In en, this message translates to:
  /// **'discount'**
  String get reasonAdjDiscount;

  /// No description provided for @reasonAdjImpulse.
  ///
  /// In en, this message translates to:
  /// **'impulse'**
  String get reasonAdjImpulse;

  /// No description provided for @categoryIncome.
  ///
  /// In en, this message translates to:
  /// **'Income'**
  String get categoryIncome;

  /// No description provided for @categorySalary.
  ///
  /// In en, this message translates to:
  /// **'Salary'**
  String get categorySalary;

  /// No description provided for @categoryFreelance.
  ///
  /// In en, this message translates to:
  /// **'Freelance'**
  String get categoryFreelance;

  /// No description provided for @categoryGroceries.
  ///
  /// In en, this message translates to:
  /// **'Groceries'**
  String get categoryGroceries;

  /// No description provided for @categoryTransport.
  ///
  /// In en, this message translates to:
  /// **'Transport'**
  String get categoryTransport;

  /// No description provided for @categoryHousing.
  ///
  /// In en, this message translates to:
  /// **'Housing'**
  String get categoryHousing;

  /// No description provided for @categoryUtilities.
  ///
  /// In en, this message translates to:
  /// **'Utilities'**
  String get categoryUtilities;

  /// No description provided for @categoryEntertainment.
  ///
  /// In en, this message translates to:
  /// **'Entertainment'**
  String get categoryEntertainment;

  /// No description provided for @categoryFood.
  ///
  /// In en, this message translates to:
  /// **'Food'**
  String get categoryFood;

  /// No description provided for @categoryShopping.
  ///
  /// In en, this message translates to:
  /// **'Shopping'**
  String get categoryShopping;

  /// No description provided for @categoryHealth.
  ///
  /// In en, this message translates to:
  /// **'Health'**
  String get categoryHealth;

  /// No description provided for @categoryTravel.
  ///
  /// In en, this message translates to:
  /// **'Travel'**
  String get categoryTravel;

  /// No description provided for @categoryEducation.
  ///
  /// In en, this message translates to:
  /// **'Education'**
  String get categoryEducation;

  /// No description provided for @categorySavings.
  ///
  /// In en, this message translates to:
  /// **'Savings'**
  String get categorySavings;

  /// No description provided for @categoryInvestment.
  ///
  /// In en, this message translates to:
  /// **'Investment'**
  String get categoryInvestment;

  /// No description provided for @categoryBusiness.
  ///
  /// In en, this message translates to:
  /// **'Business'**
  String get categoryBusiness;

  /// No description provided for @categoryGift.
  ///
  /// In en, this message translates to:
  /// **'Gift'**
  String get categoryGift;

  /// No description provided for @categoryOther.
  ///
  /// In en, this message translates to:
  /// **'Other'**
  String get categoryOther;

  /// No description provided for @goalSheetTitle.
  ///
  /// In en, this message translates to:
  /// **'Set Savings Goal'**
  String get goalSheetTitle;

  /// No description provided for @goalSheetSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Define how much to save and by when. We\'ll show you the daily target.'**
  String get goalSheetSubtitle;

  /// No description provided for @goalSheetSubmit.
  ///
  /// In en, this message translates to:
  /// **'Create Goal'**
  String get goalSheetSubmit;

  /// No description provided for @goalFieldIcon.
  ///
  /// In en, this message translates to:
  /// **'Icon'**
  String get goalFieldIcon;

  /// No description provided for @goalFieldName.
  ///
  /// In en, this message translates to:
  /// **'Goal name'**
  String get goalFieldName;

  /// No description provided for @goalFieldNameHint.
  ///
  /// In en, this message translates to:
  /// **'Emergency fund'**
  String get goalFieldNameHint;

  /// No description provided for @goalFieldTarget.
  ///
  /// In en, this message translates to:
  /// **'Target ({code})'**
  String goalFieldTarget(String code);

  /// No description provided for @goalFieldSaved.
  ///
  /// In en, this message translates to:
  /// **'Already saved'**
  String get goalFieldSaved;

  /// No description provided for @goalTimeframe.
  ///
  /// In en, this message translates to:
  /// **'Timeframe'**
  String get goalTimeframe;

  /// No description provided for @goalFieldDays.
  ///
  /// In en, this message translates to:
  /// **'Days'**
  String get goalFieldDays;

  /// No description provided for @goalMinimumDays.
  ///
  /// In en, this message translates to:
  /// **'minimum 7'**
  String get goalMinimumDays;

  /// No description provided for @goalInvalid.
  ///
  /// In en, this message translates to:
  /// **'Add a goal name and target amount.'**
  String get goalInvalid;

  /// No description provided for @goalCreated.
  ///
  /// In en, this message translates to:
  /// **'Goal created.'**
  String get goalCreated;

  /// No description provided for @goalReachIn.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{To reach your goal in {count} day:} few{To reach your goal in {count} days:} many{To reach your goal in {count} days:} other{To reach your goal in {count} days:}}'**
  String goalReachIn(int count);

  /// No description provided for @goalPerDay.
  ///
  /// In en, this message translates to:
  /// **'{amount} / day'**
  String goalPerDay(String amount);

  /// No description provided for @goalPerWeekMonth.
  ///
  /// In en, this message translates to:
  /// **'{week} / week · {month} / month'**
  String goalPerWeekMonth(String week, String month);

  /// No description provided for @goalCurrentGoals.
  ///
  /// In en, this message translates to:
  /// **'Current goals'**
  String get goalCurrentGoals;

  /// No description provided for @periodOneMonth.
  ///
  /// In en, this message translates to:
  /// **'1 Month'**
  String get periodOneMonth;

  /// No description provided for @periodThreeMonths.
  ///
  /// In en, this message translates to:
  /// **'3 Months'**
  String get periodThreeMonths;

  /// No description provided for @periodSixMonths.
  ///
  /// In en, this message translates to:
  /// **'6 Months'**
  String get periodSixMonths;

  /// No description provided for @periodOneYear.
  ///
  /// In en, this message translates to:
  /// **'1 Year'**
  String get periodOneYear;

  /// No description provided for @periodTwoYears.
  ///
  /// In en, this message translates to:
  /// **'2 Years'**
  String get periodTwoYears;

  /// No description provided for @periodCustom.
  ///
  /// In en, this message translates to:
  /// **'Custom'**
  String get periodCustom;

  /// No description provided for @plannerSurvivalTitle.
  ///
  /// In en, this message translates to:
  /// **'Survival calculator'**
  String get plannerSurvivalTitle;

  /// No description provided for @plannerSurvivalSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Your daily spendable cash after essentials.'**
  String get plannerSurvivalSubtitle;

  /// No description provided for @plannerDailySpendable.
  ///
  /// In en, this message translates to:
  /// **'Daily spendable'**
  String get plannerDailySpendable;

  /// No description provided for @plannerHorizon.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{Planning horizon — {count} day} few{Planning horizon — {count} days} many{Planning horizon — {count} days} other{Planning horizon — {count} days}}'**
  String plannerHorizon(int count);

  /// No description provided for @plannerUpcomingBills.
  ///
  /// In en, this message translates to:
  /// **'Upcoming must-pay bills ({code})'**
  String plannerUpcomingBills(String code);

  /// No description provided for @plannerIncomeStreams.
  ///
  /// In en, this message translates to:
  /// **'Income streams'**
  String get plannerIncomeStreams;

  /// No description provided for @plannerFieldSource.
  ///
  /// In en, this message translates to:
  /// **'Source'**
  String get plannerFieldSource;

  /// No description provided for @plannerFieldAmount.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get plannerFieldAmount;

  /// No description provided for @plannerFixedCosts.
  ///
  /// In en, this message translates to:
  /// **'Fixed costs'**
  String get plannerFixedCosts;

  /// No description provided for @plannerFieldBill.
  ///
  /// In en, this message translates to:
  /// **'Bill'**
  String get plannerFieldBill;

  /// No description provided for @plannerAddFixedCost.
  ///
  /// In en, this message translates to:
  /// **'Add fixed cost'**
  String get plannerAddFixedCost;

  /// No description provided for @zoneGreen.
  ///
  /// In en, this message translates to:
  /// **'Green Zone'**
  String get zoneGreen;

  /// No description provided for @zoneTight.
  ///
  /// In en, this message translates to:
  /// **'Tight Zone'**
  String get zoneTight;

  /// No description provided for @zoneCritical.
  ///
  /// In en, this message translates to:
  /// **'Critical Zone'**
  String get zoneCritical;

  /// No description provided for @cadenceOneTime.
  ///
  /// In en, this message translates to:
  /// **'One-time'**
  String get cadenceOneTime;

  /// No description provided for @cadenceWeekly.
  ///
  /// In en, this message translates to:
  /// **'Weekly'**
  String get cadenceWeekly;

  /// No description provided for @cadenceMonthly.
  ///
  /// In en, this message translates to:
  /// **'Monthly'**
  String get cadenceMonthly;

  /// No description provided for @plannerSocialTitle.
  ///
  /// In en, this message translates to:
  /// **'Social budgeting'**
  String get plannerSocialTitle;

  /// No description provided for @plannerSocialSubtitle.
  ///
  /// In en, this message translates to:
  /// **'See the impact of nights out before you commit.'**
  String get plannerSocialSubtitle;

  /// No description provided for @plannerFieldEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get plannerFieldEvent;

  /// No description provided for @plannerFieldLow.
  ///
  /// In en, this message translates to:
  /// **'Low'**
  String get plannerFieldLow;

  /// No description provided for @plannerFieldRealistic.
  ///
  /// In en, this message translates to:
  /// **'Realistic'**
  String get plannerFieldRealistic;

  /// No description provided for @plannerFieldStretch.
  ///
  /// In en, this message translates to:
  /// **'Stretch'**
  String get plannerFieldStretch;

  /// No description provided for @plannerAddPlan.
  ///
  /// In en, this message translates to:
  /// **'Add plan'**
  String get plannerAddPlan;

  /// No description provided for @plannerSocialImpact.
  ///
  /// In en, this message translates to:
  /// **'If every realistic plan happens, your daily spendable becomes {amount}.'**
  String plannerSocialImpact(String amount);

  /// No description provided for @plannerYourShare.
  ///
  /// In en, this message translates to:
  /// **'{date} · your share {amount}'**
  String plannerYourShare(String date, String amount);

  /// No description provided for @plannerYourShareSplit.
  ///
  /// In en, this message translates to:
  /// **'{date} · your share {amount} of {count}'**
  String plannerYourShareSplit(String date, String amount, int count);

  /// No description provided for @plannerRange.
  ///
  /// In en, this message translates to:
  /// **'Range {low} – {high}'**
  String plannerRange(String low, String high);

  /// No description provided for @plannerRunwayTitle.
  ///
  /// In en, this message translates to:
  /// **'Loan runway'**
  String get plannerRunwayTitle;

  /// No description provided for @plannerRunwaySubtitle.
  ///
  /// In en, this message translates to:
  /// **'Make a lump sum last the whole semester.'**
  String get plannerRunwaySubtitle;

  /// No description provided for @plannerLumpSum.
  ///
  /// In en, this message translates to:
  /// **'Lump sum'**
  String get plannerLumpSum;

  /// No description provided for @plannerSafetyBuffer.
  ///
  /// In en, this message translates to:
  /// **'Safety buffer'**
  String get plannerSafetyBuffer;

  /// No description provided for @plannerRunwayWeeks.
  ///
  /// In en, this message translates to:
  /// **'Remaining runway: {weeks} weeks'**
  String plannerRunwayWeeks(String weeks);

  /// No description provided for @plannerSemesterWeeksLeft.
  ///
  /// In en, this message translates to:
  /// **'{weeks} semester weeks left.'**
  String plannerSemesterWeeksLeft(String weeks);

  /// No description provided for @plannerWillRunOut.
  ///
  /// In en, this message translates to:
  /// **' At this pace the money runs out first.'**
  String get plannerWillRunOut;

  /// No description provided for @plannerWeeklyBurn.
  ///
  /// In en, this message translates to:
  /// **'Weekly burn'**
  String get plannerWeeklyBurn;

  /// No description provided for @plannerSuggestedCap.
  ///
  /// In en, this message translates to:
  /// **'Suggested cap'**
  String get plannerSuggestedCap;

  /// No description provided for @plannerStreakTitle.
  ///
  /// In en, this message translates to:
  /// **'Bloom streaks'**
  String get plannerStreakTitle;

  /// No description provided for @plannerStreakSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Stay within your plan three days running to earn a badge.'**
  String get plannerStreakSubtitle;

  /// No description provided for @plannerCurrentStreak.
  ///
  /// In en, this message translates to:
  /// **'Current streak'**
  String get plannerCurrentStreak;

  /// No description provided for @plannerStreakDays.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{count} day} few{{count} days} many{{count} days} other{{count} days}}'**
  String plannerStreakDays(int count);

  /// No description provided for @plannerStreakBadge.
  ///
  /// In en, this message translates to:
  /// **'3-day bloom streak'**
  String get plannerStreakBadge;

  /// No description provided for @plannerMarkedOnTrack.
  ///
  /// In en, this message translates to:
  /// **'Marked on track today'**
  String get plannerMarkedOnTrack;

  /// No description provided for @plannerMarkOnTrack.
  ///
  /// In en, this message translates to:
  /// **'Mark today on track'**
  String get plannerMarkOnTrack;

  /// No description provided for @plannerStreakFooter.
  ///
  /// In en, this message translates to:
  /// **'No penalties. Missed days just restart softly.'**
  String get plannerStreakFooter;

  /// No description provided for @budgetPlannerTitle.
  ///
  /// In en, this message translates to:
  /// **'Budget planner'**
  String get budgetPlannerTitle;

  /// No description provided for @budgetDiscardTooltip.
  ///
  /// In en, this message translates to:
  /// **'Discard draft'**
  String get budgetDiscardTooltip;

  /// No description provided for @budgetDiscardDialogTitle.
  ///
  /// In en, this message translates to:
  /// **'Discard this plan?'**
  String get budgetDiscardDialogTitle;

  /// No description provided for @budgetDiscardDialogBody.
  ///
  /// In en, this message translates to:
  /// **'The draft and its items will be deleted.'**
  String get budgetDiscardDialogBody;

  /// No description provided for @budgetTypeTrip.
  ///
  /// In en, this message translates to:
  /// **'Trip'**
  String get budgetTypeTrip;

  /// No description provided for @budgetTypeOuting.
  ///
  /// In en, this message translates to:
  /// **'Outing'**
  String get budgetTypeOuting;

  /// No description provided for @budgetTypeEvent.
  ///
  /// In en, this message translates to:
  /// **'Event'**
  String get budgetTypeEvent;

  /// No description provided for @budgetFieldTitle.
  ///
  /// In en, this message translates to:
  /// **'Plan title'**
  String get budgetFieldTitle;

  /// No description provided for @budgetFieldTitleHint.
  ///
  /// In en, this message translates to:
  /// **'e.g. Goa weekend'**
  String get budgetFieldTitleHint;

  /// No description provided for @budgetFieldFrom.
  ///
  /// In en, this message translates to:
  /// **'From'**
  String get budgetFieldFrom;

  /// No description provided for @budgetFieldTo.
  ///
  /// In en, this message translates to:
  /// **'To (optional)'**
  String get budgetFieldTo;

  /// No description provided for @budgetSplittingBetween.
  ///
  /// In en, this message translates to:
  /// **'Splitting between'**
  String get budgetSplittingBetween;

  /// No description provided for @budgetItems.
  ///
  /// In en, this message translates to:
  /// **'Items'**
  String get budgetItems;

  /// No description provided for @budgetFieldItem.
  ///
  /// In en, this message translates to:
  /// **'Item'**
  String get budgetFieldItem;

  /// No description provided for @budgetFieldCost.
  ///
  /// In en, this message translates to:
  /// **'Cost ({code})'**
  String budgetFieldCost(String code);

  /// No description provided for @budgetAddItemTooltip.
  ///
  /// In en, this message translates to:
  /// **'Add item'**
  String get budgetAddItemTooltip;

  /// No description provided for @budgetItemsEmpty.
  ///
  /// In en, this message translates to:
  /// **'Add items above to see the breakdown.'**
  String get budgetItemsEmpty;

  /// No description provided for @budgetTotal.
  ///
  /// In en, this message translates to:
  /// **'Total'**
  String get budgetTotal;

  /// No description provided for @budgetPerPerson.
  ///
  /// In en, this message translates to:
  /// **'Per person ({count})'**
  String budgetPerPerson(int count);

  /// No description provided for @budgetFinalise.
  ///
  /// In en, this message translates to:
  /// **'Finalise bill'**
  String get budgetFinalise;

  /// No description provided for @budgetFinalised.
  ///
  /// In en, this message translates to:
  /// **'Budget finalised.'**
  String get budgetFinalised;

  /// No description provided for @budgetItemInvalid.
  ///
  /// In en, this message translates to:
  /// **'Add an item name and a cost above zero.'**
  String get budgetItemInvalid;

  /// No description provided for @budgetErrorNothing.
  ///
  /// In en, this message translates to:
  /// **'Nothing to finalise.'**
  String get budgetErrorNothing;

  /// No description provided for @budgetErrorNoTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a plan title before finalising.'**
  String get budgetErrorNoTitle;

  /// No description provided for @budgetErrorNoItems.
  ///
  /// In en, this message translates to:
  /// **'Add at least one item to generate a bill.'**
  String get budgetErrorNoItems;

  /// No description provided for @budgetErrorBadDates.
  ///
  /// In en, this message translates to:
  /// **'End date cannot be before the start date.'**
  String get budgetErrorBadDates;

  /// No description provided for @budgetReceiptsTitle.
  ///
  /// In en, this message translates to:
  /// **'Finalised bills'**
  String get budgetReceiptsTitle;

  /// No description provided for @budgetReceiptSummary.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{type} · {from} · {count} item} few{{type} · {from} · {count} items} many{{type} · {from} · {count} items} other{{type} · {from} · {count} items}}'**
  String budgetReceiptSummary(String type, String from, int count);

  /// No description provided for @budgetReceiptSummaryRange.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{type} · {from} → {to} · {count} item} few{{type} · {from} → {to} · {count} items} many{{type} · {from} → {to} · {count} items} other{{type} · {from} → {to} · {count} items}}'**
  String budgetReceiptSummaryRange(
      String type, String from, String to, int count);

  /// No description provided for @budgetEach.
  ///
  /// In en, this message translates to:
  /// **'{amount} each'**
  String budgetEach(String amount);

  /// No description provided for @budgetDeleteTooltip.
  ///
  /// In en, this message translates to:
  /// **'Delete bill'**
  String get budgetDeleteTooltip;

  /// No description provided for @workspaceEmptyTitle.
  ///
  /// In en, this message translates to:
  /// **'Build your workspace'**
  String get workspaceEmptyTitle;

  /// No description provided for @workspaceEmptyBody.
  ///
  /// In en, this message translates to:
  /// **'Add the cards you want to see at a glance.'**
  String get workspaceEmptyBody;

  /// No description provided for @workspaceAddWidget.
  ///
  /// In en, this message translates to:
  /// **'Add widget'**
  String get workspaceAddWidget;

  /// No description provided for @workspaceAddWidgetTitle.
  ///
  /// In en, this message translates to:
  /// **'Add a widget'**
  String get workspaceAddWidgetTitle;

  /// No description provided for @workspaceTitle.
  ///
  /// In en, this message translates to:
  /// **'Workspace'**
  String get workspaceTitle;

  /// No description provided for @workspaceDragToReorder.
  ///
  /// In en, this message translates to:
  /// **'Drag to reorder'**
  String get workspaceDragToReorder;

  /// No description provided for @workspaceEditLayout.
  ///
  /// In en, this message translates to:
  /// **'Edit layout'**
  String get workspaceEditLayout;

  /// No description provided for @workspaceResize.
  ///
  /// In en, this message translates to:
  /// **'Resize'**
  String get workspaceResize;

  /// No description provided for @workspaceClearTitle.
  ///
  /// In en, this message translates to:
  /// **'Clear workspace?'**
  String get workspaceClearTitle;

  /// No description provided for @workspaceClearBody.
  ///
  /// In en, this message translates to:
  /// **'Every widget is removed, including any images you added.'**
  String get workspaceClearBody;

  /// No description provided for @sizeSmall.
  ///
  /// In en, this message translates to:
  /// **'S'**
  String get sizeSmall;

  /// No description provided for @sizeMedium.
  ///
  /// In en, this message translates to:
  /// **'M'**
  String get sizeMedium;

  /// No description provided for @sizeLarge.
  ///
  /// In en, this message translates to:
  /// **'L'**
  String get sizeLarge;

  /// No description provided for @widgetTodaySnapshot.
  ///
  /// In en, this message translates to:
  /// **'Today Snapshot'**
  String get widgetTodaySnapshot;

  /// No description provided for @widgetBudgetHealth.
  ///
  /// In en, this message translates to:
  /// **'Budget Health'**
  String get widgetBudgetHealth;

  /// No description provided for @widgetTopCategories.
  ///
  /// In en, this message translates to:
  /// **'Top Categories'**
  String get widgetTopCategories;

  /// No description provided for @widgetGoalProgress.
  ///
  /// In en, this message translates to:
  /// **'Goal Progress'**
  String get widgetGoalProgress;

  /// No description provided for @widgetSafeToSpend.
  ///
  /// In en, this message translates to:
  /// **'Safe-to-Spend'**
  String get widgetSafeToSpend;

  /// No description provided for @widgetSubStashJar.
  ///
  /// In en, this message translates to:
  /// **'Sub-Stash Jar'**
  String get widgetSubStashJar;

  /// No description provided for @widgetBurnRateLine.
  ///
  /// In en, this message translates to:
  /// **'Burn-Rate Line'**
  String get widgetBurnRateLine;

  /// No description provided for @widgetQuickEntryPad.
  ///
  /// In en, this message translates to:
  /// **'Quick-Entry Pad'**
  String get widgetQuickEntryPad;

  /// No description provided for @widgetWasteAuditor.
  ///
  /// In en, this message translates to:
  /// **'Waste Auditor'**
  String get widgetWasteAuditor;

  /// No description provided for @widgetRoommateSync.
  ///
  /// In en, this message translates to:
  /// **'Roommate Sync'**
  String get widgetRoommateSync;

  /// No description provided for @widgetMedia.
  ///
  /// In en, this message translates to:
  /// **'Image'**
  String get widgetMedia;

  /// No description provided for @widgetMangaStatus.
  ///
  /// In en, this message translates to:
  /// **'Manga Status'**
  String get widgetMangaStatus;

  /// No description provided for @widgetAsciiFortune.
  ///
  /// In en, this message translates to:
  /// **'ASCII Fortune'**
  String get widgetAsciiFortune;

  /// No description provided for @widgetChibiMascot.
  ///
  /// In en, this message translates to:
  /// **'Chibi Mascot'**
  String get widgetChibiMascot;

  /// No description provided for @widgetGrowthGem.
  ///
  /// In en, this message translates to:
  /// **'Growth Gem'**
  String get widgetGrowthGem;

  /// No description provided for @widgetNoCategoryBudgets.
  ///
  /// In en, this message translates to:
  /// **'No category budgets set yet.'**
  String get widgetNoCategoryBudgets;

  /// No description provided for @widgetNoGoals.
  ///
  /// In en, this message translates to:
  /// **'No goals yet.'**
  String get widgetNoGoals;

  /// No description provided for @widgetSetBalanceFirst.
  ///
  /// In en, this message translates to:
  /// **'Set your balance on the Dashboard to see a daily allowance.'**
  String get widgetSetBalanceFirst;

  /// No description provided for @widgetSafeToSpendLabel.
  ///
  /// In en, this message translates to:
  /// **'Safe to spend'**
  String get widgetSafeToSpendLabel;

  /// No description provided for @widgetSubStash.
  ///
  /// In en, this message translates to:
  /// **'Sub-stash'**
  String get widgetSubStash;

  /// No description provided for @widgetBoostsGoal.
  ///
  /// In en, this message translates to:
  /// **'Boosts \"{goal}\"'**
  String widgetBoostsGoal(String goal);

  /// No description provided for @widgetBoostAmount.
  ///
  /// In en, this message translates to:
  /// **'Boost {amount}'**
  String widgetBoostAmount(String amount);

  /// No description provided for @widgetEnterAmountFirst.
  ///
  /// In en, this message translates to:
  /// **'Enter an amount above zero first.'**
  String get widgetEnterAmountFirst;

  /// No description provided for @widgetAddedToCategory.
  ///
  /// In en, this message translates to:
  /// **'Added to {category}.'**
  String widgetAddedToCategory(String category);

  /// No description provided for @widgetAmountHint.
  ///
  /// In en, this message translates to:
  /// **'Amount'**
  String get widgetAmountHint;

  /// No description provided for @widgetNoRecurring.
  ///
  /// In en, this message translates to:
  /// **'No recurring charges detected yet.'**
  String get widgetNoRecurring;

  /// No description provided for @widgetNoSplitPlans.
  ///
  /// In en, this message translates to:
  /// **'No split plans yet. Finalise a budget with more than one person.'**
  String get widgetNoSplitPlans;

  /// No description provided for @widgetOwed.
  ///
  /// In en, this message translates to:
  /// **'Owed {amount}'**
  String widgetOwed(String amount);

  /// No description provided for @widgetChooseImage.
  ///
  /// In en, this message translates to:
  /// **'Choose image'**
  String get widgetChooseImage;

  /// No description provided for @widgetWasteAnnual.
  ///
  /// In en, this message translates to:
  /// **'{count, plural, one{{amount} a year across {count} subscription.} other{{amount} a year across {count} subscriptions.}}'**
  String widgetWasteAnnual(String amount, int count);

  /// No description provided for @perMonth.
  ///
  /// In en, this message translates to:
  /// **'{amount}/mo'**
  String perMonth(String amount);

  /// One of five rotating aphorisms on the ASCII Fortune widget. Translate for sense, not literally — an equivalent saying in the target language reads better than a transliteration.
  ///
  /// In en, this message translates to:
  /// **'A penny saved is a penny earned'**
  String get fortunePennySaved;

  /// No description provided for @fortuneSmallSteps.
  ///
  /// In en, this message translates to:
  /// **'Small steps lead to big gains'**
  String get fortuneSmallSteps;

  /// No description provided for @fortuneGoalsPatience.
  ///
  /// In en, this message translates to:
  /// **'Goals achieved with patience'**
  String get fortuneGoalsPatience;

  /// No description provided for @fortuneSmartSpending.
  ///
  /// In en, this message translates to:
  /// **'Smart spending = happy future'**
  String get fortuneSmartSpending;

  /// No description provided for @fortuneInvestYourself.
  ///
  /// In en, this message translates to:
  /// **'Invest in yourself today'**
  String get fortuneInvestYourself;

  /// No description provided for @widgetAddGoalToTrack.
  ///
  /// In en, this message translates to:
  /// **'Add a goal to start tracking'**
  String get widgetAddGoalToTrack;

  /// No description provided for @widgetSavingsProgress.
  ///
  /// In en, this message translates to:
  /// **'Savings progress {percent}%'**
  String widgetSavingsProgress(int percent);

  /// No description provided for @settingsCurrency.
  ///
  /// In en, this message translates to:
  /// **'Currency'**
  String get settingsCurrency;

  /// No description provided for @settingsUsingFallbackRates.
  ///
  /// In en, this message translates to:
  /// **'Using fallback rates.'**
  String get settingsUsingFallbackRates;

  /// No description provided for @settingsRatesUpdated.
  ///
  /// In en, this message translates to:
  /// **'Rates updated {when}.'**
  String settingsRatesUpdated(String when);

  /// No description provided for @settingsRefreshing.
  ///
  /// In en, this message translates to:
  /// **'Refreshing…'**
  String get settingsRefreshing;

  /// No description provided for @settingsRefreshRates.
  ///
  /// In en, this message translates to:
  /// **'Refresh rates'**
  String get settingsRefreshRates;

  /// No description provided for @settingsTypography.
  ///
  /// In en, this message translates to:
  /// **'Typography'**
  String get settingsTypography;

  /// No description provided for @settingsLanguage.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get settingsLanguage;

  /// No description provided for @settingsLanguageSubtitle.
  ///
  /// In en, this message translates to:
  /// **'Applies everywhere in the app straight away.'**
  String get settingsLanguageSubtitle;

  /// No description provided for @settingsLanguageSystem.
  ///
  /// In en, this message translates to:
  /// **'System default'**
  String get settingsLanguageSystem;

  /// No description provided for @settingsTextSize.
  ///
  /// In en, this message translates to:
  /// **'Text size — {percent}%'**
  String settingsTextSize(int percent);

  /// No description provided for @settingsAccount.
  ///
  /// In en, this message translates to:
  /// **'Account'**
  String get settingsAccount;

  /// No description provided for @settingsDemoMode.
  ///
  /// In en, this message translates to:
  /// **'Demo mode — data stays on this device.'**
  String get settingsDemoMode;

  /// No description provided for @settingsSignedInAs.
  ///
  /// In en, this message translates to:
  /// **'Signed in as {name}'**
  String settingsSignedInAs(String name);

  /// No description provided for @settingsLeaveDemo.
  ///
  /// In en, this message translates to:
  /// **'Leave demo mode'**
  String get settingsLeaveDemo;

  /// No description provided for @settingsSignOut.
  ///
  /// In en, this message translates to:
  /// **'Sign out'**
  String get settingsSignOut;

  /// No description provided for @settingsData.
  ///
  /// In en, this message translates to:
  /// **'Data'**
  String get settingsData;

  /// No description provided for @settingsResetAll.
  ///
  /// In en, this message translates to:
  /// **'Reset all finance data'**
  String get settingsResetAll;

  /// No description provided for @settingsResetTitle.
  ///
  /// In en, this message translates to:
  /// **'Reset everything?'**
  String get settingsResetTitle;

  /// No description provided for @settingsResetBody.
  ///
  /// In en, this message translates to:
  /// **'This permanently deletes all transactions, goals, and budgets on this device. It cannot be undone.'**
  String get settingsResetBody;

  /// No description provided for @settingsDeveloper.
  ///
  /// In en, this message translates to:
  /// **'Developer'**
  String get settingsDeveloper;

  /// No description provided for @settingsDeveloperBody.
  ///
  /// In en, this message translates to:
  /// **'Debug build only. Loads a deterministic dataset so every widget has something real to show.'**
  String get settingsDeveloperBody;

  /// No description provided for @settingsLoadSample.
  ///
  /// In en, this message translates to:
  /// **'Load sample data'**
  String get settingsLoadSample;

  /// No description provided for @settingsSampleLoaded.
  ///
  /// In en, this message translates to:
  /// **'Sample data loaded.'**
  String get settingsSampleLoaded;

  /// No description provided for @settingsSampleCleared.
  ///
  /// In en, this message translates to:
  /// **'Sample data cleared.'**
  String get settingsSampleCleared;

  /// No description provided for @relativeJustNow.
  ///
  /// In en, this message translates to:
  /// **'just now'**
  String get relativeJustNow;

  /// No description provided for @relativeMinutesAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}m ago'**
  String relativeMinutesAgo(int count);

  /// No description provided for @relativeHoursAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}h ago'**
  String relativeHoursAgo(int count);

  /// No description provided for @relativeDaysAgo.
  ///
  /// In en, this message translates to:
  /// **'{count}d ago'**
  String relativeDaysAgo(int count);
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
      'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
      'an issue with the localizations generation tool. Please file an issue '
      'on GitHub with a reproducible sample app and the gen-l10n configuration '
      'that was used.');
}
