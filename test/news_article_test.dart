import 'package:flutter_test/flutter_test.dart';
import 'package:moradabad_news/core/config/app_config.dart';

void main() {
  test('news categories include required Hindi-first sections', () {
    expect(AppConfig.newsCategories, containsAll(['Local', 'Crime', 'Education', 'Politics', 'Sports', 'Weather', 'Jobs']));
    expect(AppConfig.categoryLabelsHi['Local'], 'लोकल');
  });
}
