// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Russian (`ru`).
class AppLocalizationsRu extends AppLocalizations {
  AppLocalizationsRu([String locale = 'ru']) : super(locale);

  @override
  String get appTitle => 'Калории по фото';

  @override
  String get today => 'Сегодня';

  @override
  String get yesterday => 'Вчера';

  @override
  String get calendar => 'Календарь';

  @override
  String get settings => 'Настройки';

  @override
  String get takePhoto => 'Сфотографировать';

  @override
  String get fromGallery => 'Из галереи';

  @override
  String get withoutPhoto => 'Без фото';

  @override
  String addedKcal(String kcal) {
    return 'Добавлено: $kcal';
  }

  @override
  String get dailyGoal => 'Дневная норма';

  @override
  String get cancel => 'Отмена';

  @override
  String get save => 'Сохранить';

  @override
  String get add => 'Добавить';

  @override
  String get undo => 'Отменить';

  @override
  String kcalValue(int value) {
    return '$value ккал';
  }

  @override
  String get kcalUnit => 'ккал';

  @override
  String gramsValue(int value) {
    return '$value г';
  }

  @override
  String get gramsUnit => 'г';

  @override
  String macros(int protein, int fat, int carbs) {
    return 'Б $protein · Ж $fat · У $carbs';
  }

  @override
  String get nothingLogged => 'Пока ничего не записано';

  @override
  String kcalLeft(String kcal, String macros) {
    return 'Осталось $kcal · $macros';
  }

  @override
  String kcalOver(String kcal, String macros) {
    return 'Сверх нормы на $kcal · $macros';
  }

  @override
  String mealDeleted(String name) {
    return '«$name» удалено';
  }

  @override
  String get portion => 'Порция';

  @override
  String get dishSearchHint => 'Блюдо или продукт';

  @override
  String get nothingFound => 'Ничего не найдено';

  @override
  String per100g(String kcal) {
    return '$kcal на 100 г';
  }

  @override
  String get addManually => 'Добавить вручную';

  @override
  String get whatsInPhoto => 'Что на фото';

  @override
  String get searchCatalog => 'Найти в справочнике';

  @override
  String get mealTime => 'Время приёма пищи';

  @override
  String get chooseDish => 'Выберите блюдо';

  @override
  String addToDiary(String kcal) {
    return 'Добавить в дневник · $kcal';
  }

  @override
  String get recognitionFailed => 'Не удалось распознать фото';

  @override
  String chooseManually(String error) {
    return 'Выберите блюдо вручную.\n$error';
  }

  @override
  String get recognizing => 'Распознаю… При первом запуске загружается модель (~72 МБ).';

  @override
  String get looksLike => 'Похоже на:';

  @override
  String get remove => 'Убрать';

  @override
  String saveFailed(String error) {
    return 'Не удалось сохранить: $error';
  }

  @override
  String goalLabel(int goal) {
    return 'норма $goal';
  }

  @override
  String get noEntriesThisMonth => 'В этом месяце записей нет';

  @override
  String get statAvgKcal => 'ккал в среднем\nза день';

  @override
  String get statDaysLogged => 'дней\nс записями';

  @override
  String get statDaysOver => 'дней\nсверх нормы';

  @override
  String get updateAvailable => 'Вышла новая версия приложения';

  @override
  String get update => 'Обновить';

  @override
  String get language => 'Язык';

  @override
  String get languageSystem => 'Как в системе';

  @override
  String get dailyGoalHint => 'От этого значения считается насыщенность тепловой карты.';

  @override
  String get categorySoup => 'Супы';

  @override
  String get categoryMain => 'Основные';

  @override
  String get categoryBakery => 'Выпечка';

  @override
  String get categoryFastFood => 'Фастфуд';

  @override
  String get categoryAsian => 'Азия';

  @override
  String get categorySalad => 'Салаты';

  @override
  String get categoryBreakfast => 'Завтраки';

  @override
  String get categorySide => 'Гарниры';

