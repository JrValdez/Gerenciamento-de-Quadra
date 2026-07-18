/// URL base da API. Pode ser sobrescrita em build com:
/// flutter run -d chrome --dart-define=API_URL=http://host:porta/api
const String kApiBaseUrl = String.fromEnvironment(
  'API_URL',
  defaultValue: 'http://localhost:5080/api',
);
