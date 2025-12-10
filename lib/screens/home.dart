import 'package:flutter/material.dart';
import 'package:weather_and_air/services/weather_service.dart';
import '../screens/detail_screen.dart';
import 'package:lottie/lottie.dart';

import 'search.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final WeatherServiceV2 api = WeatherServiceV2();

  Map<String, dynamic>? weather;
  Map<String, dynamic>? aqi;

  String city = "Hanoi";

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    debugPrint('Loading data for city: $city');
    final w = await api.getCurrentWeather(city);
    final a = await api.getAQI(w["coord"]["lat"], w["coord"]["lon"]);
    setState(() {
      weather = w;
      aqi = a;
    });
  }

  String getLottieIcon(String main) {
    switch (main.toLowerCase()) {
      case "clouds":
        return "assets/cloud.json";
      case "rain":
        return "assets/rain.json";
      case "clear":
        return "assets/sun.json";
      default:
        return "assets/cloud.json";
    }
  }

  @override
  Widget build(BuildContext context) {
    if (weather == null || aqi == null) {
      return RefreshIndicator(
        onRefresh: loadData,
        child: const Scaffold(
            body: SingleChildScrollView(
                physics: AlwaysScrollableScrollPhysics(),
                child: SizedBox(
                    height: 800,
                    width: double.infinity,
                    child: CircularProgressIndicator(
                      strokeWidth: 6,
                      color: Colors.transparent,
                    )))),
      );
    }

    final w = weather!;
    final a = aqi!["list"][0];
    final int index = a["main"]["aqi"]; // 1–5

    return Scaffold(
      appBar: AppBar(
        title: Text("Weather & AQI – $city"),
        actions: [
          IconButton(
              icon: const Icon(Icons.search),
              onPressed: () async {
                final result = await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()));
                if (result != null) {
                  city = result;
                  loadData();
                }
              })
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Lottie.asset(getLottieIcon(w["weather"][0]["main"]), height: 150),
            Text("${w["main"]["temp"]}°C",
                style: const TextStyle(fontSize: 40)),
            Text(w["weather"][0]["main"], style: const TextStyle(fontSize: 20)),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white10,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  const Text("Air Quality Index",
                      style: TextStyle(fontSize: 18)),
                  Text("AQI: $index / 5",
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.bold)),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => DetailScreen(
                                    aqiData: a,
                                    lat: weather?["coord"]["lat"],
                                    lon: weather?["coord"]["lon"],
                                  )));
                    },
                    child: const Text("View AQI Detail"),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
