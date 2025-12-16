class Environment {
  static const String productionApiUrl =
      'https://hospital-search-api.onrender.com';

  static const String developmentApiUrl = 'http://localhost:3000/api';

  static const String stagingApiUrl =
      'https://hospital-search-staging.onrender.com/api';

  // Get API base URL based on environment
  static String getApiUrl({bool isDevelopment = false}) {
    if (isDevelopment) {
      return developmentApiUrl;
    }
    return productionApiUrl;
  }

  // App Configuration
  static const String appName = 'Hospital Finder';
  static const String appVersion = '1.0.0';

  // API Timeouts (in seconds)
  static const int apiTimeout = 30;

  // Cache Duration (in minutes)
  static const int cacheDuration = 60;

  // Google Maps API Key
  static const String googleMapsApiKey = 'YOUR_GOOGLE_MAPS_API_KEY';
}
