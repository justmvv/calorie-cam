// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Dutch Flemish (`nl`).
class AppLocalizationsNl extends AppLocalizations {
  AppLocalizationsNl([String locale = 'nl']) : super(locale);

  @override
  String get appTitle => 'Calorieën per foto';

  @override
  String get today => 'Vandaag';

  @override
  String get yesterday => 'Gisteren';

  @override
  String get calendar => 'Kalender';

  @override
  String get settings => 'Instellingen';

  @override
  String get takePhoto => 'Foto maken';

  @override
  String get fromGallery => 'Uit galerij';

  @override
  String get withoutPhoto => 'Zonder foto';

  @override
  String addedKcal(String kcal) {
    return 'Toegevoegd: $kcal';
  }

  @override
  String get dailyGoal => 'Dagdoel';

  @override
  String get cancel => 'Annuleren';

  @override
  String get save => 'Opslaan';

  @override
  String get add => 'Toevoegen';

  @override
  String get undo => 'Ongedaan maken';

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
    return 'E $protein · V $fat · K $carbs';
  }

  @override
  String get nothingLogged => 'Nog niets geregistreerd';

  @override
  String kcalLeft(String kcal, String macros) {
    return 'Nog $kcal · $macros';
  }

  @override
  String kcalOver(String kcal, String macros) {
    return '$kcal boven doel · $macros';
  }

  @override
  String mealDeleted(String name) {
    return '‘$name’ verwijderd';
  }

  @override
  String get portion => 'Portie';

  @override
  String get dishSearchHint => 'Gerecht of product';

  @override
  String get nothingFound => 'Niets gevonden';

  @override
  String per100g(String kcal) {
    return '$kcal per 100 g';
  }

  @override
  String get addManually => 'Handmatig toevoegen';

  @override
  String get whatsInPhoto => 'Wat staat er op de foto';

  @override
  String get searchCatalog => 'Zoeken in de catalogus';

  @override
  String get mealTime => 'Tijdstip van de maaltijd';

  @override
  String get chooseDish => 'Kies een gerecht';

  @override
  String addToDiary(String kcal) {
    return 'Toevoegen aan dagboek · $kcal';
  }

  @override
  String get recognitionFailed => 'Foto kon niet worden herkend';

  @override
  String chooseManually(String error) {
    return 'Kies het gerecht handmatig.\n$error';
  }

  @override
  String get recognizing => 'Herkennen… De eerste keer wordt het model gedownload (~23 MB).';

  @override
  String get looksLike => 'Lijkt op:';

  @override
  String get remove => 'Verwijderen';

  @override
  String saveFailed(String error) {
    return 'Opslaan mislukt: $error';
  }

  @override
  String goalLabel(int goal) {
    return 'doel $goal';
  }

  @override
  String get noEntriesThisMonth => 'Geen registraties deze maand';

  @override
  String get statAvgKcal => 'gem. kcal\nper dag';

  @override
  String get statDaysLogged => 'dagen\ngeregistreerd';

  @override
  String get statDaysOver => 'dagen\nboven doel';

  @override
  String get updateAvailable => 'Er is een nieuwe versie';

  @override
  String get update => 'Bijwerken';

  @override
  String get language => 'Taal';

  @override
  String get languageSystem => 'Systeemtaal';

  @override
  String get dailyGoalHint => 'De kleuren van de kalender-heatmap zijn relatief aan deze waarde.';

  @override
  String get categorySoup => 'Soepen';

  @override
  String get categoryMain => 'Hoofdgerechten';

  @override
  String get categoryBakery => 'Gebak en hartige snacks';

  @override
  String get categoryFastFood => 'Fastfood';

  @override
  String get categoryAsian => 'Aziatisch';

  @override
  String get categorySalad => 'Salades';

  @override
  String get categoryBreakfast => 'Ontbijt';

  @override
  String get categorySide => 'Bijgerechten';

  @override
  String get categoryBread => 'Brood';

  @override
  String get categoryDessert => 'Desserts';

  @override
  String get categoryFruit => 'Fruit';

  @override
  String get categorySnack => 'Snacks';

  @override
  String get categoryVegetable => 'Groenten';

  @override
  String get categoryDrink => 'Dranken';
}