  @override
  String get categoryBread => 'Хлеб';

  @override
  String get categoryDessert => 'Десерты';

  @override
  String get categoryFruit => 'Фрукты';

  @override
  String get categorySnack => 'Снеки';

  @override
  String get categoryVegetable => 'Овощи';

  @override
  String get categoryDrink => 'Напитки';

  @override
  String get backup => 'Резервная копия';

  @override
  String get exportBackup => 'Экспортировать дневник';

  @override
  String lastExport(String date) {
    return 'Последний экспорт: $date';
  }

  @override
  String get neverExported => 'Ещё не экспортировался — сохраните копию в Google Drive';

  @override
  String get exportDownloaded => 'Копия сохранена в «Загрузки»';

  @override
  String get exportShared => 'Файл копии создан';

  @override
  String exportFailed(String error) {
    return 'Не удалось экспортировать: $error';
  }

  @override
  String get importBackup => 'Импортировать из файла';

  @override
  String get importHint => 'Записи объединяются, дубликатов не будет';

  @override
  String importDone(int added, int updated) {
    return 'Импорт: новых $added, обновлено $updated';
  }

  @override
  String get importInvalid => 'Это не резервная копия Calorie Cam';

  @override
  String importFailed(String error) {
    return 'Не удалось импортировать: $error';
  }

  @override
  String get storagePersistent => 'Хранилище защищено от автоматической очистки';

  @override
  String get storageNotPersistent =>
      'Браузер может очистить данные при нехватке места: установите приложение и делайте экспорт';

  @override
  String get fileReady => 'Файл готов';

  @override
  String get share => 'Поделиться';

  @override
  String get addPhoto => 'Ещё фото';

  @override
  String get lookingForSides => 'Ищу гарнир и другие блюда на тарелке…';

  @override
  String get enterManually => 'Ввести калории вручную';

  @override
  String get enterManuallyHint => 'Например, с упаковки продукта';

  @override
  String get myProducts => 'Мои продукты';

  @override
  String get mySets => 'Мои наборы';

  @override
  String get catalogSection => 'Справочник';

  @override
  String get nutritionTitle => 'Пищевая ценность';

  @override
  String get productName => 'Название';

  @override
  String get per100Mode => 'на 100 г';

  @override
  String perPortionMode(String grams) {
    return 'на порцию ($grams)';
  }

  @override
  String get proteinLabel => 'Белки';

  @override
  String get fatLabel => 'Жиры';

  @override
  String get carbsLabel => 'Углеводы';

  @override
  String get saveToMyProducts => 'Сохранить в «Мои продукты»';

  @override
  String get kcalRequired => 'Укажите калории';

  @override
  String get nameRequired => 'Укажите название';

  @override
  String get editNutrition => 'Изменить калории';

  @override
  String get saveAsSet => 'Сохранить как набор';

  @override
  String get setName => 'Название набора';

  @override
  String setSaved(String name) {
    return 'Набор «$name» сохранён';
  }

  @override
  String get customItem => 'Свой продукт';

  @override
  String get deleteItem => 'Удалить';

  @override
  String get shareDay => 'Поделиться днём';

  @override
  String get chipsHint => 'Нажмите, чтобы заменить блюдо, удерживайте — чтобы добавить ещё одно';

  @override
  String versionLabel(String version, String build) {
    return 'Версия $version · сборка $build';
  }

  @override
  String get devBuild => 'Сборка для разработки';

  @override
  String memoryMatch(String similarity) {
    return 'Как в прошлый раз · сходство $similarity';
  }

  @override
  String get memoryUse => 'Взять';

  @override
  String get memoryTitle => 'Память распознавания';

  @override
  String memoryCount(int count) {
    return 'Запомнено фото: $count. По ним узнаются ваши обычные блюда и продукты';
  }

  @override
  String get memoryClear => 'Забыть';

  @override
  String get memoryClearConfirm => 'Забыть все запомненные фото? Дневник не изменится.';
}
