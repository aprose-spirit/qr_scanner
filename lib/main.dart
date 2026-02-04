import 'package:flutter/material.dart';
import 'models/scan_entry.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'login_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ This works on Web AND Android
  await Hive.initFlutter();
  Hive.registerAdapter(ScanEntryAdapter());
  await Hive.openBox<ScanEntry>('scans');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QR Scanner System',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const LoginScreen(),
    );
  }
}
