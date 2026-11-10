// Metro Widget IDF - paramètres communs
// Créé par : Omar Pérez - 2026-11-09 08:10

class AppConfig {
  static const primApiKey = String.fromEnvironment('PRIM_API_KEY');
  static const primBase = 'https://prim.iledefrance-mobilites.fr/marketplace';
  static const odsBase =
      'https://data.iledefrance-mobilites.fr/api/explore/v2.1/catalog/datasets';

  static const searchRadiusM = 600.0;
  static const maxZones = 4;
  static const maxRows = 6;
  static const timesPerRow = 2;
  static const refCacheDays = 7;
  static const autoRefresh = Duration(seconds: 30);

  static const appGroupId = 'group.com.omarperez.metrowidget';
  static const androidWidget = 'NextPassWidgetProvider';
  static const iosWidget = 'NextPassWidget';
  static const bgTask = 'metro-widget-refresh';
}
