// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Cash Compass';

  @override
  String get tabDashboard => 'Dashboard';

  @override
  String get tabGoals => 'Goals';

  @override
  String get tabPlanner => 'Planner';

  @override
  String get tabWorkspace => 'Workspace';

  @override
  String get tabSettings => 'Settings';

  @override
  String get actionCancel => 'Cancel';

  @override
  String get actionSave => 'Save';

  @override
  String get actionAdd => 'Add';

  @override
  String get actionClear => 'Clear';

  @override
  String get actionDone => 'Done';

  @override
  String get actionRemove => 'Remove';

  @override
  String get actionContinue => 'Continue';

  @override
  String get actionReset => 'Reset';

  @override
  String get actionDiscard => 'Discard';

  @override
  String get actionKeep => 'Keep';

  @override
  String get actionSkip => 'Skip';

  @override
  String get actionInclude => 'Include';

  @override
  String get actionUndo => 'Undo';

  @override
  String get actionSettle => 'Settle';

  @override
  String get labelSettled => 'Settled';

  @override
  String get authTagline => 'Live balance and budget signals, on your terms.';

  @override
  String get authFieldName => 'Name';

  @override
  String get authFieldEmail => 'Email';

  @override
  String get authFieldPassword => 'Password';

  @override
  String get authFieldConfirmPassword => 'Confirm password';

  @override
  String get authPasswordHelper => 'At least 8 characters';

  @override
  String get authWorking => 'Working…';

  @override
  String get authCreateAccount => 'Create account';

  @override
  String get authSignIn => 'Sign in';

  @override
  String get authHaveAccount => 'Already have an account? Sign in';

  @override
  String get authNeedAccount => 'Need an account? Sign up';

  @override
  String get authNoBackend =>
      'This build has no account backend configured. Demo mode works fully offline.';

  @override
  String get authContinueWithoutAccount => 'Continue without an account';

  @override
  String get authDemoDialogTitle => 'Continue without an account?';

  @override
  String get authDemoDialogBody =>
      'Demo mode starts from a clean slate — any data already on this device will be cleared. Nothing is sent anywhere.';

  @override
  String get authErrorNoSupabase =>
      'Accounts are unavailable — this build has no Supabase config. Use demo mode.';

  @override
  String get authErrorMissingCredentials => 'Enter your email and password.';

  @override
  String get authErrorSignInFailed => 'Could not sign in. Please try again.';

  @override
  String get authErrorSignUpFailed =>
      'Could not create the account. Please try again.';

  @override
  String get authErrorConfirmEmail =>
      'Check your email to confirm your account, then sign in.';

  @override
  String get authErrorMissingName => 'Enter your name.';

  @override
  String get authErrorInvalidEmail => 'Enter a valid email address.';

  @override
  String get authErrorShortPassword =>
      'Password must be at least 8 characters.';

  @override
  String get authErrorPasswordMismatch => 'Passwords do not match.';

  @override
  String get quickScanReceipt => 'Scan Receipt';

  @override
  String get quickScanReceiptSubtitle => 'Read the amount from a photo';

  @override
  String get quickScanSeveral => 'Scan Several';

  @override
  String get quickScanSeveralSubtitle => 'Pick receipts from your gallery';

  @override
  String get quickAddEntry => 'Add Entry';

  @override
  String get quickAddEntrySubtitle => 'Log an expense or income';

  @override
  String get quickSetGoal => 'Set Goal';

  @override
  String get quickSetGoalSubtitle => 'Create a savings target';

  @override
  String get quickPlanBudget => 'Plan Budget';

  @override
  String get quickPlanBudgetSubtitle => 'Cost out a trip, outing, or event';

  @override
  String get scanErrorCameraUnavailable =>
      'Camera unavailable — check the permission in Settings. Add the entry by hand for now.';

  @override
  String get scanErrorNoText =>
      'No text found in that photo. Try again in better light, or type it in.';

  @override
  String get scanErrorNothingUseful =>
      'Could not find an amount on that receipt. Fill it in below.';

  @override
  String get batchReadingReceipts => 'Reading receipts';

  @override
  String batchProgress(int done, int total) {
    return '$done of $total';
  }

  @override
  String batchSavedReceipts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Saved $count receipts.',
      one: 'Saved $count receipt.',
    );
    return '$_temp0';
  }

  @override
  String get batchReviewTitle => 'Review receipts';

  @override
  String get batchNothingToSave => 'Nothing to save';

  @override
  String batchSaveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Save $count receipts',
      one: 'Save $count receipt',
    );
    return '$_temp0';
  }

  @override
  String get batchCouldNotRead => 'Could not read this one';

  @override
  String get batchFieldMerchant => 'Merchant';

  @override
  String get batchNoPhotoDate => 'no photo date';

  @override
  String get batchRetryTooltip => 'Read this one again';

  @override
  String get batchDuplicateWarning =>
      'Looks like a repeat of an earlier receipt in this batch. Skip it if you picked the same photo twice.';

  @override
  String batchAmountConverted(String amount, String code) {
    return '$amount $code converted';
  }

  @override
  String get scannedPleaseCheck => 'Scanned — please check';

  @override
  String receiptDiscrepancyCash(String labelled, String computed) {
    return 'Labelled total $labelled disagrees with cash − change $computed. Using the arithmetic.';
  }

  @override
  String receiptDiscrepancyItems(String labelled, String itemSum) {
    return 'Total $labelled does not match the items ($itemSum) — please confirm.';
  }

  @override
  String get dashTotalBalance => 'Total balance';

  @override
  String get dashSnapshotHint => 'This snapshot drives the whole dashboard.';

  @override
  String get dashStatAvailable => 'Available';

  @override
  String get dashStatSpentToday => 'Spent today';

  @override
  String get dashStatTotalSpent => 'Total spent';

  @override
  String get dashStatAveragePerDay => 'Average / day';

  @override
  String get dashRecentActivity => 'Recent activity';

  @override
  String get dashNoEntries => 'No entries yet. Add one with the + button.';

  @override
  String get budgetingWindow => 'Budgeting window';

  @override
  String get fieldStart => 'Start';

  @override
  String get fieldEnd => 'End';

  @override
  String get dailyBudget => 'Daily budget';

  @override
  String overDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'over $count days',
      one: 'over $count day',
    );
    return '$_temp0';
  }

  @override
  String get smartCardsTitle => 'Smart cards';

  @override
  String get smartCardsWatching =>
      'Smart cards are on watch. Discretionary spending is comfortable today.';

  @override
  String smartCardsSpent(String amount, int percent) {
    return 'You have spent $amount on small extras today — $percent% of your daily limit.';
  }

  @override
  String smartCardsAnnualised(String amount) {
    return 'At this rate that is $amount a year.';
  }

  @override
  String smartCardsDivert(String goal) {
    return 'Diverting it to \"$goal\" would get you there sooner.';
  }

  @override
  String get spendingPatternTitle => 'Spending pattern';

  @override
  String spendingPatternNight(String weekday, String tag, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Your spontaneous spending clusters around $weekday nights — mostly $tag purchases ($count so far).',
      one:
          'Your spontaneous spending clusters around $weekday nights — mostly $tag purchases ($count so far).',
    );
    return '$_temp0';
  }

  @override
  String spendingPatternDay(String weekday, String tag, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Your spontaneous spending clusters around $weekday daytimes — mostly $tag purchases ($count so far).',
      one:
          'Your spontaneous spending clusters around $weekday daytimes — mostly $tag purchases ($count so far).',
    );
    return '$_temp0';
  }

  @override
  String get weekdayMonday => 'Monday';

  @override
  String get weekdayTuesday => 'Tuesday';

  @override
  String get weekdayWednesday => 'Wednesday';

  @override
  String get weekdayThursday => 'Thursday';

  @override
  String get weekdayFriday => 'Friday';

  @override
  String get weekdaySaturday => 'Saturday';

  @override
  String get weekdaySunday => 'Sunday';

  @override
  String get smartSuggestionsTitle => 'Smart suggestions';

  @override
  String suggestionWatchCategoryTitle(String category) {
    return 'Watch $category';
  }

  @override
  String suggestionWatchCategoryBody(String amount) {
    return 'It is your largest category this month. Trimming 10% would free about $amount.';
  }

  @override
  String suggestionBudgetAlertTitle(String category) {
    return '$category budget alert';
  }

  @override
  String suggestionBudgetAlertBody(int percent) {
    return 'You have used $percent% of this month\'s limit.';
  }

  @override
  String get suggestionAuditSubsTitle => 'Audit your subscriptions';

  @override
  String suggestionAuditSubsBody(String names) {
    return 'Recurring charges detected: $names.';
  }

  @override
  String get suggestionTrackTitle => 'Track for 7 days';

  @override
  String get suggestionTrackBody =>
      'Add a week of entries and personalised suggestions will appear here.';

  @override
  String get recurringChargesTitle => 'Recurring charges';

  @override
  String get recurringChargesSubtitle =>
      'Detected from a monthly cadence in your history.';

  @override
  String get recurringChargesEmpty =>
      'Nothing detected yet. Recurring charges appear after a couple of monthly repeats.';

  @override
  String subscriptionCharges(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count charges · last $date',
      many: '$count charges · last $date',
      few: '$count charges · last $date',
      one: '$count charge · last $date',
    );
    return '$_temp0';
  }

  @override
  String perYear(String amount) {
    return '$amount/yr';
  }

  @override
  String get financialCalendarTitle => 'Financial calendar';

  @override
  String get financialCalendarSubtitle =>
      'Events that can change your spending velocity.';

  @override
  String get regionIndia => 'India';

  @override
  String get regionRussia => 'Russia';

  @override
  String eventComingSoon(String name) {
    return '$name is coming soon';
  }

  @override
  String eventForecast(String projected, String increase) {
    return 'Spending usually rises during this window. Projected $projected per active day — about $increase above your usual.';
  }

  @override
  String get eventNoHistory =>
      'Estimated from your overall average — no history for this window yet.';

  @override
  String get eventToday => 'Today';

  @override
  String eventDaysShort(int count) {
    return '${count}d';
  }

  @override
  String get eventWinterExamName => 'Winter exam season';

  @override
  String get eventWinterExamNote =>
      'Study materials, transport, and late-night food often rise.';

  @override
  String get eventNewYearName => 'New Year holidays';

  @override
  String get eventNewYearNote =>
      'Gifting, travel, and social spending cluster around this break.';

  @override
  String get eventStipendName => 'Student stipend cycle';

  @override
  String get eventStipendNote =>
      'A regular stipend date to anchor your monthly plan.';

  @override
  String get eventUniExamName => 'University exam window';

  @override
  String get eventUniExamNote =>
      'Printing, travel, and convenience food can increase during exam weeks.';

  @override
  String get eventDiwaliName => 'Diwali cluster';

  @override
  String get eventDiwaliNote =>
      'Gifts, travel, and celebrations can put pressure on flexible cash.';

  @override
  String get eventSemesterName => 'Semester reset';

  @override
  String get eventSemesterNote =>
      'Books, supplies, and housing deposits often return at the start of term.';

  @override
  String get eventTypeAcademic => 'Academic';

  @override
  String get eventTypeHoliday => 'Holiday';

  @override
  String get eventTypeIncome => 'Income';

  @override
  String get eventTypeFestival => 'Festival';

  @override
  String get eventTypeStudentCosts => 'Student costs';

  @override
  String get locationGuidanceTitle => 'Location guidance';

  @override
  String get locationGuidanceSubtitle =>
      'Typical local costs against what is left for today.';

  @override
  String get fieldRegion => 'Region';

  @override
  String get geoUsCity => 'US City';

  @override
  String get geoIndiaMetro => 'India Metro';

  @override
  String get geoEasternEurope => 'Eastern Europe';

  @override
  String get stapleLunch => 'Lunch';

  @override
  String get stapleTransit => 'Transit';

  @override
  String get stapleGroceries => 'Groceries';

  @override
  String stapleCost(String cost, String limit) {
    return 'Typical $cost · suggested max $limit';
  }

  @override
  String get badgeOnBudget => 'On Budget';

  @override
  String get badgeTrimNeeded => 'Trim Needed';

  @override
  String get suggestionsTodayTitle => 'Suggestions for today';

  @override
  String get tipOverBudget =>
      'You are over today\'s budget. Switch to essential-only purchases for the rest of the day.';

  @override
  String get tipFinalQuarter =>
      'You are in the final 25% of your daily budget. Keep only high-priority plan items.';

  @override
  String get tipComfortable =>
      'You still have comfortable room today. Front-load essentials and delay impulse categories.';

  @override
  String get tipPlannedOverBudget =>
      'Your planned spend is above budget. Reduce one plan item by around 20-30%.';

  @override
  String get tipAverageOverBudget =>
      'Your average daily spend is above your location-adjusted budget. Try a three-day low-spend streak.';

  @override
  String get tipCategoryCaps =>
      'Use category caps for Food and Shopping today to protect tomorrow\'s flexibility.';

  @override
  String get dailyPlanTitle => 'Daily plan builder';

  @override
  String get dailyPlanSubtitle =>
      'Plan a day, then compare it against your daily budget.';

  @override
  String get dailyPlanName => 'Plan name';

  @override
  String get dailyPlanNameHint => 'Groceries and transit';

  @override
  String dailyPlanEstimate(String code) {
    return 'Estimate ($code)';
  }

  @override
  String get dailyPlanDate => 'Plan date';

  @override
  String get dailyPlanAdd => 'Add plan';

  @override
  String get dailyPlanInvalid => 'Add a plan name and a valid amount.';

  @override
  String get dailyPlanSpentThatDay => 'Spent that day';

  @override
  String get dailyPlanPlanned => 'Planned';

  @override
  String get dailyPlanRemaining => 'Remaining after plans';

  @override
  String get dailyPlanEmpty => 'No plans for this day yet.';

  @override
  String get dailyPlanDeleteTooltip => 'Delete plan';

  @override
  String get dayRecordsTitle => 'All day records';

  @override
  String get dayRecordsEmpty =>
      'No records yet. Add entries to start building history.';

  @override
  String get goalsEmptyTitle => 'No savings goals yet.';

  @override
  String get goalsEmptyBody => 'Use the + button to create one.';

  @override
  String get goalsGuidanceTitle => 'Personalised guidance';

  @override
  String goalAmountOf(String current, String target) {
    return '$current of $target';
  }

  @override
  String goalAddAmount(String amount) {
    return 'Add $amount';
  }

  @override
  String get goalInsightEmpty =>
      'Add a few expenses and personalised guidance will appear here.';

  @override
  String goalInsightTopShare(String category, int percent) {
    return '$category is $percent% of your spending. A 10% trim there moves your goals faster than cutting anywhere else.';
  }

  @override
  String goalInsightTopTwo(String first, String second, int percent) {
    return 'Together, $first and $second account for $percent% of outgoings.';
  }

  @override
  String get goalInsightAutomate =>
      'Automating a transfer on the day you get paid protects savings before spending starts.';

  @override
  String get goalInsightReviewWeekly =>
      'Reviewing one category a week is more sustainable than cutting everything at once.';

  @override
  String get chartTopCategories => 'Top categories';

  @override
  String get chartNoExpenses => 'No expenses yet.';

  @override
  String get chartIncomeVsExpenses => 'Income vs expenses';

  @override
  String get chartLastSixMonths => 'Last six months';

  @override
  String get chartNotEnoughHistory => 'Not enough history yet.';

  @override
  String get chartLegendIncome => 'Income';

  @override
  String get chartLegendExpenses => 'Expenses';

  @override
  String get monthJan => 'Jan';

  @override
  String get monthFeb => 'Feb';

  @override
  String get monthMar => 'Mar';

  @override
  String get monthApr => 'Apr';

  @override
  String get monthMay => 'May';

  @override
  String get monthJun => 'Jun';

  @override
  String get monthJul => 'Jul';

  @override
  String get monthAug => 'Aug';

  @override
  String get monthSep => 'Sep';

  @override
  String get monthOct => 'Oct';

  @override
  String get monthNov => 'Nov';

  @override
  String get monthDec => 'Dec';

  @override
  String get entrySheetTitleAdd => 'Add Entry';

  @override
  String get entrySheetTitleCheck => 'Check Receipt';

  @override
  String get entrySheetSubtitleAdd =>
      'Log an expense or income. Mark recurring charges to track them.';

  @override
  String get entrySheetSubtitleCheck =>
      'Read from your receipt. Anything marked \"please check\" was a guess — correct it before saving.';

  @override
  String get entrySheetSubmit => 'Save Entry';

  @override
  String get entryRecurringHint =>
      'This looks like a recurring charge. Set to monthly — change it below if that is wrong.';

  @override
  String get entryTypeExpense => 'Expense';

  @override
  String get entryTypeIncome => 'Income';

  @override
  String get entryFieldName => 'Name';

  @override
  String get entryFieldNameHint => 'e.g. Grocery run';

  @override
  String entryFieldAmount(String code) {
    return 'Amount ($code)';
  }

  @override
  String get entryFieldCategory => 'Category';

  @override
  String get entryFieldDate => 'Date';

  @override
  String get entryFieldNote => 'Note';

  @override
  String get entryFieldNoteHint => 'Any details about this entry';

  @override
  String get entryRecurringQuestion => 'Is this recurring?';

  @override
  String get entryUnplanned => 'Unplanned / spontaneous';

  @override
  String get entryUnplannedSubtitle =>
      'Optional context to make insights more useful, never judgmental.';

  @override
  String get entryReasonPrompt => 'What influenced this? Optional';

  @override
  String get entryInvalid => 'Please provide a name and a valid amount.';

  @override
  String get entrySaved => 'Entry saved.';

  @override
  String entrySavedRecurring(String cadence) {
    return 'Recurring $cadence entry added.';
  }

  @override
  String entryConvertedFrom(String amount, String code, String target) {
    return '$amount $code converted to $target';
  }

  @override
  String entryNoRate(String code) {
    return 'Receipt is in $code — no exchange rate available, so this is unconverted';
  }

  @override
  String get recurrenceNone => 'One-time';

  @override
  String get recurrenceDaily => 'Daily';

  @override
  String get recurrenceWeekly => 'Weekly';

  @override
  String get recurrenceBiweekly => 'Biweekly';

  @override
  String get recurrenceMonthly => 'Monthly';

  @override
  String get recurrenceYearly => 'Yearly';

  @override
  String get reasonEmotional => 'Emotional purchase';

  @override
  String get reasonSocial => 'Social';

  @override
  String get reasonDiscount => 'Discount / sale';

  @override
  String get reasonImpulse => 'Impulse';

  @override
  String get reasonAdjEmotional => 'emotional';

  @override
  String get reasonAdjSocial => 'social';

  @override
  String get reasonAdjDiscount => 'discount';

  @override
  String get reasonAdjImpulse => 'impulse';

  @override
  String get categoryIncome => 'Income';

  @override
  String get categorySalary => 'Salary';

  @override
  String get categoryFreelance => 'Freelance';

  @override
  String get categoryGroceries => 'Groceries';

  @override
  String get categoryTransport => 'Transport';

  @override
  String get categoryHousing => 'Housing';

  @override
  String get categoryUtilities => 'Utilities';

  @override
  String get categoryEntertainment => 'Entertainment';

  @override
  String get categoryFood => 'Food';

  @override
  String get categoryShopping => 'Shopping';

  @override
  String get categoryHealth => 'Health';

  @override
  String get categoryTravel => 'Travel';

  @override
  String get categoryEducation => 'Education';

  @override
  String get categorySavings => 'Savings';

  @override
  String get categoryInvestment => 'Investment';

  @override
  String get categoryBusiness => 'Business';

  @override
  String get categoryGift => 'Gift';

  @override
  String get categoryOther => 'Other';

  @override
  String get goalSheetTitle => 'Set Savings Goal';

  @override
  String get goalSheetSubtitle =>
      'Define how much to save and by when. We\'ll show you the daily target.';

  @override
  String get goalSheetSubmit => 'Create Goal';

  @override
  String get goalFieldIcon => 'Icon';

  @override
  String get goalFieldName => 'Goal name';

  @override
  String get goalFieldNameHint => 'Emergency fund';

  @override
  String goalFieldTarget(String code) {
    return 'Target ($code)';
  }

  @override
  String get goalFieldSaved => 'Already saved';

  @override
  String get goalTimeframe => 'Timeframe';

  @override
  String get goalFieldDays => 'Days';

  @override
  String get goalMinimumDays => 'minimum 7';

  @override
  String get goalInvalid => 'Add a goal name and target amount.';

  @override
  String get goalCreated => 'Goal created.';

  @override
  String goalReachIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'To reach your goal in $count days:',
      many: 'To reach your goal in $count days:',
      few: 'To reach your goal in $count days:',
      one: 'To reach your goal in $count day:',
    );
    return '$_temp0';
  }

  @override
  String goalPerDay(String amount) {
    return '$amount / day';
  }

  @override
  String goalPerWeekMonth(String week, String month) {
    return '$week / week · $month / month';
  }

  @override
  String get goalCurrentGoals => 'Current goals';

  @override
  String get periodOneMonth => '1 Month';

  @override
  String get periodThreeMonths => '3 Months';

  @override
  String get periodSixMonths => '6 Months';

  @override
  String get periodOneYear => '1 Year';

  @override
  String get periodTwoYears => '2 Years';

  @override
  String get periodCustom => 'Custom';

  @override
  String get plannerSurvivalTitle => 'Survival calculator';

  @override
  String get plannerSurvivalSubtitle =>
      'Your daily spendable cash after essentials.';

  @override
  String get plannerDailySpendable => 'Daily spendable';

  @override
  String plannerHorizon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Planning horizon — $count days',
      many: 'Planning horizon — $count days',
      few: 'Planning horizon — $count days',
      one: 'Planning horizon — $count day',
    );
    return '$_temp0';
  }

  @override
  String plannerUpcomingBills(String code) {
    return 'Upcoming must-pay bills ($code)';
  }

  @override
  String get plannerIncomeStreams => 'Income streams';

  @override
  String get plannerFieldSource => 'Source';

  @override
  String get plannerFieldAmount => 'Amount';

  @override
  String get plannerFixedCosts => 'Fixed costs';

  @override
  String get plannerFieldBill => 'Bill';

  @override
  String get plannerAddFixedCost => 'Add fixed cost';

  @override
  String get zoneGreen => 'Green Zone';

  @override
  String get zoneTight => 'Tight Zone';

  @override
  String get zoneCritical => 'Critical Zone';

  @override
  String get cadenceOneTime => 'One-time';

  @override
  String get cadenceWeekly => 'Weekly';

  @override
  String get cadenceMonthly => 'Monthly';

  @override
  String get plannerSocialTitle => 'Social budgeting';

  @override
  String get plannerSocialSubtitle =>
      'See the impact of nights out before you commit.';

  @override
  String get plannerFieldEvent => 'Event';

  @override
  String get plannerFieldLow => 'Low';

  @override
  String get plannerFieldRealistic => 'Realistic';

  @override
  String get plannerFieldStretch => 'Stretch';

  @override
  String get plannerAddPlan => 'Add plan';

  @override
  String plannerSocialImpact(String amount) {
    return 'If every realistic plan happens, your daily spendable becomes $amount.';
  }

  @override
  String plannerYourShare(String date, String amount) {
    return '$date · your share $amount';
  }

  @override
  String plannerYourShareSplit(String date, String amount, int count) {
    return '$date · your share $amount of $count';
  }

  @override
  String plannerRange(String low, String high) {
    return 'Range $low – $high';
  }

  @override
  String get plannerRunwayTitle => 'Loan runway';

  @override
  String get plannerRunwaySubtitle =>
      'Make a lump sum last the whole semester.';

  @override
  String get plannerLumpSum => 'Lump sum';

  @override
  String get plannerSafetyBuffer => 'Safety buffer';

  @override
  String plannerRunwayWeeks(String weeks) {
    return 'Remaining runway: $weeks weeks';
  }

  @override
  String plannerSemesterWeeksLeft(String weeks) {
    return '$weeks semester weeks left.';
  }

  @override
  String get plannerWillRunOut => ' At this pace the money runs out first.';

  @override
  String get plannerWeeklyBurn => 'Weekly burn';

  @override
  String get plannerSuggestedCap => 'Suggested cap';

  @override
  String get plannerStreakTitle => 'Bloom streaks';

  @override
  String get plannerStreakSubtitle =>
      'Stay within your plan three days running to earn a badge.';

  @override
  String get plannerCurrentStreak => 'Current streak';

  @override
  String plannerStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count days',
      many: '$count days',
      few: '$count days',
      one: '$count day',
    );
    return '$_temp0';
  }

  @override
  String get plannerStreakBadge => '3-day bloom streak 🌸';

  @override
  String get plannerMarkedOnTrack => 'Marked on track today';

  @override
  String get plannerMarkOnTrack => 'Mark today on track';

  @override
  String get plannerStreakFooter =>
      'No penalties. Missed days just restart softly.';

  @override
  String get budgetPlannerTitle => 'Budget planner';

  @override
  String get budgetDiscardTooltip => 'Discard draft';

  @override
  String get budgetDiscardDialogTitle => 'Discard this plan?';

  @override
  String get budgetDiscardDialogBody =>
      'The draft and its items will be deleted.';

  @override
  String get budgetTypeTrip => 'Trip';

  @override
  String get budgetTypeOuting => 'Outing';

  @override
  String get budgetTypeEvent => 'Event';

  @override
  String get budgetFieldTitle => 'Plan title';

  @override
  String get budgetFieldTitleHint => 'e.g. Goa weekend';

  @override
  String get budgetFieldFrom => 'From';

  @override
  String get budgetFieldTo => 'To (optional)';

  @override
  String get budgetSplittingBetween => 'Splitting between';

  @override
  String get budgetItems => 'Items';

  @override
  String get budgetFieldItem => 'Item';

  @override
  String budgetFieldCost(String code) {
    return 'Cost ($code)';
  }

  @override
  String get budgetAddItemTooltip => 'Add item';

  @override
  String get budgetItemsEmpty => 'Add items above to see the breakdown.';

  @override
  String get budgetTotal => 'Total';

  @override
  String budgetPerPerson(int count) {
    return 'Per person ($count)';
  }

  @override
  String get budgetFinalise => 'Finalise bill';

  @override
  String get budgetFinalised => 'Budget finalised.';

  @override
  String get budgetItemInvalid => 'Add an item name and a cost above zero.';

  @override
  String get budgetErrorNothing => 'Nothing to finalise.';

  @override
  String get budgetErrorNoTitle => 'Add a plan title before finalising.';

  @override
  String get budgetErrorNoItems => 'Add at least one item to generate a bill.';

  @override
  String get budgetErrorBadDates => 'End date cannot be before the start date.';

  @override
  String get budgetReceiptsTitle => 'Finalised bills';

  @override
  String budgetReceiptSummary(String type, String from, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$type · $from · $count items',
      many: '$type · $from · $count items',
      few: '$type · $from · $count items',
      one: '$type · $from · $count item',
    );
    return '$_temp0';
  }

  @override
  String budgetReceiptSummaryRange(
      String type, String from, String to, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$type · $from → $to · $count items',
      many: '$type · $from → $to · $count items',
      few: '$type · $from → $to · $count items',
      one: '$type · $from → $to · $count item',
    );
    return '$_temp0';
  }

  @override
  String budgetEach(String amount) {
    return '$amount each';
  }

  @override
  String get budgetDeleteTooltip => 'Delete bill';

  @override
  String get workspaceEmptyTitle => 'Build your workspace';

  @override
  String get workspaceEmptyBody => 'Add the cards you want to see at a glance.';

  @override
  String get workspaceAddWidget => 'Add widget';

  @override
  String get workspaceAddWidgetTitle => 'Add a widget';

  @override
  String get workspaceTitle => 'Workspace';

  @override
  String get workspaceDragToReorder => 'Drag to reorder';

  @override
  String get workspaceEditLayout => 'Edit layout';

  @override
  String get workspaceResize => 'Resize';

  @override
  String get workspaceClearTitle => 'Clear workspace?';

  @override
  String get workspaceClearBody =>
      'Every widget is removed, including any images you added.';

  @override
  String get sizeSmall => 'S';

  @override
  String get sizeMedium => 'M';

  @override
  String get sizeLarge => 'L';

  @override
  String get widgetTodaySnapshot => 'Today Snapshot';

  @override
  String get widgetBudgetHealth => 'Budget Health';

  @override
  String get widgetTopCategories => 'Top Categories';

  @override
  String get widgetGoalProgress => 'Goal Progress';

  @override
  String get widgetSafeToSpend => 'Safe-to-Spend';

  @override
  String get widgetSubStashJar => 'Sub-Stash Jar';

  @override
  String get widgetBurnRateLine => 'Burn-Rate Line';

  @override
  String get widgetQuickEntryPad => 'Quick-Entry Pad';

  @override
  String get widgetWasteAuditor => 'Waste Auditor';

  @override
  String get widgetRoommateSync => 'Roommate Sync';

  @override
  String get widgetMedia => 'Image';

  @override
  String get widgetMangaStatus => 'Manga Status';

  @override
  String get widgetAsciiFortune => 'ASCII Fortune';

  @override
  String get widgetChibiMascot => 'Chibi Mascot';

  @override
  String get widgetGrowthGem => 'Growth Gem';

  @override
  String get widgetNoCategoryBudgets => 'No category budgets set yet.';

  @override
  String get widgetNoGoals => 'No goals yet.';

  @override
  String get widgetSetBalanceFirst =>
      'Set your balance on the Dashboard to see a daily allowance.';

  @override
  String get widgetSafeToSpendLabel => 'Safe to spend';

  @override
  String get widgetSubStash => 'Sub-stash';

  @override
  String widgetBoostsGoal(String goal) {
    return 'Boosts \"$goal\"';
  }

  @override
  String widgetBoostAmount(String amount) {
    return 'Boost $amount';
  }

  @override
  String get widgetEnterAmountFirst => 'Enter an amount above zero first.';

  @override
  String widgetAddedToCategory(String category) {
    return 'Added to $category.';
  }

  @override
  String get widgetAmountHint => 'Amount';

  @override
  String get widgetNoRecurring => 'No recurring charges detected yet.';

  @override
  String get widgetNoSplitPlans =>
      'No split plans yet. Finalise a budget with more than one person.';

  @override
  String widgetOwed(String amount) {
    return 'Owed $amount';
  }

  @override
  String get widgetChooseImage => 'Choose image';

  @override
  String widgetWasteAnnual(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount a year across $count subscriptions.',
      one: '$amount a year across $count subscription.',
    );
    return '$_temp0';
  }

  @override
  String perMonth(String amount) {
    return '$amount/mo';
  }

  @override
  String get fortunePennySaved => '💰 A penny saved is a penny earned';

  @override
  String get fortuneSmallSteps => '📈 Small steps lead to big gains';

  @override
  String get fortuneGoalsPatience => '🎯 Goals achieved with patience';

  @override
  String get fortuneSmartSpending => '💡 Smart spending = happy future';

  @override
  String get fortuneInvestYourself => '🚀 Invest in yourself today';

  @override
  String get widgetAddGoalToTrack => 'Add a goal to start tracking';

  @override
  String widgetSavingsProgress(int percent) {
    return 'Savings progress $percent%';
  }

  @override
  String get settingsCurrency => 'Currency';

  @override
  String get settingsUsingFallbackRates => 'Using fallback rates.';

  @override
  String settingsRatesUpdated(String when) {
    return 'Rates updated $when.';
  }

  @override
  String get settingsRefreshing => 'Refreshing…';

  @override
  String get settingsRefreshRates => 'Refresh rates';

  @override
  String get settingsTheme => 'Theme';

  @override
  String get settingsTypography => 'Typography';

  @override
  String get settingsLanguage => 'Language';

  @override
  String get settingsLanguageSubtitle =>
      'Applies everywhere in the app straight away.';

  @override
  String get settingsLanguageSystem => 'System default';

  @override
  String get settingsFontDefault => 'Default';

  @override
  String get settingsFontEditorial => 'Editorial';

  @override
  String get settingsFontMono => 'Mono';

  @override
  String settingsTextSize(int percent) {
    return 'Text size — $percent%';
  }

  @override
  String get settingsAccount => 'Account';

  @override
  String get settingsDemoMode => 'Demo mode — data stays on this device.';

  @override
  String settingsSignedInAs(String name) {
    return 'Signed in as $name';
  }

  @override
  String get settingsLeaveDemo => 'Leave demo mode';

  @override
  String get settingsSignOut => 'Sign out';

  @override
  String get settingsData => 'Data';

  @override
  String get settingsResetAll => 'Reset all finance data';

  @override
  String get settingsResetTitle => 'Reset everything?';

  @override
  String get settingsResetBody =>
      'This permanently deletes all transactions, goals, and budgets on this device. It cannot be undone.';

  @override
  String get settingsDeveloper => 'Developer';

  @override
  String get settingsDeveloperBody =>
      'Debug build only. Loads a deterministic dataset so every widget has something real to show.';

  @override
  String get settingsLoadSample => 'Load sample data';

  @override
  String get settingsSampleLoaded => 'Sample data loaded.';

  @override
  String get settingsSampleCleared => 'Sample data cleared.';

  @override
  String get relativeJustNow => 'just now';

  @override
  String relativeMinutesAgo(int count) {
    return '${count}m ago';
  }

  @override
  String relativeHoursAgo(int count) {
    return '${count}h ago';
  }

  @override
  String relativeDaysAgo(int count) {
    return '${count}d ago';
  }

  @override
  String get themeSoftBloom => 'Soft Bloom';
}
