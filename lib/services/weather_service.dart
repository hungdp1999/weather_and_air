// lib/services/weather_service_v3.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class WeatherServiceV3 {
  WeatherServiceV3();

  // Read all environment variables that start with `API_KEY_`, e.g. API_KEY_1
  List<String> get _keys {
    final names =
        dotenv.env.keys.where((k) => k.startsWith('API_KEY_')).toList()..sort();
    final vals = names
        .map((n) => dotenv.env[n] ?? '')
        .where((s) => s.isNotEmpty)
        .toList();
    return vals;
  }

  int _idx = 0;
  final String base = "https://api.openweathermap.org/data/2.5";

  Future<dynamic> _fetchUrl(String url) async {
    final keys = _keys;
    if (keys.isEmpty) {
      throw Exception('No API keys found in .env (API_KEY_1, API_KEY_2, ...).');
    }

    int tried = 0;
    while (tried < keys.length) {
      final k = keys[_idx];
      final full = "$url&appid=$k";
      final r = await http.get(Uri.parse(full));
      if (r.statusCode == 200) {
        return jsonDecode(r.body);
      }
      if (r.statusCode == 401 || r.statusCode == 429) {
        // rotate key
        _idx = (_idx + 1) % keys.length;
        tried++;
        continue;
      }
      throw Exception("API error ${r.statusCode}: ${r.body}");
    }
    throw Exception("All API keys failed or rate-limited.");
  }

  // Current weather by city
  Future<Map<String, dynamic>> getCurrentWeather(String city) async {
    final url = "$base/weather?q=$city&units=metric";
    return Map<String, dynamic>.from(await _fetchUrl(url));
  }

  // OneCall (hourly/daily) by lat/lon
  Future<Map<String, dynamic>> getOneCall(double lat, double lon) async {
    // exclude minutely for smaller payload
    final url =
        "$base/onecall?lat=$lat&lon=$lon&units=metric&exclude=minutely&lang=vi";
    return Map<String, dynamic>.from(await _fetchUrl(url));
  }

  // Air pollution current
  Future<Map<String, dynamic>> getAQI(double lat, double lon) async {
    final url = "$base/air_pollution?lat=$lat&lon=$lon";
    return Map<String, dynamic>.from(await _fetchUrl(url));
  }

  // Air pollution history (start/end unix)
  Future<Map<String, dynamic>> getAQIHistory(
      double lat, double lon, int start, int end) async {
    final url =
        "$base/air_pollution/history?lat=$lat&lon=$lon&start=$start&end=$end";
    return Map<String, dynamic>.from(await _fetchUrl(url));
  }

  // Geocoding
  Future<List<dynamic>> searchLocation(String q) async {
    final url = "http://api.openweathermap.org/geo/1.0/direct?q=$q&limit=6";
    return await _fetchUrl(url);
  }
}
