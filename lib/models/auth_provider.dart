// Provider para manejar el estado de autenticación
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/screens/feed.dart';
import 'package:sapers/components/screens/login_dialog.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/styles.dart';

class AuthProviderSapers with ChangeNotifier {
  User? _user;
  UserInfoPopUp? _userInfo;
  bool _isLoading = false;

  // 2. Getters públicos
  User? get user => _user;
  UserInfoPopUp? get userInfo => _userInfo; // Getter crítico
  bool get isLoading => _isLoading;
  bool get isLoggedIn => _user != null;

  AuthProviderSapers() {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      setUser(user);
    });
  }

  showLoginDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const LoginScreen(),
    );
  }

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
      } finally {
        setLoading(false);
      }
    }
  }

  static buildLoginButton(BuildContext context, String keyText) {
    return Center(
      child: ElevatedButton(
        onPressed: () {
          // Aquí puedes abrir el login dialog o navegar a login
          Provider.of<AuthProviderSapers>(context, listen: false)
              .showLoginDialog(context);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppStyles.colorAvatarBorder,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
          elevation: 0,
        ),
        child: Text(
          Texts.translate(keyText, LanguageProvider().currentLanguage),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
      ),
    );
  }

  Future<void> signOut() async {
    try {
      await FirebaseAuth.instance.signOut();
      setUser(null);
    } catch (e) {}
  }

  Future<void> loadUserInfo(User user) async {
    if (_userInfo == null) {
      _userInfo = await FirebaseService().getUserInfoByEmail(user.email!);
      notifyListeners();
    }
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  Future<void> _showLoginDialog(BuildContext context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
//progressIndicatorButton
    return Consumer<AuthProviderSapers>(
      builder: (context, authProvider, child) {
        if (authProvider.isLoading) {
          return Center(child: AppStyles().progressIndicatorButton(context));
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
          return Center(child: AppStyles().progressIndicatorButton(context));
        }

        // Usuario autenticado y con información de perfil
        return Feed(user: authProvider.user);
      },
    );
  }
}
