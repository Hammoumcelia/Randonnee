import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class WeatherService {
  static const String apiKey = 'bde9facfa75fc9322bbf359bee762e91';
  static const String baseUrl = 'https://api.openweathermap.org/data/2.5';

  // Méthode pour la météo actuelle (nom corrigé)
  static Future<Map<String, dynamic>> getWeather(double lat, double lon) async {
    try {
      final url = '$baseUrl/weather?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=fr';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('Erreur météo: $e');
      rethrow;
    }
  }

  // Méthode pour les prévisions
  static Future<Map<String, dynamic>> getWeatherForecast(double lat, double lon) async {
    try {
      final url = '$baseUrl/forecast?lat=$lat&lon=$lon&appid=$apiKey&units=metric&lang=fr';
      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        throw Exception('Erreur API: ${response.statusCode}');
      }
    } catch (e) {
      if (kDebugMode) print('Erreur prévisions: $e');
      rethrow;
    }
  }

  // Méthode pour les icônes météo
  static String getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'clear': return '☀️';
      case 'clouds': return '☁️';
      case 'rain': return '🌧️';
      case 'snow': return '❄️';
      case 'thunderstorm': return '⛈️';
      case 'drizzle': return '🌦️';
      default: return '🌈';
    }
  }
}