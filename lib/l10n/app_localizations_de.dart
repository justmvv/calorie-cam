// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for German (`de`).
class AppLocalizationsDe extends AppLocalizations {
  AppLocalizationsDe([String locale = 'de']) : super(locale);

  @override
  String get appTitle => 'Calorie Cam';

  @override
  String get today => 'Heute';

  @override
  String get yesterday => 'Gestern';

  @override
  String get calendar => 'Kalender';

  @override
  String get settings => 'Einstellungen';

  @override
  String get takePhoto => 'Foto aufnehmen';

  @override
  String get fromGallery => 'Aus der Galerie';

  @override
  String get withoutPhoto => 'Ohne Foto';

  @override
  String addedKcal(String kcal) {
    return 'Hinzugefügt: $kcal';
  }

  @override
  String get dailyGoal => 'Tagesziel';

  @override
  String get switchCamera => 'Kamera wechseln';

  @override
  String get cancel => 'Abbrechen';

  @override
  String get save => 'Speichern';

  @override
  String get add => 'Hinzufügen';

  @override
  String get undo => 'Rückgängig';

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
    return 'E $protein · F $fat · K $carbs';
  }

  @override
  String get nothingLogged => 'Noch nichts eingetragen';

  @override
  String kcalLeft(String kcal, String macros) {
    return 'noch $kcal · $macros';
  }

  @override
  String kcalOver(String kcal, String macros) {
    return '$kcal über dem Ziel · $macros';
  }

  @override
  String mealDeleted(String name) {
    return '„$name“ gelöscht';
  }

  @override
  String get portion => 'Portion';

  @override
  String get dishSearchHint => 'Gericht oder Produkt';

  @override
  String get nothingFound => 'Nichts gefunden';

  @override
  String per100g(String kcal) {
    return '$kcal pro 100 g';
  }

  @override
  String get addManually => 'Manuell hinzufügen';

  @override
  String get whatsInPhoto => 'Was ist auf dem Foto';

  @override
  String get searchCatalog => 'Im Katalog suchen';

  @override
  String get mealTime => 'Uhrzeit der Mahlzeit';

  @override
  String get chooseDish => 'Gericht wählen';

  @override
  String addToDiary(String kcal) {
    return 'Ins Tagebuch · $kcal';
  }

  @override
  String get recognitionFailed => 'Das Foto konnte nicht erkannt werden';

  @override
  String chooseManually(String error) {
    return 'Wähle das Gericht manuell.\n$error';
  }

  @override
  String get recognizing => 'Erkennung läuft… Beim ersten Mal wird das Modell geladen (~72 MB).';

  @override
  String get looksLike => 'Sieht aus wie:';

  @override
  String get remove => 'Entfernen';

  @override
  String saveFailed(String error) {
    return 'Speichern fehlgeschlagen: $error';
  }

  @override
  String goalLabel(int goal) {
    return 'Ziel $goal';
  }

  @override
  String get noEntriesThisMonth => 'Keine Einträge in diesem Monat';

  @override
  String get statAvgKcal => 'kcal pro Tag\nim Schnitt';

  @override
  String get statDaysLogged => 'Tage\nerfasst';

  @override
  String get statDaysOver => 'Tage\nüber dem Ziel';

  @override
  String get updateAvailable => 'Eine neue Version ist verfügbar';

  @override
  String get update => 'Aktualisieren';

  @override
  String get language => 'Sprache';

  @override
  String get languageSystem => 'System';

  @override
  String get dailyGoalHint => 'Die Farben im Kalender richten sich nach diesem Wert.';

  @override
  String get categorySoup => 'Suppen';

  @override
  String get categoryMain => 'Hauptgerichte';

  @override
  String get categoryBakery => 'Gebäck';

  @override
  String get categoryFastFood => 'Fast Food';

  @override
  String get categoryAsian => 'Asiatisch';

  @override
  String get categorySalad => 'Salate';

  @override
  String get categoryBreakfast => 'Frühstück';

  @override
  String get categorySide => 'Beilagen';

  @override
  String get categoryBread => 'Brot';

  @override
  String get categoryDessert => 'Desserts';

  @override
  String get categoryFruit => 'Obst';

  @override
  String get categorySnack => 'Snacks';

  @override
  String get categoryVegetable => 'Gemüse';

  @override
  String get categoryDrink => 'Getränke';

  @override
  String get categorySweets => 'Süßigkeiten';

  @override
  String get backup => 'Datensicherung';

  @override
  String get exportBackup => 'Tagebuch exportieren';

  @override
  String lastExport(String date) {
    return 'Letzter Export: $date';
  }

  @override
  String get neverExported => 'Noch nicht exportiert — speichere eine Kopie in Google Drive';

  @override
  String get exportDownloaded => 'Sicherung unter Downloads gespeichert';

  @override
  String get exportShared => 'Sicherungsdatei erstellt';

  @override
  String exportFailed(String error) {
    return 'Export fehlgeschlagen: $error';
  }

  @override
  String get importBackup => 'Aus Datei importieren';

  @override
  String get importHint => 'Einträge werden zusammengeführt, nichts wird doppelt angelegt';

  @override
  String importDone(int added, int updated) {
    return 'Importiert: $added neu, $updated aktualisiert';
  }

  @override
  String get importInvalid => 'Diese Datei ist keine Calorie-Cam-Sicherung';

  @override
  String importFailed(String error) {
    return 'Import fehlgeschlagen: $error';
  }

  @override
  String get storagePersistent => 'Der Speicher ist vor automatischem Löschen geschützt';

  @override
  String get storageNotPersistent =>
      'Der Browser kann Daten bei Speichermangel löschen: installiere die App und exportiere regelmäßig';

  @override
  String get fileReady => 'Die Datei ist bereit';

  @override
  String get share => 'Teilen';

  @override
  String get addPhoto => 'Foto hinzufügen';

  @override
  String get lookingForSides => 'Suche nach Beilagen und weiteren Speisen auf dem Teller…';

  @override
  String get enterManually => 'Kalorien manuell eingeben';

  @override
  String get enterManuallyHint => 'Z. B. von der Verpackung';

  @override
  String get myProducts => 'Meine Produkte';

  @override
  String get mySets => 'Meine Menüs';

  @override
  String get catalogSection => 'Katalog';

  @override
  String get nutritionTitle => 'Nährwerte';

  @override
  String get productName => 'Name';

  @override
  String get per100Mode => 'pro 100 g';

  @override
  String perPortionMode(String grams) {
    return 'pro Portion ($grams)';
  }

  @override
  String get proteinLabel => 'Eiweiß';

  @override
  String get fatLabel => 'Fett';

  @override
  String get carbsLabel => 'Kohlenhydrate';

  @override
  String get saveToMyProducts => 'Unter Meine Produkte speichern';

  @override
  String get kcalRequired => 'Gib die Kalorien ein';

  @override
  String get nameRequired => 'Gib einen Namen ein';

  @override
  String get editNutrition => 'Kalorien bearbeiten';

  @override
  String get saveAsSet => 'Als Menü speichern';

  @override
  String get setName => 'Name des Menüs';

  @override
  String setSaved(String name) {
    return 'Menü „$name“ gespeichert';
  }

  @override
  String get customItem => 'Eigener Eintrag';

  @override
  String get deleteItem => 'Löschen';

  @override
  String get shareDay => 'Tag teilen';

  @override
  String get chipsHint => 'Tippen ersetzt das vorgeschlagene Gericht, Halten fügt eines hinzu';

  @override
  String versionLabel(String version, String build) {
    return 'Version $version · Build $build';
  }

  @override
  String get devBuild => 'Entwicklungsversion';

  @override
  String memoryMatch(String similarity) {
    return 'Wie beim letzten Mal · $similarity ähnlich';
  }

  @override
  String get memoryUse => 'Übernehmen';

  @override
  String get memoryTitle => 'Erkennungsgedächtnis';

  @override
  String memoryCount(int count) {
    return '$count gemerkte Fotos: daran werden deine üblichen Gerichte und Produkte erkannt';
  }

  @override
  String get memoryClear => 'Vergessen';

  @override
  String get memoryClearConfirm => 'Alle gemerkten Fotos vergessen? Das Tagebuch bleibt unverändert.';
}
