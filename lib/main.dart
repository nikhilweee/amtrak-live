import 'package:flutter/material.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'widgets/home_page.dart';

void main() {
  tz.initializeTimeZones();
  runApp(const AmtrakLiveApp());
}

class AmtrakLiveApp extends StatelessWidget {
  const AmtrakLiveApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Amtrak Live',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blue,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: ThemeMode.system,
      home: const HomePage(),
    );
  }
}
