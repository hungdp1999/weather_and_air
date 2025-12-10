import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:weather_aqi_app/screens/home.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  runApp(const WeatherProApp());
}

class WeatherProApp extends StatelessWidget {
  const WeatherProApp({super.key});
  @override
  Widget build(BuildContext context) {
    final cs = ColorScheme.fromSeed(seedColor: Colors.indigo);
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Weather Pro',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: cs,
        textTheme: GoogleFonts.interTextTheme(),
        scaffoldBackgroundColor: cs.background,
        appBarTheme: AppBarTheme(
          backgroundColor: cs.surface,
          foregroundColor: cs.onSurface,
          elevation: 0,
          centerTitle: true,
        ),
      ),
      home: const HomeV3(),
    );
  }
}
