// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Calorie Cam';

  @override
  String get today => 'Today';

  @override
  String get yesterday => 'Yesterday';

  @override
  String get calendar => 'Calendar';

  @override
  String get settings => 'Settings';

  @override
  String get takePhoto => 'Take a photo';

  @override
  String get fromGallery => 'From gallery';

  @override
  String get withoutPhoto => 'Without photo';

  @override
  String addedKcal(String kcal) {
    return 'Added: $kcal';
  }

  @override
  String get dailyGoal => 'Daily goal';

  @override
  String get cancel => 'Cancel';

  @override
  String get save => 'Save';

  @override
  String get add => 'Add';

  @override
  String get undo => 'Undo';

  @override
  String kcalValue(int value) {
    return '$value kcal';
  }

  @override
  String get kcalUnit => 'kcal';

  @override
  String gramsValue(int value) {
    return '$value g';
  }

  @override
  String get gramsUnit => 'g';

  @override
  String macros(int protein, int fat, int carbs) {
    return 'P $protein · F $fat · C $carbs';
  }

  @override
  String get nothingLogged => 'Nothing logged yet';

  @override
  String kcalLeft(String kcal, String macros) {
    return '$kcal left · $macros';
  }

  @override
  String kcalOver(String kcal, String macros) {
    return '$kcal over goal · $macros';
  }

  @override
  String mealDeleted(String name) {
    return '“$name” deleted';
  }

  @override
  String get portion => 'Portion';

  @override
  String get dishSearchHint => 'Dish or product';

  @override
  String get nothingFound => 'Nothing found';

  @override
  String per100g(String kcal) {
    return '$kcal per 100 g';
  }

  @override
  String get addManually => 'Add manually';

  @override
  String get whatsInPhoto => 'What\'s in the photo';

  @override
  String get searchCatalog => 'Search the catalog';

  @override
  String get mealTime => 'Meal time';

  @override
  String get chooseDish => 'Choose a dish';

  @override
  String addToDiary(String kcal) {
    return 'Add to diary · $kcal';
  }

  @override
  String get recognitionFailed => 'Couldn\'t recognize the photo';

  @override
  String chooseManually(String error) {
    return 'Choose the dish manually.\n$error';
  }

  @override
  String get recognizing => 'Recognizing… The first run downloads the model (~23 MB).';

  @override
  String get looksLike => 'Looks like:';

  @override
  String get remove => 'Remove';

  @override
  String saveFailed(String error) {
    return 'Couldn\'t save: $error';
  }

  @override
  String goalLabel(int goal) {
    return 'goal $goal';
  }

  @override
  String get noEntriesThisMonth => 'No entries this month';

  @override
  String get statAvgKcal => 'avg kcal\nper day';

  @override
  String get statDaysLogged => 'days\nlogged';

  @override
  String get statDaysOver => 'days\nover goal';

  @override
  String get updateAvailable => 'A new version is available';

  @override
  String get update => 'Update';

  @override
  String get language => 'Language';

  @override
  String get languageSystem => 'System';

  @override
  String get dailyGoalHint => 'The calendar heatmap is colored relative to this value.';

  @override
  String get categorySoup => 'Soups';

  @override
  String get categoryMain => 'Mains';

  @override
  String get categoryBakery => 'Pastry';

  @override
  String get categoryFastFood => 'Fast food';

  @override
  String get categoryAsian => 'Asian';

  @override
  String get categorySalad => 'Salads';

  @override
  String get categoryBreakfast => 'Breakfast';

  @override
  String get categorySide => 'Sides';

  @override
  String get categoryBread => 'Bread';

  @override
  String get categoryDessert => 'Desserts';

  @override
  String get categoryFruit => 'Fruit';

  @override
  String get categorySnack => 'Snacks';

  @override
  String get categoryVegetable => 'Vegetables';

  @override
  String get categoryDrink => 'Drinks';

  @override
  String get backup => 'Backup';

  @override
  String get exportBackup => 'Export diary';

  @override
  String lastExport(String date) {
    return 'Last export: $date';
  }

  @override
  String get neverExported => 'Not exported yet — save a copy to Google Drive';

  @override
  String get exportDownloaded => 'Backup saved to Downloads';

  @override
  String get exportShared => 'Backup file created';

  @override
  String exportFailed(String error) {
    return 'Export failed: $error';
  }

  @override
  String get importBackup => 'Import from file';

  @override
  String get importHint => 'Entries are merged, nothing is duplicated';

  @override
  String importDone(int added, int updated) {
    return 'Imported: $added new, $updated updated';
  }

  @override
  String get importInvalid => 'This file isn\'t a Calorie Cam backup';

  @override
  String importFailed(String error) {
    return 'Couldn\'t import: $error';
  }

  @override
  String get storagePersistent => 'Storage is protected from automatic clearing';

  @override
  String get storageNotPersistent =>
      'The browser may clear data when space runs low: install the app and export regularly';

  @override
  String get fileReady => 'The file is ready';

  @override
  String get share => 'Share';
}
