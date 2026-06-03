// KIT305 Assignment 4 — Interior Design Quoting App (Flutter)
// App entry point: initialises Firebase and shows the House list.
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'firebase_options.dart';
import 'screens/house_list_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // If Firebase fails to init (e.g. placeholder config), the app still runs
    // so the UI can be inspected; data operations will surface an error.
    // ignore: avoid_print
    print('Firebase init failed: $e');
  }
  runApp(const QuotingApp());
}

class QuotingApp extends StatelessWidget {
  const QuotingApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Interior Design Quoting',
      debugShowCheckedModeBanner: false,
      theme: buildAppTheme(),
      home: const HouseListScreen(),
    );
  }
}

