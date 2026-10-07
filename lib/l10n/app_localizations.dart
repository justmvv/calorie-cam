import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_es.dart';
import 'app_localizations_nl.dart';
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
/// import 'l10n/app_localizations.dart';
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
  AppLocalizations(String locale) : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static const LocalizationsDelegate<AppLocalizations> delegate = _AppLocalizationsDelegate();

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
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    delegate,
    GlobalMaterialLocalizations.delegate,
    GlobalCupertinoLocalizations.delegate,
    GlobalWidgetsLocalizations.delegate,
  ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[Locale('en'), Locale('es'), Locale('nl'), Locale('ru')];

  /// No description provided for @appTitle.
  ///
  /// In en, this message translates to:
  /// **'Calorie Cam'**
  String get appTitle;

  /// No description provided for @today.
  ///
  /// In en, this message translates to:
  /// **'Today'**
  String get today;

  /// No description provided for @yesterday.
  ///
  /// In en, this message translates to:
  /// **'Yesterday'**
  String get yesterday;

  /// No description provided for @calendar.
  ///
  /// In en, this message translates to:
  /// **'Calendar'**
  String get calendar;

  /// No description provided for @settings.
  ///
  /// In en, this message translates to:
  /// **'Settings'**
  String get settings;

  /// No description provided for @takePhoto.
  ///
  /// In en, this message translates to:
  /// **'Take a photo'**
  String get takePhoto;

  /// No description provided for @fromGallery.
  ///
  /// In en, this message translates to:
  /// **'From gallery'**
  String get fromGallery;

  /// No description provided for @withoutPhoto.
  ///
  /// In en, this message translates to:
  /// **'Without photo'**
  String get withoutPhoto;

  /// No description provided for @addedKcal.
  ///
  /// In en, this message translates to:
  /// **'Added: {kcal}'**
  String addedKcal(String kcal);

  /// No description provided for @dailyGoal.
  ///
  /// In en, this message translates to:
  /// **'Daily goal'**
  String get dailyGoal;

  /// No description provided for @cancel.
  ///
  /// In en, this message translates to:
  /// **'Cancel'**
  String get cancel;

  /// No description provided for @save.
  ///
  /// In en, this message translates to:
  /// **'Save'**
  String get save;

  /// No description provided for @add.
  ///
  /// In en, this message translates to:
  /// **'Add'**
  String get add;

  /// No description provided for @undo.
  ///
  /// In en, this message translates to:
  /// **'Undo'**
  String get undo;

  /// No description provided for @kcalValue.
  ///
  /// In en, this message translates to:
  /// **'{value} kcal'**
  String kcalValue(int value);

  /// No description provided for @kcalUnit.
  ///
  /// In en, this message translates to:
  /// **'kcal'**
  String get kcalUnit;

  /// No description provided for @gramsValue.
  ///
  /// In en, this message translates to:
  /// **'{value} g'**
  String gramsValue(int value);

  /// No description provided for @gramsUnit.
  ///
  /// In en, this message translates to:
  /// **'g'**
  String get gramsUnit;

  /// Protein, fat, carbohydrates in grams
  ///
  /// In en, this message translates to:
  /// **'P {protein} · F {fat} · C {carbs}'**
  String macros(int protein, int fat, int carbs);

  /// No description provided for @nothingLogged.
  ///
  /// In en, this message translates to:
  /// **'Nothing logged yet'**
  String get nothingLogged;

  /// No description provided for @kcalLeft.
  ///
  /// In en, this message translates to:
  /// **'{kcal} left · {macros}'**
  String kcalLeft(String kcal, String macros);

  /// No description provided for @kcalOver.
  ///
  /// In en, this message translates to:
  /// **'{kcal} over goal · {macros}'**
  String kcalOver(String kcal, String macros);

  /// No description provided for @mealDeleted.
  ///
  /// In en, this message translates to:
  /// **'“{name}” deleted'**
  String mealDeleted(String name);

  /// No description provided for @portion.
  ///
  /// In en, this message translates to:
  /// **'Portion'**
  String get portion;

  /// No description provided for @dishSearchHint.
  ///
  /// In en, this message translates to:
  /// **'Dish or product'**
  String get dishSearchHint;

  /// No description provided for @nothingFound.
  ///
  /// In en, this message translates to:
  /// **'Nothing found'**
  String get nothingFound;

  /// No description provided for @per100g.
  ///
  /// In en, this message translates to:
  /// **'{kcal} per 100 g'**
  String per100g(String kcal);

  /// No description provided for @addManually.
  ///
  /// In en, this message translates to:
  /// **'Add manually'**
  String get addManually;

  /// No description provided for @whatsInPhoto.
  ///
  /// In en, this message translates to:
  /// **'What\'s in the photo'**
  String get whatsInPhoto;

  /// No description provided for @searchCatalog.
  ///
  /// In en, this message translates to:
  /// **'Search the catalog'**
  String get searchCatalog;

  /// No description provided for @mealTime.
  ///
  /// In en, this message translates to:
  /// **'Meal time'**
  String get mealTime;

  /// No description provided for @chooseDish.
  ///
  /// In en, this message translates to:
  /// **'Choose a dish'**
  String get chooseDish;

  /// No description provided for @addToDiary.
  ///
  /// In en, this message translates to:
  /// **'Add to diary · {kcal}'**
  String addToDiary(String kcal);

  /// No description provided for @recognitionFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t recognize the photo'**
  String get recognitionFailed;

  /// No description provided for @chooseManually.
  ///
  /// In en, this message translates to:
  /// **'Choose the dish manually.\n{error}'**
  String chooseManually(String error);

  /// No description provided for @recognizing.
  ///
  /// In en, this message translates to:
  /// **'Recognizing… The first run downloads the model (~23 MB).'**
  String get recognizing;

  /// No description provided for @looksLike.
  ///
  /// In en, this message translates to:
  /// **'Looks like:'**
  String get looksLike;

  /// No description provided for @remove.
  ///
  /// In en, this message translates to:
  /// **'Remove'**
  String get remove;

  /// No description provided for @saveFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t save: {error}'**
  String saveFailed(String error);

  /// No description provided for @goalLabel.
  ///
  /// In en, this message translates to:
  /// **'goal {goal}'**
  String goalLabel(int goal);

  /// No description provided for @noEntriesThisMonth.
  ///
  /// In en, this message translates to:
  /// **'No entries this month'**
  String get noEntriesThisMonth;

  /// No description provided for @statAvgKcal.
  ///
  /// In en, this message translates to:
  /// **'avg kcal\nper day'**
  String get statAvgKcal;

  /// No description provided for @statDaysLogged.
  ///
  /// In en, this message translates to:
  /// **'days\nlogged'**
  String get statDaysLogged;

  /// No description provided for @statDaysOver.
  ///
  /// In en, this message translates to:
  /// **'days\nover goal'**
  String get statDaysOver;

  /// No description provided for @updateAvailable.
  ///
  /// In en, this message translates to:
  /// **'A new version is available'**
  String get updateAvailable;

  /// No description provided for @update.
  ///
  /// In en, this message translates to:
  /// **'Update'**
  String get update;

  /// No description provided for @language.
  ///
  /// In en, this message translates to:
  /// **'Language'**
  String get language;

  /// No description provided for @languageSystem.
  ///
  /// In en, this message translates to:
  /// **'System'**
  String get languageSystem;

  /// No description provided for @dailyGoalHint.
  ///
  /// In en, this message translates to:
  /// **'The calendar heatmap is colored relative to this value.'**
  String get dailyGoalHint;

  /// No description provided for @categorySoup.
  ///
  /// In en, this message translates to:
  /// **'Soups'**
  String get categorySoup;

  /// No description provided for @categoryMain.
  ///
  /// In en, this message translates to:
  /// **'Mains'**
  String get categoryMain;

  /// No description provided for @categoryBakery.
  ///
  /// In en, this message translates to:
  /// **'Pastry'**
  String get categoryBakery;

  /// No description provided for @categoryFastFood.
  ///
  /// In en, this message translates to:
  /// **'Fast food'**
  String get categoryFastFood;

  /// No description provided for @categoryAsian.
  ///
  /// In en, this message translates to:
  /// **'Asian'**
  String get categoryAsian;

  /// No description provided for @categorySalad.
  ///
  /// In en, this message translates to:
  /// **'Salads'**
  String get categorySalad;

  /// No description provided for @categoryBreakfast.
  ///
  /// In en, this message translates to:
  /// **'Breakfast'**
  String get categoryBreakfast;

  /// No description provided for @categorySide.
  ///
  /// In en, this message translates to:
  /// **'Sides'**
  String get categorySide;

  /// No description provided for @categoryBread.
  ///
  /// In en, this message translates to:
  /// **'Bread'**
  String get categoryBread;

  /// No description provided for @categoryDessert.
  ///
  /// In en, this message translates to:
  /// **'Desserts'**
  String get categoryDessert;

  /// No description provided for @categoryFruit.
  ///
  /// In en, this message translates to:
  /// **'Fruit'**
  String get categoryFruit;

  /// No description provided for @categorySnack.
  ///
  /// In en, this message translates to:
  /// **'Snacks'**
  String get categorySnack;

  /// No description provided for @categoryVegetable.
  ///
  /// In en, this message translates to:
  /// **'Vegetables'**
  String get categoryVegetable;

  /// No description provided for @categoryDrink.
  ///
  /// In en, this message translates to:
  /// **'Drinks'**
  String get categoryDrink;

  /// No description provided for @backup.
  ///
  /// In en, this message translates to:
  /// **'Backup'**
  String get backup;

  /// No description provided for @exportBackup.
  ///
  /// In en, this message translates to:
  /// **'Export diary'**
  String get exportBackup;

  /// No description provided for @lastExport.
  ///
  /// In en, this message translates to:
  /// **'Last export: {date}'**
  String lastExport(String date);

  /// No description provided for @neverExported.
  ///
  /// In en, this message translates to:
  /// **'Not exported yet — save a copy to Google Drive'**
  String get neverExported;

  /// No description provided for @exportDownloaded.
  ///
  /// In en, this message translates to:
  /// **'Backup saved to Downloads'**
  String get exportDownloaded;

  /// No description provided for @exportShared.
  ///
  /// In en, this message translates to:
  /// **'Backup file created'**
  String get exportShared;

  /// No description provided for @exportFailed.
  ///
  /// In en, this message translates to:
  /// **'Export failed: {error}'**
  String exportFailed(String error);

  /// No description provided for @importBackup.
  ///
  /// In en, this message translates to:
  /// **'Import from file'**
  String get importBackup;

  /// No description provided for @importHint.
  ///
  /// In en, this message translates to:
  /// **'Entries are merged, nothing is duplicated'**
  String get importHint;

  /// No description provided for @importDone.
  ///
  /// In en, this message translates to:
  /// **'Imported: {added} new, {updated} updated'**
  String importDone(int added, int updated);

  /// No description provided for @importInvalid.
  ///
  /// In en, this message translates to:
  /// **'This file isn\'t a Calorie Cam backup'**
  String get importInvalid;

  /// No description provided for @importFailed.
  ///
  /// In en, this message translates to:
  /// **'Couldn\'t import: {error}'**
  String importFailed(String error);

  /// No description provided for @storagePersistent.
  ///
  /// In en, this message translates to:
  /// **'Storage is protected from automatic clearing'**
  String get storagePersistent;

  /// No description provided for @storageNotPersistent.
  ///
  /// In en, this message translates to:
  /// **'The browser may clear data when space runs low: install the app and export regularly'**
  String get storageNotPersistent;

  /// No description provided for @fileReady.
  ///
  /// In en, this message translates to:
  /// **'The file is ready'**
  String get fileReady;

  /// No description provided for @share.
  ///
  /// In en, this message translates to:
  /// **'Share'**
  String get share;

  /// No description provided for @addPhoto.
  ///
  /// In en, this message translates to:
  /// **'Add photo'**
  String get addPhoto;

  /// No description provided for @lookingForSides.
  ///
  /// In en, this message translates to:
  /// **'Looking for a side dish and other items on the plate…'**
  String get lookingForSides;

  /// No description provided for @enterManually.
  ///
  /// In en, this message translates to:
  /// **'Enter calories manually'**
  String get enterManually;

  /// No description provided for @enterManuallyHint.
  ///
  /// In en, this message translates to:
  /// **'E.g. from the package label'**
  String get enterManuallyHint;

  /// No description provided for @myProducts.
  ///
  /// In en, this message translates to:
  /// **'My products'**
  String get myProducts;

  /// No description provided for @mySets.
  ///
  /// In en, this message translates to:
  /// **'My sets'**
  String get mySets;

  /// No description provided for @catalogSection.
  ///
  /// In en, this message translates to:
  /// **'Catalog'**
  String get catalogSection;

  /// No description provided for @nutritionTitle.
  ///
  /// In en, this message translates to:
  /// **'Nutrition'**
  String get nutritionTitle;

  /// No description provided for @productName.
  ///
  /// In en, this message translates to:
  /// **'Name'**
  String get productName;

  /// No description provided for @per100Mode.
  ///
  /// In en, this message translates to:
  /// **'per 100 g'**
  String get per100Mode;

  /// No description provided for @perPortionMode.
  ///
  /// In en, this message translates to:
  /// **'per portion ({grams})'**
  String perPortionMode(String grams);

  /// No description provided for @proteinLabel.
  ///
  /// In en, this message translates to:
  /// **'Protein'**
  String get proteinLabel;

  /// No description provided for @fatLabel.
  ///
  /// In en, this message translates to:
  /// **'Fat'**
  String get fatLabel;

  /// No description provided for @carbsLabel.
  ///
  /// In en, this message translates to:
  /// **'Carbs'**
  String get carbsLabel;

  /// No description provided for @saveToMyProducts.
  ///
  /// In en, this message translates to:
  /// **'Save to My products'**
  String get saveToMyProducts;

  /// No description provided for @kcalRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter the calories'**
  String get kcalRequired;

  /// No description provided for @nameRequired.
  ///
  /// In en, this message translates to:
  /// **'Enter a name'**
  String get nameRequired;

  /// No description provided for @editNutrition.
  ///
  /// In en, this message translates to:
  /// **'Edit calories'**
  String get editNutrition;

  /// No description provided for @saveAsSet.
  ///
  /// In en, this message translates to:
  /// **'Save as set'**
  String get saveAsSet;

  /// No description provided for @setName.
  ///
  /// In en, this message translates to:
  /// **'Set name'**
  String get setName;

  /// No description provided for @setSaved.
  ///
  /// In en, this message translates to:
  /// **'Set “{name}” saved'**
  String setSaved(String name);

  /// No description provided for @customItem.
  ///
  /// In en, this message translates to:
  /// **'Custom item'**
  String get customItem;

  /// No description provided for @deleteItem.
  ///
  /// In en, this message translates to:
  /// **'Delete'**
  String get deleteItem;

  /// No description provided for @shareDay.
  ///
  /// In en, this message translates to:
  /// **'Share the day'**
  String get shareDay;

  /// No description provided for @chipsHint.
  ///
  /// In en, this message translates to:
  /// **'Tap to replace the suggested dish, hold to add one more'**
  String get chipsHint;
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) => <String>['en', 'es', 'nl', 'ru'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'es':
      return AppLocalizationsEs();
    case 'nl':
      return AppLocalizationsNl();
    case 'ru':
      return AppLocalizationsRu();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
