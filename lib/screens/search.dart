import 'package:flutter/material.dart';
import 'package:weather_and_air/services/weather_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final api = WeatherServiceV2();
  List<dynamic> results = [];

  void search(String text) async {
    if (text.isEmpty) return;
    results = await api.searchLocation(text);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Search City")),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: const InputDecoration(hintText: "Enter city name"),
              onChanged: search,
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: results.length,
              itemBuilder: (_, i) {
                final item = results[i];
                return ListTile(
                  title: Text(item["name"]),
                  subtitle: Text("${item["lat"]}, ${item["lon"]}"),
                  onTap: () => Navigator.pop(context, item["name"]),
                );
              },
            ),
          )
        ],
      ),
    );
  }
}
