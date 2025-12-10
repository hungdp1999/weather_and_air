import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:weather_and_air/services/weather_service.dart';
import 'package:intl/intl.dart';

class DetailScreen extends StatefulWidget {
  final Map<String, dynamic> aqiData;
  final double lat;
  final double lon;
  const DetailScreen(
      {super.key, required this.aqiData, required this.lat, required this.lon});

  @override
  State<DetailScreen> createState() => _DetailScreenState();
}

class _DetailScreenState extends State<DetailScreen> {
  final api = WeatherServiceV2();
  List<Map<String, dynamic>> history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    loadHistory();
  }

  Future<void> loadHistory() async {
    try {
      final h = await api.getAQIHistory(widget.lat, widget.lon);
      setState(() {
        history = h;
        loading = false;
      });
    } catch (e) {
      setState(() {
        history = [];
        loading = false;
      });
      debugPrint("Error loading history: $e");
    }
  }

  String levelText(int aqi) {
    switch (aqi) {
      case 1:
        return "Tốt";
      case 2:
        return "Trung bình";
      case 3:
        return "Kém";
      case 4:
        return "Xấu";
      case 5:
        return "Nguy hại";
      default:
        return "Không rõ";
    }
  }

  Color levelColor(int aqi) {
    switch (aqi) {
      case 1:
        return Colors.green;
      case 2:
        return Colors.yellow.shade700;
      case 3:
        return Colors.orange;
      case 4:
        return Colors.red;
      case 5:
        return Colors.purple;
      default:
        return Colors.grey;
    }
  }

  List<FlSpot> buildSpots() {
    if (history.isEmpty) return [];
    // sort by dt ascending
    final sorted = List<Map<String, dynamic>>.from(history)
      ..sort((a, b) => (a['dt'] as int).compareTo(b['dt'] as int));
    final spots = <FlSpot>[];
    for (int i = 0; i < sorted.length; i++) {
      final item = sorted[i];
      (item['dt'] as int).toDouble();
      final aqi = (item['main']['aqi'] as num).toDouble();
      // Use index as x to avoid big unix timestamps on axis
      spots.add(FlSpot(i.toDouble(), aqi));
    }
    return spots;
  }

  List<String> buildXLabels() {
    if (history.isEmpty) return [];
    final sorted = List<Map<String, dynamic>>.from(history)
      ..sort((a, b) => (a['dt'] as int).compareTo(b['dt'] as int));
    final fmt = DateFormat.Hms(); // hour:minute
    return sorted.map((e) {
      final dt = DateTime.fromMillisecondsSinceEpoch((e['dt'] as int) * 1000,
              isUtc: true)
          .toLocal();
      return fmt.format(dt);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final int aqi = widget.aqiData['main']['aqi'];
    final comp = widget.aqiData['components'] ?? {};

    final spots = buildSpots();
    final xLabels = buildXLabels();

    return Scaffold(
      appBar: AppBar(title: const Text("AQI Detail")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Header card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: levelColor(aqi).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: levelColor(aqi).withOpacity(0.2),
                          ),
                          child: Text("$aqi",
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: levelColor(aqi))),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(levelText(aqi),
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 6),
                              Text("Gợi ý: ${_suggestion(aqi)}",
                                  style: const TextStyle(fontSize: 13)),
                            ],
                          ),
                        )
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Chart Card
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Text("AQI (24h)",
                                style: TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.w600)),
                          ),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 180,
                            child: spots.isEmpty
                                ? const Center(
                                    child: Text("Không có dữ liệu lịch sử"))
                                : Padding(
                                    padding: const EdgeInsets.only(
                                        right: 12.0, left: 6.0),
                                    child: LineChart(
                                      LineChartData(
                                        gridData: FlGridData(
                                            show: true,
                                            drawVerticalLine: false),
                                        titlesData: FlTitlesData(
                                          leftTitles: AxisTitles(
                                              sideTitles:
                                                  SideTitles(showTitles: true)),
                                          bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                            showTitles: true,
                                            reservedSize: 30,
                                            interval: 1,
                                            getTitlesWidget: (value, meta) {
                                              final idx = value.toInt();
                                              if (idx < 0 ||
                                                  idx >= xLabels.length) {
                                                return const SizedBox.shrink();
                                              }
                                              return Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 6.0),
                                                child: Text(xLabels[idx],
                                                    style: const TextStyle(
                                                        fontSize: 10)),
                                              );
                                            },
                                          )),
                                        ),
                                        borderData: FlBorderData(show: false),
                                        minY: 0,
                                        maxY: 6,
                                        lineBarsData: [
                                          LineChartBarData(
                                            spots: spots,
                                            isCurved: true,
                                            barWidth: 3,
                                            dotData: FlDotData(show: true),
                                            belowBarData: BarAreaData(
                                                show: true,
                                                color: levelColor(aqi)
                                                    .withOpacity(0.18)),
                                          )
                                        ],
                                      ),
                                    ),
                                  ),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Components
                  Expanded(
                    child: ListView(
                      children: [
                        const Text("Chi tiết thành phần",
                            style: TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        const SizedBox(height: 8),
                        _buildComponentRow("PM2.5", comp['pm2_5']),
                        _buildComponentRow("PM10", comp['pm10']),
                        _buildComponentRow("O₃", comp['o3']),
                        _buildComponentRow("NO₂", comp['no2']),
                        _buildComponentRow("SO₂", comp['so2']),
                        _buildComponentRow("CO", comp['co']),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildComponentRow(String label, dynamic v) {
    final val = v == null ? "-" : v.toString();
    return Card(
      child: ListTile(
        title: Text(label),
        trailing: Text("$val µg/m³",
            style: const TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }

  String _suggestion(int aqi) {
    switch (aqi) {
      case 1:
        return "Không cần biện pháp đặc biệt";
      case 2:
        return "Người nhạy cảm cân nhắc hạn chế hoạt động ngoài trời";
      case 3:
        return "Hạn chế hoạt động ngoài trời nếu có bệnh hô hấp";
      case 4:
        return "Tránh hoạt động ngoài trời; đeo khẩu trang chất lượng cao";
      case 5:
        return "Nguy hại: ở trong nhà, đóng cửa sổ, dùng máy lọc";
      default:
        return "";
    }
  }
}
