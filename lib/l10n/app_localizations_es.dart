// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Spanish Castilian (`es`).
class AppLocalizationsEs extends AppLocalizations {
  AppLocalizationsEs([String locale = 'es']) : super(locale);

  @override
  String get appTitle => 'Calorías por foto';

  @override
  String get today => 'Hoy';

  @override
  String get yesterday => 'Ayer';

  @override
  String get calendar => 'Calendario';

  @override
  String get settings => 'Ajustes';

  @override
  String get takePhoto => 'Hacer una foto';

  @override
  String get fromGallery => 'De la galería';

  @override
  String get withoutPhoto => 'Sin foto';

  @override
  String addedKcal(String kcal) {
    return 'Añadido: $kcal';
  }

  @override
  String get dailyGoal => 'Objetivo diario';

  @override
  String get cancel => 'Cancelar';

  @override
  String get save => 'Guardar';

  @override
  String get add => 'Añadir';

  @override
  String get undo => 'Deshacer';

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
    return 'P $protein · G $fat · HC $carbs';
  }

  @override
  String get nothingLogged => 'Aún no hay nada registrado';

  @override
  String kcalLeft(String kcal, String macros) {
    return 'Quedan $kcal · $macros';
  }

  @override
  String kcalOver(String kcal, String macros) {
    return '$kcal por encima del objetivo · $macros';
  }

  @override
  String mealDeleted(String name) {
    return '«$name» eliminado';
  }

  @override
  String get portion => 'Ración';

  @override
  String get dishSearchHint => 'Plato o producto';

  @override
  String get nothingFound => 'No se ha encontrado nada';

  @override
  String per100g(String kcal) {
    return '$kcal por 100 g';
  }

  @override
  String get addManually => 'Añadir manualmente';

  @override
  String get whatsInPhoto => '¿Qué hay en la foto?';

  @override
  String get searchCatalog => 'Buscar en el catálogo';

  @override
  String get mealTime => 'Hora de la comida';

  @override
  String get chooseDish => 'Elige un plato';

  @override
  String addToDiary(String kcal) {
    return 'Añadir al diario · $kcal';
  }

  @override
  String get recognitionFailed => 'No se pudo reconocer la foto';

  @override
  String chooseManually(String error) {
    return 'Elige el plato manualmente.\n$error';
  }

  @override
  String get recognizing => 'Reconociendo… La primera vez se descarga el modelo (~23 MB).';

  @override
  String get looksLike => 'Parece:';

  @override
  String get remove => 'Quitar';

  @override
  String saveFailed(String error) {
    return 'No se pudo guardar: $error';
  }

  @override
  String goalLabel(int goal) {
    return 'objetivo $goal';
  }

  @override
  String get noEntriesThisMonth => 'No hay registros este mes';

  @override
  String get statAvgKcal => 'kcal de media\nal día';

  @override
  String get statDaysLogged => 'días\ncon registros';

  @override
  String get statDaysOver => 'días\nsobre el objetivo';

  @override
  String get updateAvailable => 'Hay una nueva versión';

  @override
  String get update => 'Actualizar';

  @override
  String get language => 'Idioma';

  @override
  String get languageSystem => 'Como el sistema';

  @override
  String get dailyGoalHint => 'El mapa de calor del calendario se colorea en relación con este valor.';

  @override
  String get categorySoup => 'Sopas';

  @override
  String get categoryMain => 'Platos principales';

  @override
  String get categoryBakery => 'Bollería y masas';

  @override
  String get categoryFastFood => 'Comida rápida';

  @override
  String get categoryAsian => 'Asiática';

  @override
  String get categorySalad => 'Ensaladas';

  @override
  String get categoryBreakfast => 'Desayuno';

  @override
  String get categorySide => 'Guarniciones';

  @override
  String get categoryBread => 'Pan';

  @override
  String get categoryDessert => 'Postres';

  @override
  String get categoryFruit => 'Fruta';

  @override
  String get categorySnack => 'Aperitivos';

  @override
  String get categoryVegetable => 'Verduras';

  @override
  String get categoryDrink => 'Bebidas';

  @override
  String get backup => 'Copia de seguridad';

  @override
  String get exportBackup => 'Exportar diario';

  @override
  String lastExport(String date) {
    return 'Última exportación: $date';
  }

  @override
  String get neverExported => 'Aún no exportado: guarda una copia en Google Drive';

  @override
  String get exportDownloaded => 'Copia guardada en Descargas';

  @override
  String get exportShared => 'Archivo de copia creado';

  @override
  String exportFailed(String error) {
    return 'No se pudo exportar: $error';
  }

  @override
  String get importBackup => 'Importar desde archivo';

  @override
  String get importHint => 'Las entradas se combinan, sin duplicados';

  @override
  String importDone(int added, int updated) {
    return 'Importado: $added nuevas, $updated actualizadas';
  }

  @override
  String get importInvalid => 'Este archivo no es una copia de Calorie Cam';

  @override
  String importFailed(String error) {
    return 'No se pudo importar: $error';
  }

  @override
  String get storagePersistent => 'El almacenamiento está protegido contra el borrado automático';

  @override
  String get storageNotPersistent =>
      'El navegador puede borrar los datos si falta espacio: instala la app y exporta con regularidad';

  @override
  String get fileReady => 'El archivo está listo';

  @override
  String get share => 'Compartir';

  @override
  String get addPhoto => 'Añadir foto';

  @override
  String get lookingForSides => 'Buscando guarnición y otros platos…';

  @override
  String get enterManually => 'Introducir calorías manualmente';

  @override
  String get enterManuallyHint => 'Por ejemplo, de la etiqueta del envase';

  @override
  String get myProducts => 'Mis productos';

  @override
  String get mySets => 'Mis menús';

  @override
  String get catalogSection => 'Catálogo';

  @override
  String get nutritionTitle => 'Valor nutricional';

  @override
  String get productName => 'Nombre';

  @override
  String get per100Mode => 'por 100 g';

  @override
  String perPortionMode(String grams) {
    return 'por ración ($grams)';
  }

  @override
  String get proteinLabel => 'Proteínas';

  @override
  String get fatLabel => 'Grasas';

  @override
  String get carbsLabel => 'Hidratos';

  @override
  String get saveToMyProducts => 'Guardar en Mis productos';

  @override
  String get kcalRequired => 'Introduce las calorías';

  @override
  String get nameRequired => 'Introduce un nombre';

  @override
  String get editNutrition => 'Editar calorías';

  @override
  String get saveAsSet => 'Guardar como menú';

  @override
  String get setName => 'Nombre del menú';

  @override
  String setSaved(String name) {
    return 'Menú «$name» guardado';
  }

  @override
  String get customItem => 'Producto propio';

  @override
  String get deleteItem => 'Eliminar';

  @override
  String get shareDay => 'Compartir el día';

  @override
  String get chipsHint => 'Toca para cambiar el plato sugerido, mantén pulsado para añadir otro';

  @override
  String versionLabel(String version, String build) {
    return 'Versión $version · compilación $build';
  }

  @override
  String get devBuild => 'Compilación de desarrollo';
}
