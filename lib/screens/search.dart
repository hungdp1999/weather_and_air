import 'package:flutter/material.dart';
import 'package:weather_aqi_app/services/weather_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final service = WeatherServiceV3();
  List<dynamic> results = [];
  bool loading = false;

  void onSearch(String q) async {
    if (q.trim().isEmpty) {
      setState(() => results = []);
      return;
    }
    setState(() => loading = true);
    try {
      final res = await service.searchLocation(q);
      setState(() => results = res);
    } catch (e) {
      debugPrint("Search err $e");
      setState(() => results = []);
    } finally {
      setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search city")),
      body: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextField(
              decoration: const InputDecoration(hintText: "Enter city name"),
              onChanged: onSearch,
            ),
            const SizedBox(height: 8),
            if (loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (_, i) {
                    final r = results[i];
                    return ListTile(
                      title: Text("${r['name']}, ${r['country'] ?? ''}"),
                      subtitle: Text("lat:${r['lat']}, lon:${r['lon']}"),
                      onTap: () => Navigator.pop(context, r),
                    );
                  }),
            )
          ],
        ),
      ),
    );
  }
}
