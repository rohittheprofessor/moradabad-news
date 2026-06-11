import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

final weatherRepositoryProvider = Provider<WeatherRepository>((ref) {
  return WeatherRepository();
});

final moradabadWeatherProvider = FutureProvider<WeatherReport>((ref) {
  return ref.watch(weatherRepositoryProvider).currentMoradabadWeather();
});

class WeatherRepository {
  Future<WeatherReport> currentMoradabadWeather() async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=28.8386&longitude=78.7733'
      '&current=temperature_2m,relative_humidity_2m,weather_code'
      '&daily=temperature_2m_max,temperature_2m_min'
      '&timezone=Asia%2FKolkata',
    );
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      throw Exception('Weather API failed: ${response.statusCode}');
    }
    return WeatherReport.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
  }
}

class WeatherReport {
  WeatherReport({
    required this.temperature,
    required this.humidity,
    required this.maxTemperature,
    required this.minTemperature,
  });

  final num temperature;
  final num humidity;
  final num maxTemperature;
  final num minTemperature;

  factory WeatherReport.fromJson(Map<String, dynamic> json) {
    final current = json['current'] as Map<String, dynamic>;
    final daily = json['daily'] as Map<String, dynamic>;
    return WeatherReport(
      temperature: current['temperature_2m'] as num,
      humidity: current['relative_humidity_2m'] as num,
      maxTemperature: (daily['temperature_2m_max'] as List<dynamic>).first as num,
      minTemperature: (daily['temperature_2m_min'] as List<dynamic>).first as num,
    );
  }
}
