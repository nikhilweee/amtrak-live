import 'package:flutter/material.dart';
import 'widgets/home_page.dart';
import 'services/preload_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  PreloadService().preloadAll(); // fire-and-forget, non-blocking
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
