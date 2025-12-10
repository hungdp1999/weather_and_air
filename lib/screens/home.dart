import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:weather_aqi_app/screens/detail_screen.dart';
import 'package:weather_aqi_app/screens/search.dart';
import 'package:weather_aqi_app/services/weather_service.dart';

class HomeV3 extends StatefulWidget {
  const HomeV3({super.key});
  @override
  State<HomeV3> createState() => _HomeV3State();
}

class _HomeV3State extends State<HomeV3> {
  final service = WeatherServiceV3();
  Map<String, dynamic>? weather;
  Map<String, dynamic>? onecall;
  Map<String, dynamic>? aqi;
  String city = "Hanoi";
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadAll(city);
  }

  Future<void> _loadAll(String cityName) async {
    setState(() {
      loading = true;
    });
    try {
      final w = await service.getCurrentWeather(cityName);
      final lat = (w['coord']['lat'] as num).toDouble();
      final lon = (w['coord']['lon'] as num).toDouble();
      final oc = await service.getOneCall(lat, lon);
      final a = await service.getAQI(lat, lon);
      setState(() {
        weather = w;
        onecall = oc;
        aqi = a;
        city = cityName;
        loading = false;
      });
    } catch (e) {
      setState(() {
        loading = false;
      });
      debugPrint("Load error $e");
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Lỗi: $e")));
    }
  }

  String _bgGradientBy(String main) {
    final m = main.toLowerCase();
    if (m.contains('cloud')) return 'cloud';
    if (m.contains('rain')) return 'rain';
    if (m.contains('clear')) return 'clear';
    return 'default';
  }

  Widget _buildWeatherCard() {
    if (weather == null || onecall == null) return const SizedBox.shrink();
    final w = weather!;
    final main = w['weather'][0]['main'] as String;
    final temp = (w['main']['temp']).toString();
    // final icon = w['weather'][0]['icon'] as String;
    final a = aqi?['list'] != null ? aqi!['list'][0] : null;
    final aqiIndex = a != null ? a['main']['aqi'] as int : null;
    final gradient = _bgGradientBy(main);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 600),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: gradient == 'clear'
            ? LinearGradient(
                colors: [Colors.orange.shade200, Colors.indigo.shade200])
            : gradient == 'rain'
                ? LinearGradient(
                    colors: [Colors.blueGrey.shade700, Colors.blue.shade400])
                : LinearGradient(
                    colors: [Colors.grey.shade800, Colors.blueGrey.shade600]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 12, offset: Offset(0, 6))
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 120,
            height: 120,
            child: Lottie.asset(
              main.toLowerCase().contains('rain')
                  ? 'assets/rain.json'
                  : main.toLowerCase().contains('clear')
                      ? 'assets/sun.json'
                      : 'assets/cloud.json',
              fit: BoxFit.contain,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(city,
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.w700)),
                const SizedBox(height: 6),
                Text("$temp°C",
                    style: const TextStyle(
                        fontSize: 44, fontWeight: FontWeight.w800)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    if (aqiIndex != null) Chip(label: Text("AQI: $aqiIndex")),
                    const SizedBox(width: 8),
                    Text(w['weather'][0]['description'],
                        style: const TextStyle(fontSize: 14)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildHourlyStrip() {
    final hours = onecall?['hourly'] as List<dynamic>? ?? [];
    final toShow = hours.take(12).toList();
    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: toShow.length,
        itemBuilder: (_, i) {
          final it = toShow[i];
          final dt = DateTime.fromMillisecondsSinceEpoch(
                  (it['dt'] as int) * 1000,
                  isUtc: true)
              .toLocal();
          final temp = (it['temp'] as num).round();
          final icon = it['weather'][0]['icon'];
          return Container(
            width: 78,
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text("${dt.hour}:00"),
                const SizedBox(height: 6),
                // small lottie or icon fallback
                Image.network("https://openweathermap.org/img/wn/$icon@2x.png",
                    width: 36, height: 36),
                const SizedBox(height: 6),
                Text("$temp°C"),
              ],
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Weather Pro'),
        actions: [
          IconButton(
              onPressed: () async {
                final res = await Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const SearchScreen()));
                if (res != null && res is Map<String, dynamic>) {
                  final cityName = res['name'] as String;
                  _loadAll(cityName);
                }
              },
              icon: const Icon(Icons.search)),
          IconButton(
              onPressed: () {
                if (weather == null) return;
                final lat = (weather!['coord']['lat'] as num).toDouble();
                final lon = (weather!['coord']['lon'] as num).toDouble();
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => DetailV3(
                              aqiData: aqi!['list'][0],
                              lat: lat,
                              lon: lon,
                              historySource: service,
                            )));
              },
              icon: const Icon(Icons.info_outline)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadAll(city),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildWeatherCard(),
                  const SizedBox(height: 16),
                  const Text("Hourly",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  _buildHourlyStrip(),
                  const SizedBox(height: 16),
                  const Text("7-day forecast",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  ..._buildDailyCards(),
                ],
              ),
      ),
    );
  }

  List<Widget> _buildDailyCards() {
    final days = onecall?['daily'] as List<dynamic>? ?? [];
    return days.take(7).map((d) {
      final dt = DateTime.fromMillisecondsSinceEpoch((d['dt'] as int) * 1000,
              isUtc: true)
          .toLocal();
      final min = (d['temp']['min'] as num).round();
      final max = (d['temp']['max'] as num).round();
      final icon = d['weather'][0]['icon'];
      return Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: ListTile(
          leading: Image.network("https://openweathermap.org/img/wn/$icon.png"),
          title: Text("${dt.weekdayString()}"),
          subtitle: Text("${d['weather'][0]['description']}"),
          trailing: Text("$max° / $min°"),
        ),
      );
    }).toList();
  }
}

extension WeekdayExt on DateTime {
  String weekdayString() {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[this.weekday - 1];
  }
}
