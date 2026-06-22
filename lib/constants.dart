/// Global, app-wide constants.
/// Feature-specific constants should live closer to their feature instead.
library;

const double kHorizontalPadding = 24.0;

/// SharedPreferences keys
const String kIsOnBoardingSeen = "isOnBoardingSeen";
const String kThemeModeKey = "themeMode";
const String kAuthTokenKey = "token";

/// Backend API base URL (port 5000 per qemma-backend)
/// Android emulator: use http://10.0.2.2:5000/api
const String kApiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:5000/api',
);
