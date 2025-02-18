import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sapers/components/screens/feed.dart';
import 'package:sapers/components/screens/login_dialog.dart';
import 'package:sapers/models/auth_utils.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/theme.dart';
import 'package:sapers/models/user.dart';
import 'firebase_options.dart';
import 'package:sapers/models/auth_utils.dart' as zauth;
import 'package:sapers/models/router.dart';

// Variables globales
String globalLanguage = 'es';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializar Firebase
  if (kIsWeb) {
    await Firebase.initializeApp(
      options: FirebaseOptions(
        apiKey: DefaultFirebaseOptions.web.apiKey,
        appId: DefaultFirebaseOptions.web.appId,
        messagingSenderId: DefaultFirebaseOptions.web.messagingSenderId,
        storageBucket: DefaultFirebaseOptions.web.storageBucket,
        projectId: DefaultFirebaseOptions.web.projectId,
      ),
    );
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => zauth.AuthProvider()),
      ],
      child: const SAPSocialApp(),
    ),
  );
}

class SAPSocialApp extends StatefulWidget {
  const SAPSocialApp({super.key});

  @override
  State<SAPSocialApp> createState() => _SAPSocialAppState();
}

class _SAPSocialAppState extends State<SAPSocialApp> {
  @override
  void initState() {
    super.initState();
    _setupAuthListener();
  }

  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted) return;
      final authProvider =
          Provider.of<zauth.AuthProvider>(context, listen: false);
      authProvider.setUser(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeNotifier, zauth.AuthProvider>(
      builder: (context, themeNotifier, authProvider, child) {
        return MaterialApp.router(
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getLightTheme(),
          darkTheme: AppTheme.getDarkTheme(),
          themeMode:
              themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
          // home: const AuthWrapper(),
          // routes: {
          //   '/feed': (context) => Feed(user: authProvider.user),
          //   '/login': (context) => const LoginDialog(),
          // },
        );
      },
    );
  }
}
