class AppConfig {
  static const apiBase = String.fromEnvironment(
    'API_BASE',
    defaultValue: 'https://www.promoff.com',
  );

  static const country = String.fromEnvironment(
    'COUNTRY',
    defaultValue: 'US',
  );

  static const currency = String.fromEnvironment(
    'CURRENCY',
    defaultValue: 'USD',
  );

  static bool get isUS => country == 'US';
  static bool get isES => country == 'ES';
}
