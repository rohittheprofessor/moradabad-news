class AppConfig {
  const AppConfig._();

  static const appName = 'Moradabad News';
  static const supportedCities = [
    'Moradabad',
    'Rampur',
    'Sambhal',
    'Amroha',
    'Bareilly',
  ];

  static const newsCategories = [
    'Local',
    'Crime',
    'Education',
    'Politics',
    'Sports',
    'Weather',
    'Jobs',
  ];

  static const categoryLabelsHi = {
    'Local': 'लोकल',
    'Crime': 'क्राइम',
    'Education': 'शिक्षा',
    'Politics': 'राजनीति',
    'Sports': 'खेल',
    'Weather': 'मौसम',
    'Jobs': 'नौकरी',
  };

  static String categoryLabel(String category, String languageCode) {
    if (languageCode == 'hi') return categoryLabelsHi[category] ?? category;
    return category;
  }
}
