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
  String get switchCamera => 'Camera wisselen';

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
  String get recognizing => 'Herkennen… De eerste keer wordt het model gedownload (~72 MB).';

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

  @override
  String get categorySweets => 'Snoep';

  @override
  String get backup => 'Back-up';

  @override
  String get exportBackup => 'Dagboek exporteren';

  @override
  String lastExport(String date) {
    return 'Laatste export: $date';
  }

  @override
  String get neverExported => 'Nog niet geëxporteerd — bewaar een kopie in Google Drive';

  @override
  String get exportDownloaded => 'Back-up opgeslagen in Downloads';

  @override
  String get exportShared => 'Back-upbestand gemaakt';

  @override
  String exportFailed(String error) {
    return 'Exporteren mislukt: $error';
  }

  @override
  String get importBackup => 'Importeren uit bestand';

  @override
  String get importHint => 'Items worden samengevoegd, zonder dubbele';

  @override
  String importDone(int added, int updated) {
    return 'Geïmporteerd: $added nieuw, $updated bijgewerkt';
  }

  @override
  String get importInvalid => 'Dit bestand is geen back-up van Calorie Cam';

  @override
  String importFailed(String error) {
    return 'Importeren mislukt: $error';
  }

  @override
  String get storagePersistent => 'Opslag is beschermd tegen automatisch wissen';

  @override
  String get storageNotPersistent =>
      'De browser kan gegevens wissen bij te weinig ruimte: installeer de app en exporteer regelmatig';

  @override
  String get fileReady => 'Het bestand is klaar';

  @override
  String get share => 'Delen';

  @override
  String get addPhoto => 'Foto toevoegen';

  @override
  String get lookingForSides => 'Bijgerecht en andere items zoeken…';

  @override
  String get enterManually => 'Calorieën handmatig invoeren';

  @override
  String get enterManuallyHint => 'Bijvoorbeeld van het etiket';

  @override
  String get myProducts => 'Mijn producten';

  @override
  String get mySets => 'Mijn sets';

  @override
  String get catalogSection => 'Catalogus';

  @override
  String get nutritionTitle => 'Voedingswaarde';

  @override
  String get productName => 'Naam';

  @override
  String get per100Mode => 'per 100 g';

  @override
  String perPortionMode(String grams) {
    return 'per portie ($grams)';
  }

  @override
  String get proteinLabel => 'Eiwit';

  @override
  String get fatLabel => 'Vet';

  @override
  String get carbsLabel => 'Koolhydraten';

  @override
  String get saveToMyProducts => 'Opslaan in Mijn producten';

  @override
  String get kcalRequired => 'Vul de calorieën in';

  @override
  String get nameRequired => 'Vul een naam in';

  @override
  String get editNutrition => 'Calorieën bewerken';

  @override
  String get saveAsSet => 'Opslaan als set';

  @override
  String get setName => 'Naam van de set';

  @override
  String setSaved(String name) {
    return 'Set ‘$name’ opgeslagen';
  }

  @override
  String get customItem => 'Eigen product';

  @override
  String get deleteItem => 'Verwijderen';

  @override
  String get shareDay => 'Dag delen';

  @override
  String get chipsHint => 'Tik om het voorgestelde gerecht te vervangen, houd vast om er een toe te voegen';

  @override
  String versionLabel(String version, String build) {
    return 'Versie $version · build $build';
  }

  @override
  String get devBuild => 'Ontwikkelversie';

  @override
  String memoryMatch(String similarity) {
    return 'Zoals vorige keer · $similarity gelijk';
  }

  @override
  String get memoryUse => 'Gebruiken';

  @override
  String get memoryTitle => 'Herkenningsgeheugen';

  @override
  String memoryCount(int count) {
    return 'Onthouden foto\'s: $count. Daarmee worden je vaste maaltijden en producten herkend';
  }

  @override
  String get memoryClear => 'Vergeten';

  @override
  String get memoryClearConfirm => 'Alle onthouden foto\'s vergeten? Het dagboek blijft zoals het is.';
}
