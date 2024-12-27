import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:sapers/components/screens/feed.dart';
import 'package:sapers/components/screens/login_dialog.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/theme.dart';
import 'package:sapers/models/user.dart';
import 'firebase_options.dart';

// Variables globales
String globalLanguage = 'es';

// Provider para manejar el estado de autenticación
class AuthProvider with ChangeNotifier {
  User? _user;
  UserInfoPopUp? _userInfo;
  bool _isLoading = false;

  User? get user => _user;
  UserInfoPopUp? get userInfo => _userInfo;
  bool get isLoading => _isLoading;

  void setUser(User? user) {
    if (_user != user) {
      _user = user;
      notifyListeners();
      if (user != null) {
        refreshUserInfo();
      } else {
        setUserInfo(null);
      }
    }
  }

  void setUserInfo(UserInfoPopUp? userInfo) {
    if (_userInfo != userInfo) {
      _userInfo = userInfo;
      notifyListeners();
    }
  }

  void setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  Future<void> refreshUserInfo() async {
    if (_user != null) {
      try {
        setLoading(true);
        final userInfo =
            await FirebaseService().getUserInfoByEmail(_user!.email!);
        setUserInfo(userInfo);
      } catch (e) {
        print('Error refreshing user info: $e');
      } finally {
        setLoading(false);
      }
    }
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      setUser(null);
    } catch (e) {
      print('Error signing outt: $e');
    }
  }

  Future<void> loadUserInfo(User user) async {
    if (_userInfo == null) {
      _userInfo = await FirebaseService().getUserInfoByEmail(user.email!);
      notifyListeners();
    }
  }
}

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
        ChangeNotifierProvider(create: (_) => AuthProvider()),
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
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      authProvider.setUser(user);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer2<ThemeNotifier, AuthProvider>(
      builder: (context, themeNotifier, authProvider, child) {
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
          home: const AuthWrapper(),
          routes: {
            '/feed': (context) => Feed(user: authProvider.user),
            '/login': (context) => const LoginDialog(),
          },
        );
      },
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<void> _showLoginDialog(BuildContext context) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const LoginDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        // Si el usuario no está autenticado, mostrar Feed con opción de login
        if (authProvider.user == null) {
          return Feed(
            user: null,
            onLoginRequired: () => _showLoginDialog(context),
          );
        }

        // Si el usuario está autenticado pero no tiene información de perfil
        if (authProvider.userInfo == null) {
          return const Center(child: CircularProgressIndicator());
        }

        // Usuario autenticado y con información de perfil
        return Feed(user: authProvider.user);
      },
    );
  }
}
