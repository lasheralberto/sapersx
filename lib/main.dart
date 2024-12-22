// theme_notifier.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:sapers/components/screens/feed.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/theme.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

String globalLanguage = 'es';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    var fbOptions = FirebaseOptions(
        apiKey: DefaultFirebaseOptions.web.apiKey,
        appId: DefaultFirebaseOptions.web.appId,
        messagingSenderId: DefaultFirebaseOptions.web.messagingSenderId,
        storageBucket: DefaultFirebaseOptions.web.storageBucket,
        projectId: DefaultFirebaseOptions.web.projectId);

    await Firebase.initializeApp(options: fbOptions);
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeNotifier(),
      child: const SAPSocialApp(),
    ),
  );
}

class SAPSocialApp extends StatelessWidget {
  const SAPSocialApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeNotifier>(
      builder: (context, themeNotifier, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.light,
            useMaterial3: true,
            scaffoldBackgroundColor: AppStyles.scaffoldBackgroundColorBright,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            brightness: Brightness.dark,
            useMaterial3: true,
            scaffoldBackgroundColor: AppStyles.scaffoldBackgroundColorDar,
          ),
          themeMode:
              themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          initialRoute: '/feed', // Ruta inicial
          routes: {
            '/feed': (context) => const Feed(), // Define la ruta
          },
        );
      },
    );
  }
}
