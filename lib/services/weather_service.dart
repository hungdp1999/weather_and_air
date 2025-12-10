import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class WeatherServiceV2 {
  // 🔥 Danh sách nhiều API key của bạn:
  final List<String> apiKeys = [
    "a144155263631e254fe2385ecc1adef3",
    "eefdf5b3d05447c909e93054158ee384",
    "385e945e514f14a92c3b295f37659737",
    "19a5c9460ae3629880045b378d0ccaaa",
    "65d96e20400e75bfb96f29b00d5c5d43",
    "71aa75c6da6e441485a41ff75f9d2423",
    "4ed815d0c628a3f68e284ffd55f85aa9",
  ];

  int keyIndex = 0;
  final String base = "https://api.openweathermap.org/data/2.5";

  Future<dynamic> _fetch(String url) async {
    int retryCount = 0;

    while (retryCount < apiKeys.length) {
      final apiKey = apiKeys[keyIndex];
      final finalUrl = "$url&appid=$apiKey";

      if (kDebugMode) {
        print("🔑 Using API Key[$keyIndex]");
      }
      final response = await http.get(Uri.parse(finalUrl));
      final code = response.statusCode;

      if (code == 200) {
        return jsonDecode(response.body);
      }

      if (code == 401 || code == 429) {
        keyIndex = (keyIndex + 1) % apiKeys.length;
        retryCount++;
        continue;
      }

      throw Exception("Lỗi API: $code – ${response.body}");
    }

    throw Exception("Tất cả API key đều lỗi hoặc hết hạn mức!");
  }

  Future<Map<String, dynamic>> getCurrentWeather(String city) async {
    final url = "$base/weather?q=$city&units=metric";
    return await _fetch(url);
  }

  Future<Map<String, dynamic>> getAQI(double lat, double lon) async {
    final url = "$base/air_pollution?lat=$lat&lon=$lon";
    return await _fetch(url);
  }

  Future<List<dynamic>> searchLocation(String query) async {
    final url = "http://api.openweathermap.org/geo/1.0/direct?q=$query&limit=5";
    return await _fetch(url);
  }

  // -------------------------
  // Lấy lịch sử AQI (last 24 hours)
  // -------------------------
  Future<List<Map<String, dynamic>>> getAQIHistory(
      double lat, double lon) async {
    final int now = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
    final int start = now - 24 * 3600; // 24h trước
    final url =
        "$base/air_pollution/history?lat=$lat&lon=$lon&start=$start&end=$now";
    final res = await _fetch(url);
    // res.json trả về {"coord":..., "list":[{dt:..., components:{...}, main:{aqi:...}}, ...]}
    if (res == null || res["list"] == null) return [];
    return List<Map<String, dynamic>>.from(res["list"]);
  }
}
