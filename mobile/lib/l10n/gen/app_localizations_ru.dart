// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Cash Compass';

  @override
  String get tabDashboard => 'Обзор';

  @override
  String get tabGoals => 'Цели';

  @override
  String get tabPlanner => 'Планировщик';

  @override
  String get tabWorkspace => 'Рабочий стол';

  @override
  String get tabSettings => 'Настройки';

  @override
  String get actionCancel => 'Отмена';

  @override
  String get actionSave => 'Сохранить';

  @override
  String get actionAdd => 'Добавить';

  @override
  String get actionClear => 'Очистить';

  @override
  String get actionDone => 'Готово';

  @override
  String get actionRemove => 'Удалить';

  @override
  String get actionContinue => 'Продолжить';

  @override
  String get actionReset => 'Сбросить';

  @override
  String get actionDiscard => 'Удалить';

  @override
  String get actionKeep => 'Оставить';

  @override
  String get actionSkip => 'Пропустить';

  @override
  String get actionInclude => 'Вернуть';

  @override
  String get actionUndo => 'Отменить';

  @override
  String get actionSettle => 'Рассчитаться';

  @override
  String get labelSettled => 'Рассчитано';

  @override
  String get authTagline =>
      'Баланс и подсказки по бюджету — на ваших условиях.';

  @override
  String get authFieldName => 'Имя';

  @override
  String get authFieldEmail => 'Эл. почта';

  @override
  String get authFieldPassword => 'Пароль';

  @override
  String get authFieldConfirmPassword => 'Повторите пароль';

  @override
  String get authPasswordHelper => 'Не менее 8 символов';

  @override
  String get authWorking => 'Подождите…';

  @override
  String get authCreateAccount => 'Создать аккаунт';

  @override
  String get authSignIn => 'Войти';

  @override
  String get authHaveAccount => 'Уже есть аккаунт? Войти';

  @override
  String get authNeedAccount => 'Нет аккаунта? Зарегистрироваться';

  @override
  String get authNoBackend =>
      'В этой сборке не настроен сервер аккаунтов. Демо-режим работает полностью офлайн.';

  @override
  String get authContinueWithoutAccount => 'Продолжить без аккаунта';

  @override
  String get authDemoDialogTitle => 'Продолжить без аккаунта?';

  @override
  String get authDemoDialogBody =>
      'Демо-режим начинается с чистого листа — все данные на этом устройстве будут удалены. Ничего никуда не отправляется.';

  @override
  String get authErrorNoSupabase =>
      'Аккаунты недоступны — в этой сборке нет настроек Supabase. Используйте демо-режим.';

  @override
  String get authErrorMissingCredentials => 'Введите почту и пароль.';

  @override
  String get authErrorSignInFailed => 'Не удалось войти. Попробуйте ещё раз.';

  @override
  String get authErrorSignUpFailed =>
      'Не удалось создать аккаунт. Попробуйте ещё раз.';

  @override
  String get authErrorConfirmEmail =>
      'Подтвердите аккаунт по ссылке из письма, затем войдите.';

  @override
  String get authErrorMissingName => 'Введите имя.';

  @override
  String get authErrorInvalidEmail => 'Введите корректный адрес эл. почты.';

  @override
  String get authErrorShortPassword =>
      'Пароль должен быть не короче 8 символов.';

  @override
  String get authErrorPasswordMismatch => 'Пароли не совпадают.';

  @override
  String get quickScanReceipt => 'Сканировать чек';

  @override
  String get quickScanReceiptSubtitle => 'Считать сумму с фотографии';

  @override
  String get quickScanSeveral => 'Сканировать несколько';

  @override
  String get quickScanSeveralSubtitle => 'Выбрать чеки из галереи';

  @override
  String get quickAddEntry => 'Добавить запись';

  @override
  String get quickAddEntrySubtitle => 'Записать расход или доход';

  @override
  String get quickSetGoal => 'Поставить цель';

  @override
  String get quickSetGoalSubtitle => 'Создать цель по накоплениям';

  @override
  String get quickPlanBudget => 'Спланировать бюджет';

  @override
  String get quickPlanBudgetSubtitle =>
      'Рассчитать поездку, вылазку или мероприятие';

  @override
  String get scanErrorCameraUnavailable =>
      'Камера недоступна — проверьте разрешение в настройках. Пока добавьте запись вручную.';

  @override
  String get scanErrorNoText =>
      'На фотографии не найдено текста. Попробуйте при лучшем освещении или введите вручную.';

  @override
  String get scanErrorNothingUseful =>
      'Не удалось найти сумму на чеке. Заполните её ниже.';

  @override
  String get batchReadingReceipts => 'Читаем чеки';

  @override
  String batchProgress(int done, int total) {
    return '$done из $total';
  }

  @override
  String batchSavedReceipts(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сохранено $count чека.',
      many: 'Сохранено $count чеков.',
      few: 'Сохранено $count чека.',
      one: 'Сохранён $count чек.',
    );
    return '$_temp0';
  }

  @override
  String get batchReviewTitle => 'Проверка чеков';

  @override
  String get batchNothingToSave => 'Нечего сохранять';

  @override
  String batchSaveCount(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Сохранить $count чека',
      many: 'Сохранить $count чеков',
      few: 'Сохранить $count чека',
      one: 'Сохранить $count чек',
    );
    return '$_temp0';
  }

  @override
  String get batchCouldNotRead => 'Не удалось прочитать этот чек';

  @override
  String get batchFieldMerchant => 'Магазин';

  @override
  String get batchNoPhotoDate => 'нет даты съёмки';

  @override
  String get batchRetryTooltip => 'Прочитать ещё раз';

  @override
  String get batchDuplicateWarning =>
      'Похоже на повтор другого чека в этой партии. Пропустите его, если вы выбрали одно фото дважды.';

  @override
  String batchAmountConverted(String amount, String code) {
    return '$amount $code — пересчитано';
  }

  @override
  String get scannedPleaseCheck => 'Распознано — проверьте';

  @override
  String receiptDiscrepancyCash(String labelled, String computed) {
    return 'Указанный итог $labelled расходится с расчётом «наличные − сдача» ($computed). Используем расчёт.';
  }

  @override
  String receiptDiscrepancyItems(String labelled, String itemSum) {
    return 'Итог $labelled не сходится с суммой позиций ($itemSum) — проверьте, пожалуйста.';
  }

  @override
  String get dashTotalBalance => 'Общий баланс';

  @override
  String get dashSnapshotHint => 'От этой суммы считается весь обзор.';

  @override
  String get dashStatAvailable => 'Доступно';

  @override
  String get dashStatSpentToday => 'Потрачено сегодня';

  @override
  String get dashStatTotalSpent => 'Потрачено всего';

  @override
  String get dashStatAveragePerDay => 'В среднем в день';

  @override
  String get dashRecentActivity => 'Последние операции';

  @override
  String get dashNoEntries => 'Записей пока нет. Добавьте первую кнопкой +.';

  @override
  String get budgetingWindow => 'Период бюджета';

  @override
  String get fieldStart => 'Начало';

  @override
  String get fieldEnd => 'Конец';

  @override
  String get dailyBudget => 'Бюджет на день';

  @override
  String overDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'на $count дня',
      many: 'на $count дней',
      few: 'на $count дня',
      one: 'на $count день',
    );
    return '$_temp0';
  }

  @override
  String get smartCardsTitle => 'Умные карточки';

  @override
  String get smartCardsWatching =>
      'Умные карточки следят за тратами. Сегодня с необязательными расходами всё спокойно.';

  @override
  String smartCardsSpent(String amount, int percent) {
    return 'Сегодня вы потратили $amount на мелочи — это $percent% дневного лимита.';
  }

  @override
  String smartCardsAnnualised(String amount) {
    return 'В таком темпе это $amount за год.';
  }

  @override
  String smartCardsDivert(String goal) {
    return 'Если направить их на «$goal», цель приблизится.';
  }

  @override
  String get spendingPatternTitle => 'Закономерность трат';

  @override
  String spendingPatternNight(String weekday, String tag, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Спонтанные траты чаще всего случаются $weekday вечером — в основном $tag покупки (пока $count).',
      many:
          'Спонтанные траты чаще всего случаются $weekday вечером — в основном $tag покупки (пока $count).',
      few:
          'Спонтанные траты чаще всего случаются $weekday вечером — в основном $tag покупки (пока $count).',
      one:
          'Спонтанные траты чаще всего случаются $weekday вечером — в основном $tag покупки (пока $count).',
    );
    return '$_temp0';
  }

  @override
  String spendingPatternDay(String weekday, String tag, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other:
          'Спонтанные траты чаще всего случаются $weekday днём — в основном $tag покупки (пока $count).',
      many:
          'Спонтанные траты чаще всего случаются $weekday днём — в основном $tag покупки (пока $count).',
      few:
          'Спонтанные траты чаще всего случаются $weekday днём — в основном $tag покупки (пока $count).',
      one:
          'Спонтанные траты чаще всего случаются $weekday днём — в основном $tag покупки (пока $count).',
    );
    return '$_temp0';
  }

  @override
  String get weekdayMonday => 'по понедельникам';

  @override
  String get weekdayTuesday => 'по вторникам';

  @override
  String get weekdayWednesday => 'по средам';

  @override
  String get weekdayThursday => 'по четвергам';

  @override
  String get weekdayFriday => 'по пятницам';

  @override
  String get weekdaySaturday => 'по субботам';

  @override
  String get weekdaySunday => 'по воскресеньям';

  @override
  String get smartSuggestionsTitle => 'Умные подсказки';

  @override
  String suggestionWatchCategoryTitle(String category) {
    return 'Следите за категорией «$category»';
  }

  @override
  String suggestionWatchCategoryBody(String amount) {
    return 'Это ваша самая крупная категория в этом месяце. Сокращение на 10% освободит около $amount.';
  }

  @override
  String suggestionBudgetAlertTitle(String category) {
    return 'Внимание: бюджет «$category»';
  }

  @override
  String suggestionBudgetAlertBody(int percent) {
    return 'Вы израсходовали $percent% лимита на этот месяц.';
  }

  @override
  String get suggestionAuditSubsTitle => 'Проверьте подписки';

  @override
  String suggestionAuditSubsBody(String names) {
    return 'Найдены регулярные списания: $names.';
  }

  @override
  String get suggestionTrackTitle => 'Ведите записи 7 дней';

  @override
  String get suggestionTrackBody =>
      'Добавьте записи за неделю — и здесь появятся персональные подсказки.';

  @override
  String get recurringChargesTitle => 'Регулярные списания';

  @override
  String get recurringChargesSubtitle =>
      'Найдены по ежемесячной периодичности в вашей истории.';

  @override
  String get recurringChargesEmpty =>
      'Пока ничего не найдено. Регулярные списания появятся после нескольких месячных повторов.';

  @override
  String subscriptionCharges(int count, String date) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count списания · последнее $date',
      many: '$count списаний · последнее $date',
      few: '$count списания · последнее $date',
      one: '$count списание · последнее $date',
    );
    return '$_temp0';
  }

  @override
  String perYear(String amount) {
    return '$amount/год';
  }

  @override
  String get financialCalendarTitle => 'Финансовый календарь';

  @override
  String get financialCalendarSubtitle =>
      'События, которые могут изменить темп ваших трат.';

  @override
  String get regionIndia => 'Индия';

  @override
  String get regionRussia => 'Россия';

  @override
  String eventComingSoon(String name) {
    return 'Скоро: $name';
  }

  @override
  String eventForecast(String projected, String increase) {
    return 'В этот период траты обычно растут. Прогноз — $projected в день, примерно на $increase больше обычного.';
  }

  @override
  String get eventNoHistory =>
      'Оценка по вашему общему среднему — истории за этот период пока нет.';

  @override
  String get eventToday => 'Сегодня';

  @override
  String eventDaysShort(int count) {
    return '$count дн.';
  }

  @override
  String get eventWinterExamName => 'Зимняя сессия';

  @override
  String get eventWinterExamNote =>
      'Учебные материалы, транспорт и поздние перекусы часто дорожают.';

  @override
  String get eventNewYearName => 'Новогодние праздники';

  @override
  String get eventNewYearNote =>
      'Подарки, поездки и встречи с друзьями приходятся на эти каникулы.';

  @override
  String get eventStipendName => 'Стипендиальный цикл';

  @override
  String get eventStipendNote =>
      'Регулярная дата стипендии — опора для месячного плана.';

  @override
  String get eventUniExamName => 'Экзаменационная неделя';

  @override
  String get eventUniExamNote =>
      'Печать, дорога и еда навынос обычно дорожают в сессию.';

  @override
  String get eventDiwaliName => 'Дивали';

  @override
  String get eventDiwaliNote =>
      'Подарки, поездки и праздники нагружают свободные деньги.';

  @override
  String get eventSemesterName => 'Начало семестра';

  @override
  String get eventSemesterNote =>
      'Книги, канцелярия и залог за жильё часто возвращаются к началу семестра.';

  @override
  String get eventTypeAcademic => 'Учёба';

  @override
  String get eventTypeHoliday => 'Праздники';

  @override
  String get eventTypeIncome => 'Доход';

  @override
  String get eventTypeFestival => 'Фестиваль';

  @override
  String get eventTypeStudentCosts => 'Студенческие расходы';

  @override
  String get locationGuidanceTitle => 'Подсказки по региону';

  @override
  String get locationGuidanceSubtitle =>
      'Типичные местные цены в сравнении с остатком на сегодня.';

  @override
  String get fieldRegion => 'Регион';

  @override
  String get geoUsCity => 'Город в США';

  @override
  String get geoIndiaMetro => 'Мегаполис Индии';

  @override
  String get geoEasternEurope => 'Восточная Европа';

  @override
  String get stapleLunch => 'Обед';

  @override
  String get stapleTransit => 'Проезд';

  @override
  String get stapleGroceries => 'Продукты';

  @override
  String stapleCost(String cost, String limit) {
    return 'Обычно $cost · рекомендуемый максимум $limit';
  }

  @override
  String get badgeOnBudget => 'В бюджете';

  @override
  String get badgeTrimNeeded => 'Нужно урезать';

  @override
  String get suggestionsTodayTitle => 'Подсказки на сегодня';

  @override
  String get tipOverBudget =>
      'Вы превысили дневной бюджет. До конца дня покупайте только самое необходимое.';

  @override
  String get tipFinalQuarter =>
      'У вас осталось меньше 25% дневного бюджета. Оставьте только самые важные пункты плана.';

  @override
  String get tipComfortable =>
      'Запас на сегодня комфортный. Сначала закройте необходимое, импульсивное отложите.';

  @override
  String get tipPlannedOverBudget =>
      'Запланированные траты выше бюджета. Сократите один пункт плана примерно на 20–30%.';

  @override
  String get tipAverageOverBudget =>
      'Средние дневные траты выше бюджета с учётом региона. Попробуйте три дня экономии подряд.';

  @override
  String get tipCategoryCaps =>
      'Поставьте сегодня лимиты на «Питание» и «Покупки» — это сохранит запас на завтра.';

  @override
  String get dailyPlanTitle => 'План на день';

  @override
  String get dailyPlanSubtitle =>
      'Составьте план дня и сравните его с дневным бюджетом.';

  @override
  String get dailyPlanName => 'Название плана';

  @override
  String get dailyPlanNameHint => 'Продукты и проезд';

  @override
  String dailyPlanEstimate(String code) {
    return 'Оценка ($code)';
  }

  @override
  String get dailyPlanDate => 'Дата плана';

  @override
  String get dailyPlanAdd => 'Добавить план';

  @override
  String get dailyPlanInvalid => 'Укажите название плана и корректную сумму.';

  @override
  String get dailyPlanSpentThatDay => 'Потрачено в этот день';

  @override
  String get dailyPlanPlanned => 'Запланировано';

  @override
  String get dailyPlanRemaining => 'Остаток после планов';

  @override
  String get dailyPlanEmpty => 'На этот день планов пока нет.';

  @override
  String get dailyPlanDeleteTooltip => 'Удалить план';

  @override
  String get dayRecordsTitle => 'Все дни';

  @override
  String get dayRecordsEmpty =>
      'Записей пока нет. Добавьте траты, чтобы начать историю.';

  @override
  String get goalsEmptyTitle => 'Целей по накоплениям пока нет.';

  @override
  String get goalsEmptyBody => 'Создайте первую кнопкой +.';

  @override
  String get goalsGuidanceTitle => 'Персональные рекомендации';

  @override
  String goalAmountOf(String current, String target) {
    return '$current из $target';
  }

  @override
  String goalAddAmount(String amount) {
    return 'Добавить $amount';
  }

  @override
  String get goalInsightEmpty =>
      'Добавьте несколько трат — и здесь появятся персональные рекомендации.';

  @override
  String goalInsightTopShare(String category, int percent) {
    return 'На «$category» приходится $percent% ваших трат. Сокращение здесь на 10% приблизит цели быстрее, чем экономия где-либо ещё.';
  }

  @override
  String goalInsightTopTwo(String first, String second, int percent) {
    return 'Вместе «$first» и «$second» составляют $percent% расходов.';
  }

  @override
  String get goalInsightAutomate =>
      'Автоперевод в день зарплаты защищает накопления до того, как начнутся траты.';

  @override
  String get goalInsightReviewWeekly =>
      'Разбирать по одной категории в неделю проще, чем урезать всё сразу.';

  @override
  String get chartTopCategories => 'Основные категории';

  @override
  String get chartNoExpenses => 'Трат пока нет.';

  @override
  String get chartIncomeVsExpenses => 'Доходы и расходы';

  @override
  String get chartLastSixMonths => 'Последние шесть месяцев';

  @override
  String get chartNotEnoughHistory => 'Пока мало данных.';

  @override
  String get chartLegendIncome => 'Доходы';

  @override
  String get chartLegendExpenses => 'Расходы';

  @override
  String get monthJan => 'янв';

  @override
  String get monthFeb => 'фев';

  @override
  String get monthMar => 'мар';

  @override
  String get monthApr => 'апр';

  @override
  String get monthMay => 'май';

  @override
  String get monthJun => 'июн';

  @override
  String get monthJul => 'июл';

  @override
  String get monthAug => 'авг';

  @override
  String get monthSep => 'сен';

  @override
  String get monthOct => 'окт';

  @override
  String get monthNov => 'ноя';

  @override
  String get monthDec => 'дек';

  @override
  String get entrySheetTitleAdd => 'Новая запись';

  @override
  String get entrySheetTitleCheck => 'Проверьте чек';

  @override
  String get entrySheetSubtitleAdd =>
      'Запишите расход или доход. Отметьте регулярные списания, чтобы следить за ними.';

  @override
  String get entrySheetSubtitleCheck =>
      'Считано с чека. Всё, что помечено «проверьте», — предположение; исправьте перед сохранением.';

  @override
  String get entrySheetSubmit => 'Сохранить запись';

  @override
  String get entryRecurringHint =>
      'Похоже на регулярное списание. Поставили «Ежемесячно» — измените ниже, если это не так.';

  @override
  String get entryTypeExpense => 'Расход';

  @override
  String get entryTypeIncome => 'Доход';

  @override
  String get entryFieldName => 'Название';

  @override
  String get entryFieldNameHint => 'напр. Поход в магазин';

  @override
  String entryFieldAmount(String code) {
    return 'Сумма ($code)';
  }

  @override
  String get entryFieldCategory => 'Категория';

  @override
  String get entryFieldDate => 'Дата';

  @override
  String get entryFieldNote => 'Заметка';

  @override
  String get entryFieldNoteHint => 'Любые подробности об этой записи';

  @override
  String get entryRecurringQuestion => 'Это повторяется?';

  @override
  String get entryUnplanned => 'Незапланированная / спонтанная';

  @override
  String get entryUnplannedSubtitle =>
      'Необязательный контекст: он делает подсказки полезнее и никогда не осуждает.';

  @override
  String get entryReasonPrompt => 'Что на это повлияло? Необязательно';

  @override
  String get entryInvalid => 'Укажите название и корректную сумму.';

  @override
  String get entrySaved => 'Запись сохранена.';

  @override
  String entrySavedRecurring(String cadence) {
    return 'Добавлена регулярная запись ($cadence).';
  }

  @override
  String entryConvertedFrom(String amount, String code, String target) {
    return '$amount $code пересчитано в $target';
  }

  @override
  String entryNoRate(String code) {
    return 'Чек в валюте $code — курса нет, поэтому сумма без пересчёта';
  }

  @override
  String get recurrenceNone => 'Разово';

  @override
  String get recurrenceDaily => 'Ежедневно';

  @override
  String get recurrenceWeekly => 'Еженедельно';

  @override
  String get recurrenceBiweekly => 'Раз в две недели';

  @override
  String get recurrenceMonthly => 'Ежемесячно';

  @override
  String get recurrenceYearly => 'Ежегодно';

  @override
  String get reasonEmotional => 'Эмоциональная покупка';

  @override
  String get reasonSocial => 'Компания';

  @override
  String get reasonDiscount => 'Скидка / распродажа';

  @override
  String get reasonImpulse => 'Импульс';

  @override
  String get reasonAdjEmotional => 'эмоциональные';

  @override
  String get reasonAdjSocial => 'совместные';

  @override
  String get reasonAdjDiscount => 'скидочные';

  @override
  String get reasonAdjImpulse => 'импульсивные';

  @override
  String get categoryIncome => 'Доход';

  @override
  String get categorySalary => 'Зарплата';

  @override
  String get categoryFreelance => 'Фриланс';

  @override
  String get categoryGroceries => 'Продукты';

  @override
  String get categoryTransport => 'Транспорт';

  @override
  String get categoryHousing => 'Жильё';

  @override
  String get categoryUtilities => 'Коммунальные услуги';

  @override
  String get categoryEntertainment => 'Развлечения';

  @override
  String get categoryFood => 'Питание';

  @override
  String get categoryShopping => 'Покупки';

  @override
  String get categoryHealth => 'Здоровье';

  @override
  String get categoryTravel => 'Путешествия';

  @override
  String get categoryEducation => 'Образование';

  @override
  String get categorySavings => 'Сбережения';

  @override
  String get categoryInvestment => 'Инвестиции';

  @override
  String get categoryBusiness => 'Бизнес';

  @override
  String get categoryGift => 'Подарок';

  @override
  String get categoryOther => 'Другое';

  @override
  String get goalSheetTitle => 'Цель по накоплениям';

  @override
  String get goalSheetSubtitle =>
      'Укажите сумму и срок — мы посчитаем, сколько откладывать в день.';

  @override
  String get goalSheetSubmit => 'Создать цель';

  @override
  String get goalFieldIcon => 'Значок';

  @override
  String get goalFieldName => 'Название цели';

  @override
  String get goalFieldNameHint => 'Подушка безопасности';

  @override
  String goalFieldTarget(String code) {
    return 'Цель ($code)';
  }

  @override
  String get goalFieldSaved => 'Уже накоплено';

  @override
  String get goalTimeframe => 'Срок';

  @override
  String get goalFieldDays => 'Дней';

  @override
  String get goalMinimumDays => 'минимум 7';

  @override
  String get goalInvalid => 'Укажите название цели и сумму.';

  @override
  String get goalCreated => 'Цель создана.';

  @override
  String goalReachIn(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Чтобы достичь цели за $count дня:',
      many: 'Чтобы достичь цели за $count дней:',
      few: 'Чтобы достичь цели за $count дня:',
      one: 'Чтобы достичь цели за $count день:',
    );
    return '$_temp0';
  }

  @override
  String goalPerDay(String amount) {
    return '$amount в день';
  }

  @override
  String goalPerWeekMonth(String week, String month) {
    return '$week в неделю · $month в месяц';
  }

  @override
  String get goalCurrentGoals => 'Текущие цели';

  @override
  String get periodOneMonth => '1 месяц';

  @override
  String get periodThreeMonths => '3 месяца';

  @override
  String get periodSixMonths => '6 месяцев';

  @override
  String get periodOneYear => '1 год';

  @override
  String get periodTwoYears => '2 года';

  @override
  String get periodCustom => 'Свой срок';

  @override
  String get plannerSurvivalTitle => 'Калькулятор выживания';

  @override
  String get plannerSurvivalSubtitle =>
      'Сколько можно тратить в день после обязательных расходов.';

  @override
  String get plannerDailySpendable => 'Доступно в день';

  @override
  String plannerHorizon(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: 'Горизонт планирования — $count дня',
      many: 'Горизонт планирования — $count дней',
      few: 'Горизонт планирования — $count дня',
      one: 'Горизонт планирования — $count день',
    );
    return '$_temp0';
  }

  @override
  String plannerUpcomingBills(String code) {
    return 'Обязательные платежи впереди ($code)';
  }

  @override
  String get plannerIncomeStreams => 'Источники дохода';

  @override
  String get plannerFieldSource => 'Источник';

  @override
  String get plannerFieldAmount => 'Сумма';

  @override
  String get plannerFixedCosts => 'Постоянные расходы';

  @override
  String get plannerFieldBill => 'Платёж';

  @override
  String get plannerAddFixedCost => 'Добавить постоянный расход';

  @override
  String get zoneGreen => 'Зелёная зона';

  @override
  String get zoneTight => 'Ограниченная зона';

  @override
  String get zoneCritical => 'Критическая зона';

  @override
  String get cadenceOneTime => 'Разово';

  @override
  String get cadenceWeekly => 'Еженедельно';

  @override
  String get cadenceMonthly => 'Ежемесячно';

  @override
  String get plannerSocialTitle => 'Бюджет на встречи';

  @override
  String get plannerSocialSubtitle =>
      'Оцените, как вечер с друзьями скажется на бюджете, до того как согласиться.';

  @override
  String get plannerFieldEvent => 'Событие';

  @override
  String get plannerFieldLow => 'Минимум';

  @override
  String get plannerFieldRealistic => 'Реально';

  @override
  String get plannerFieldStretch => 'Максимум';

  @override
  String get plannerAddPlan => 'Добавить план';

  @override
  String plannerSocialImpact(String amount) {
    return 'Если все реалистичные планы состоятся, в день останется $amount.';
  }

  @override
  String plannerYourShare(String date, String amount) {
    return '$date · ваша доля $amount';
  }

  @override
  String plannerYourShareSplit(String date, String amount, int count) {
    return '$date · ваша доля $amount из $count';
  }

  @override
  String plannerRange(String low, String high) {
    return 'Диапазон $low – $high';
  }

  @override
  String get plannerRunwayTitle => 'Запас по займу';

  @override
  String get plannerRunwaySubtitle =>
      'Растяните разовую сумму на весь семестр.';

  @override
  String get plannerLumpSum => 'Разовая сумма';

  @override
  String get plannerSafetyBuffer => 'Неприкосновенный запас';

  @override
  String plannerRunwayWeeks(String weeks) {
    return 'Хватит ещё на $weeks нед.';
  }

  @override
  String plannerSemesterWeeksLeft(String weeks) {
    return 'До конца семестра $weeks нед.';
  }

  @override
  String get plannerWillRunOut => ' При таком темпе деньги закончатся раньше.';

  @override
  String get plannerWeeklyBurn => 'Расход в неделю';

  @override
  String get plannerSuggestedCap => 'Рекомендуемый лимит';

  @override
  String get plannerStreakTitle => 'Серии успеха';

  @override
  String get plannerStreakSubtitle =>
      'Продержитесь в рамках плана три дня подряд и получите значок.';

  @override
  String get plannerCurrentStreak => 'Текущая серия';

  @override
  String plannerStreakDays(int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$count дня',
      many: '$count дней',
      few: '$count дня',
      one: '$count день',
    );
    return '$_temp0';
  }

  @override
  String get plannerStreakBadge => '3 дня подряд 🌸';

  @override
  String get plannerMarkedOnTrack => 'Сегодня отмечено';

  @override
  String get plannerMarkOnTrack => 'Отметить сегодняшний день';

  @override
  String get plannerStreakFooter =>
      'Никаких штрафов. Пропущенные дни просто мягко обнуляют серию.';

  @override
  String get budgetPlannerTitle => 'Планировщик бюджета';

  @override
  String get budgetDiscardTooltip => 'Удалить черновик';

  @override
  String get budgetDiscardDialogTitle => 'Удалить этот план?';

  @override
  String get budgetDiscardDialogBody =>
      'Черновик и все его позиции будут удалены.';

  @override
  String get budgetTypeTrip => 'Поездка';

  @override
  String get budgetTypeOuting => 'Вылазка';

  @override
  String get budgetTypeEvent => 'Мероприятие';

  @override
  String get budgetFieldTitle => 'Название плана';

  @override
  String get budgetFieldTitleHint => 'напр. Выходные в Сочи';

  @override
  String get budgetFieldFrom => 'С';

  @override
  String get budgetFieldTo => 'По (необязательно)';

  @override
  String get budgetSplittingBetween => 'Делим на';

  @override
  String get budgetItems => 'Позиции';

  @override
  String get budgetFieldItem => 'Позиция';

  @override
  String budgetFieldCost(String code) {
    return 'Стоимость ($code)';
  }

  @override
  String get budgetAddItemTooltip => 'Добавить позицию';

  @override
  String get budgetItemsEmpty =>
      'Добавьте позиции выше, чтобы увидеть расклад.';

  @override
  String get budgetTotal => 'Итого';

  @override
  String budgetPerPerson(int count) {
    return 'На человека ($count)';
  }

  @override
  String get budgetFinalise => 'Закрыть счёт';

  @override
  String get budgetFinalised => 'Бюджет закрыт.';

  @override
  String get budgetItemInvalid =>
      'Укажите название позиции и стоимость больше нуля.';

  @override
  String get budgetErrorNothing => 'Нечего закрывать.';

  @override
  String get budgetErrorNoTitle => 'Добавьте название плана перед закрытием.';

  @override
  String get budgetErrorNoItems =>
      'Добавьте хотя бы одну позицию, чтобы составить счёт.';

  @override
  String get budgetErrorBadDates =>
      'Дата окончания не может быть раньше даты начала.';

  @override
  String get budgetReceiptsTitle => 'Закрытые счета';

  @override
  String budgetReceiptSummary(String type, String from, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$type · $from · $count позиции',
      many: '$type · $from · $count позиций',
      few: '$type · $from · $count позиции',
      one: '$type · $from · $count позиция',
    );
    return '$_temp0';
  }

  @override
  String budgetReceiptSummaryRange(
      String type, String from, String to, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$type · $from → $to · $count позиции',
      many: '$type · $from → $to · $count позиций',
      few: '$type · $from → $to · $count позиции',
      one: '$type · $from → $to · $count позиция',
    );
    return '$_temp0';
  }

  @override
  String budgetEach(String amount) {
    return 'по $amount';
  }

  @override
  String get budgetDeleteTooltip => 'Удалить счёт';

  @override
  String get workspaceEmptyTitle => 'Соберите рабочий стол';

  @override
  String get workspaceEmptyBody =>
      'Добавьте карточки, которые хотите видеть сразу.';

  @override
  String get workspaceAddWidget => 'Добавить виджет';

  @override
  String get workspaceAddWidgetTitle => 'Добавить виджет';

  @override
  String get workspaceTitle => 'Рабочий стол';

  @override
  String get workspaceDragToReorder => 'Перетащите, чтобы изменить порядок';

  @override
  String get workspaceEditLayout => 'Изменить расположение';

  @override
  String get workspaceResize => 'Размер';

  @override
  String get workspaceClearTitle => 'Очистить рабочий стол?';

  @override
  String get workspaceClearBody =>
      'Будут удалены все виджеты, включая добавленные изображения.';

  @override
  String get sizeSmall => 'S';

  @override
  String get sizeMedium => 'M';

  @override
  String get sizeLarge => 'L';

  @override
  String get widgetTodaySnapshot => 'Сводка за день';

  @override
  String get widgetBudgetHealth => 'Состояние бюджета';

  @override
  String get widgetTopCategories => 'Основные категории';

  @override
  String get widgetGoalProgress => 'Прогресс целей';

  @override
  String get widgetSafeToSpend => 'Можно потратить';

  @override
  String get widgetSubStashJar => 'Копилка подписок';

  @override
  String get widgetBurnRateLine => 'График расходов';

  @override
  String get widgetQuickEntryPad => 'Быстрая запись';

  @override
  String get widgetWasteAuditor => 'Аудит лишних трат';

  @override
  String get widgetRoommateSync => 'Расчёты с соседями';

  @override
  String get widgetMedia => 'Изображение';

  @override
  String get widgetMangaStatus => 'Статус манги';

  @override
  String get widgetAsciiFortune => 'ASCII-предсказание';

  @override
  String get widgetChibiMascot => 'Чиби-маскот';

  @override
  String get widgetGrowthGem => 'Кристалл роста';

  @override
  String get widgetNoCategoryBudgets => 'Лимиты по категориям пока не заданы.';

  @override
  String get widgetNoGoals => 'Целей пока нет.';

  @override
  String get widgetSetBalanceFirst =>
      'Укажите баланс в разделе «Обзор», чтобы увидеть дневной лимит.';

  @override
  String get widgetSafeToSpendLabel => 'Можно потратить';

  @override
  String get widgetSubStash => 'Копилка';

  @override
  String widgetBoostsGoal(String goal) {
    return 'Пополняет «$goal»';
  }

  @override
  String widgetBoostAmount(String amount) {
    return 'Пополнить на $amount';
  }

  @override
  String get widgetEnterAmountFirst => 'Сначала введите сумму больше нуля.';

  @override
  String widgetAddedToCategory(String category) {
    return 'Добавлено в «$category».';
  }

  @override
  String get widgetAmountHint => 'Сумма';

  @override
  String get widgetNoRecurring => 'Регулярные списания пока не найдены.';

  @override
  String get widgetNoSplitPlans =>
      'Общих счетов пока нет. Закройте бюджет с числом участников больше одного.';

  @override
  String widgetOwed(String amount) {
    return 'Должны $amount';
  }

  @override
  String get widgetChooseImage => 'Выбрать изображение';

  @override
  String widgetWasteAnnual(String amount, int count) {
    String _temp0 = intl.Intl.pluralLogic(
      count,
      locale: localeName,
      other: '$amount в год за $count подписки.',
      many: '$amount в год за $count подписок.',
      few: '$amount в год за $count подписки.',
      one: '$amount в год за $count подписку.',
    );
    return '$_temp0';
  }

  @override
  String perMonth(String amount) {
    return '$amount/мес';
  }

  @override
  String get fortunePennySaved => '💰 Копейка рубль бережёт';

  @override
  String get fortuneSmallSteps => '📈 Малые шаги ведут к большому';

  @override
  String get fortuneGoalsPatience => '🎯 Цели достигаются терпением';

  @override
  String get fortuneSmartSpending => '💡 Разумные траты — спокойное будущее';

  @override
  String get fortuneInvestYourself => '🚀 Вложитесь в себя сегодня';

  @override
  String get widgetAddGoalToTrack => 'Добавьте цель, чтобы начать следить';

  @override
  String widgetSavingsProgress(int percent) {
    return 'Прогресс накоплений $percent%';
  }

  @override
  String get settingsCurrency => 'Валюта';

  @override
  String get settingsUsingFallbackRates => 'Используются резервные курсы.';

  @override
  String settingsRatesUpdated(String when) {
    return 'Курсы обновлены $when.';
  }

  @override
  String get settingsRefreshing => 'Обновляем…';

  @override
  String get settingsRefreshRates => 'Обновить курсы';

  @override
  String get settingsTheme => 'Тема';

  @override
  String get settingsTypography => 'Шрифты';

  @override
  String get settingsLanguage => 'Язык';

  @override
  String get settingsLanguageSubtitle =>
      'Применяется во всём приложении сразу.';

  @override
  String get settingsLanguageSystem => 'Как в системе';

  @override
  String get settingsFontDefault => 'Обычный';

  @override
  String get settingsFontEditorial => 'Книжный';

  @override
  String get settingsFontMono => 'Моноширинный';

  @override
  String settingsTextSize(int percent) {
    return 'Размер текста — $percent%';
  }

  @override
  String get settingsAccount => 'Аккаунт';

  @override
  String get settingsDemoMode =>
      'Демо-режим — данные остаются на этом устройстве.';

  @override
  String settingsSignedInAs(String name) {
    return 'Вы вошли как $name';
  }

  @override
  String get settingsLeaveDemo => 'Выйти из демо-режима';

  @override
  String get settingsSignOut => 'Выйти';

  @override
  String get settingsData => 'Данные';

  @override
  String get settingsResetAll => 'Сбросить все финансовые данные';

  @override
  String get settingsResetTitle => 'Сбросить всё?';

  @override
  String get settingsResetBody =>
      'Это навсегда удалит все операции, цели и бюджеты на этом устройстве. Отменить будет нельзя.';

  @override
  String get settingsDeveloper => 'Разработчику';

  @override
  String get settingsDeveloperBody =>
      'Только для отладочной сборки. Загружает фиксированный набор данных, чтобы каждому виджету было что показать.';

  @override
  String get settingsLoadSample => 'Загрузить тестовые данные';

  @override
  String get settingsSampleLoaded => 'Тестовые данные загружены.';

  @override
  String get settingsSampleCleared => 'Тестовые данные удалены.';

  @override
  String get relativeJustNow => 'только что';

  @override
  String relativeMinutesAgo(int count) {
    return '$count мин назад';
  }

  @override
  String relativeHoursAgo(int count) {
    return '$count ч назад';
  }

  @override
  String relativeDaysAgo(int count) {
    return '$count дн назад';
  }

  @override
  String get themeSoftBloom => 'Мягкий цвет';
}
