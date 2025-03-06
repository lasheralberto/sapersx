import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sapers/components/screens/feed.dart';
import 'package:sapers/components/screens/login_dialog.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/make_api.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/theme.dart';
import 'package:sapers/models/user.dart';
import 'firebase_options.dart';
import 'package:sapers/models/auth_provider.dart' as zauth;
import 'package:sapers/models/router.dart';
import 'package:url_strategy/url_strategy.dart';
import 'package:location/location.dart';
import 'package:flutter_web_plugins/flutter_web_plugins.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //setPathUrlStrategy(); // Configura el modo path-based routing
  setUrlStrategy(const HashUrlStrategy());

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

  makePostRequest(
      'https://hook.eu2.make.com/cudppako45cwb99ovmhuuyyy63i6ssr6', {
    "user": "Inició la app",
  });

  //globalLanguage = 'es';

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ThemeNotifier()),
        ChangeNotifierProvider(create: (_) => zauth.AuthProviderSapers()),
        ChangeNotifierProvider(create: (_) => LanguageProvider()), // Añade esto
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
  LanguageProvider languageProvider = LanguageProvider();

  @override
  void initState() {
    super.initState();
    _setupAuthListener();
    WidgetsBinding.instance.addPostFrameCallback((_) => _setupLanguage());
  }

  void _setupLanguage() {
    final langProvider = context.read<LanguageProvider>();
    final systemLanguage =
        langProvider.getSystemLanguage(); // Método interno del provider
    langProvider.setLanguage(systemLanguage);
  }

  void _setupAuthListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (!mounted) return;
      final authProvider =
          Provider.of<zauth.AuthProviderSapers>(context, listen: false);
      authProvider.setUser(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer3<ThemeNotifier, zauth.AuthProviderSapers, LanguageProvider>(
      builder: (context, themeNotifier, authProvider, langProvider, child) {
        return MaterialApp.router(
          routerConfig: router,
          debugShowCheckedModeBanner: false,
          theme: AppTheme.getLightTheme(),
          darkTheme: AppTheme.getDarkTheme(),
          themeMode:
              themeNotifier.isDarkMode ? ThemeMode.dark : ThemeMode.light,
        );
      },
    );
  }
}
