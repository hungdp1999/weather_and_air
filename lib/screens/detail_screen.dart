// lib/screens/detail_v3.dart
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'dart:math';

import 'package:weather_aqi_app/services/weather_service.dart';

class DetailV3 extends StatefulWidget {
  final Map<String, dynamic> aqiData;
  final double lat;
  final double lon;
  final WeatherServiceV3 historySource;
  const DetailV3(
      {super.key,
      required this.aqiData,
      required this.lat,
      required this.lon,
      required this.historySource});

  @override
  State<DetailV3> createState() => _DetailV3State();
}

class _DetailV3State extends State<DetailV3> {
  List<Map<String, dynamic>> history = [];
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    final now = DateTime.now().toUtc();
    final end = now.millisecondsSinceEpoch ~/ 1000;
    final start = end - 24 * 3600;
    try {
      final res = await widget.historySource
          .getAQIHistory(widget.lat, widget.lon, start, end);
      // res['list'] may be a map structure; our service returns Map -> so convert
      List<Map<String, dynamic>> list;
      if (res['list'] != null) {
        list = List<Map<String, dynamic>>.from(res['list']);
      } else {
        list = [];
      }
      setState(() {
        history = list;
        loading = false;
      });
    } catch (e) {
      debugPrint("History error $e");
      setState(() {
        history = [];
        loading = false;
      });
    }
  }

  List<FlSpot> _buildSpots() {
    if (history.isEmpty) return [];
    final sorted = List<Map<String, dynamic>>.from(history)
      ..sort((a, b) => (a['dt'] as int).compareTo(b['dt'] as int));
    final spots = <FlSpot>[];
    for (var i = 0; i < sorted.length; i++) {
      final aqiVal = (sorted[i]['main']['aqi'] as num).toDouble();
      spots.add(FlSpot(i.toDouble(), aqiVal));
    }
    return spots;
  }

  List<BarChartGroupData> _buildBarData() {
    final comp = widget.aqiData['components'] as Map<String, dynamic>? ?? {};
    final keys = ['pm2_5', 'pm10', 'o3', 'no2', 'so2', 'co'];
    final bars = <BarChartGroupData>[];
    for (int i = 0; i < keys.length; i++) {
      final v = comp[keys[i]] ?? 0;
      bars.add(BarChartGroupData(
          x: i,
          barRods: [BarChartRodData(toY: (v as num).toDouble(), width: 18)]));
    }
    return bars;
  }

  @override
  Widget build(BuildContext context) {
    final aqi = widget.aqiData['main']['aqi'] as int;
    final comp = widget.aqiData['components'] as Map<String, dynamic>? ?? {};
    final spots = _buildSpots();
    final bars = _buildBarData();

    return Scaffold(
      appBar: AppBar(title: const Text("AQI Detail Pro")),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  // header
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: _colorBy(aqi).withOpacity(.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        CircleAvatar(
                            radius: 28,
                            backgroundColor: _colorBy(aqi).withOpacity(.2),
                            child: Text("$aqi",
                                style: TextStyle(
                                    color: _colorBy(aqi),
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(_levelText(aqi) as String,
                                  style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              Text("Gợi ý: ${_suggestion(aqi)}"),
                            ])),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Line chart: AQI history
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          const Align(
                              alignment: Alignment.centerLeft,
                              child: Text("AQI 24h",
                                  style:
                                      TextStyle(fontWeight: FontWeight.w600))),
                          const SizedBox(height: 8),
                          SizedBox(
                            height: 180,
                            child: spots.isEmpty
                                ? Center(
                                    child: Text("Không có dữ liệu lịch sử"))
                                : LineChart(
                                    LineChartData(
                                        minY: 0,
                                        maxY: 6,
                                        gridData: FlGridData(show: true),
                                        titlesData: FlTitlesData(
                                          leftTitles: AxisTitles(
                                              sideTitles:
                                                  SideTitles(showTitles: true)),
                                          bottomTitles: AxisTitles(
                                              sideTitles: SideTitles(
                                                  showTitles: false)),
                                        ),
                                        lineBarsData: [
                                          LineChartBarData(
                                              spots: spots,
                                              isCurved: true,
                                              barWidth: 3,
                                              belowBarData: BarAreaData(
                                                  show: true,
                                                  color: _colorBy(aqi)
                                                      .withOpacity(.16)))
                                        ]),
                                  ),
                          )
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Bars for components
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(children: [
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Thành phần (µg/m³)",
                                style: TextStyle(fontWeight: FontWeight.w600))),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 160,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              maxY: _maxBarY(comp),
                              barGroups: bars,
                              titlesData: FlTitlesData(
                                leftTitles: AxisTitles(
                                    sideTitles: SideTitles(showTitles: true)),
                                bottomTitles: AxisTitles(
                                    sideTitles: SideTitles(
                                        showTitles: true,
                                        getTitlesWidget: (value, meta) {
                                          const labels = [
                                            'PM2.5',
                                            'PM10',
                                            'O3',
                                            'NO2',
                                            'SO2',
                                            'CO'
                                          ];
                                          final idx = value.toInt();
                                          if (idx < 0 || idx >= labels.length)
                                            return const SizedBox.shrink();
                                          return Text(labels[idx],
                                              style: const TextStyle(
                                                  fontSize: 10));
                                        })),
                              ),
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Radar-like
                  Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(children: [
                        const Align(
                            alignment: Alignment.centerLeft,
                            child: Text("Radar: overview",
                                style: TextStyle(fontWeight: FontWeight.w600))),
                        const SizedBox(height: 8),
                        SizedBox(
                            height: 200,
                            child: RadarWidget(values: _radarValues(comp))),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  double _maxBarY(Map<String, dynamic>? comp) {
    if (comp == null) return 100;
    final vals = [
      comp['pm2_5'] ?? 0,
      comp['pm10'] ?? 0,
      comp['o3'] ?? 0,
      comp['no2'] ?? 0,
      comp['so2'] ?? 0,
      comp['co'] ?? 0
    ];
    final maxv = vals
        .map((e) => (e as num).toDouble())
        .fold(0.0, (p, n) => n > p ? n : p);
    return (maxv * 1.4).clamp(10, 500);
  }

  int _levelText(int aqi) {
    return aqi;
  }

  Color _colorBy(int aqi) {
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

  String _suggestion(int aqi) {
    switch (aqi) {
      case 1:
        return "Hoạt động bình thường";
      case 2:
        return "Người nhạy cảm cân nhắc hạn chế";
      case 3:
        return "Hạn chế ngoài trời";
      case 4:
        return "Đeo khẩu trang, hạn chế ra ngoài";
      case 5:
        return "Ở trong nhà, đóng cửa";
      default:
        return "";
    }
  }

  List<double> _radarValues(Map<String, dynamic>? comp) {
    // normalize to 0..1 scale by some benchmarks
    final pm25 = (comp?['pm2_5'] ?? 0) as num;
    final pm10 = (comp?['pm10'] ?? 0) as num;
    final o3 = (comp?['o3'] ?? 0) as num;
    final no2 = (comp?['no2'] ?? 0) as num;
    final so2 = (comp?['so2'] ?? 0) as num;
    final co = (comp?['co'] ?? 0) as num;
    // benchmarks
    double norm(v, b) => (v.toDouble() / b).clamp(0.0, 1.0);
    return [
      norm(pm25, 75), // pm2.5 benchmark
      norm(pm10, 150),
      norm(o3, 200),
      norm(no2, 200),
      norm(so2, 200),
      norm(co, 10),
    ];
  }
}

class RadarWidget extends StatelessWidget {
  final List<double> values; // 0..1
  const RadarWidget({super.key, required this.values});
  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: RadarPainter(values),
      child: Container(),
    );
  }
}

class RadarPainter extends CustomPainter {
  final List<double> values;
  RadarPainter(this.values);
  @override
  void paint(Canvas canvas, Size size) {
    final paintGrid = Paint()
      ..color = Colors.grey.withOpacity(.18)
      ..style = PaintingStyle.stroke;
    final paintArea = Paint()
      ..color = Colors.indigo.withOpacity(.18)
      ..style = PaintingStyle.fill;
    final paintLine = Paint()
      ..color = Colors.indigo
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 * 0.85;
    final n = values.length;
    // draw rings
    for (int ring = 1; ring <= 4; ring++) {
      final r = radius * (ring / 4);
      canvas.drawCircle(center, r, paintGrid);
    }
    // draw spokes
    for (int i = 0; i < n; i++) {
      final angle = (pi * 2 / n) * i - pi / 2;
      final p = Offset(
          center.dx + radius * cos(angle), center.dy + radius * sin(angle));
      canvas.drawLine(center, p, paintGrid);
    }
    // draw polygon values
    final path = Path();
    for (int i = 0; i < n; i++) {
      final angle = (pi * 2 / n) * i - pi / 2;
      final r = radius * values[i];
      final p = Offset(center.dx + r * cos(angle), center.dy + r * sin(angle));
      if (i == 0)
        path.moveTo(p.dx, p.dy);
      else
        path.lineTo(p.dx, p.dy);
      // dot
      canvas.drawCircle(p, 3, paintLine);
    }
    path.close();
    canvas.drawPath(path, paintArea);
    canvas.drawPath(path, paintLine);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
