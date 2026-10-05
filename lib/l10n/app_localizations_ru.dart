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
  String get recognizing => 'Распознаю… При первом запуске загружается модель (~23 МБ).';

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
}
