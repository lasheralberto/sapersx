import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:sapers/models/texts.dart';
import 'package:web/web.dart';
import 'package:flutter/foundation.dart';

class LanguageProvider with ChangeNotifier {
  late String _currentLanguage;

  LanguageProvider() {
    // Detectar idioma al inicializar
    _currentLanguage = getSystemLanguage();
  }

  String get currentLanguage => _currentLanguage;

  String getSystemLanguage() {
    var supportedLanguages =
        Texts.supportedLanguages; // Puedes añadir más luego
    final String systemLang = kIsWeb
        ? window.navigator.language.substring(0, 2).toLowerCase()
        : PlatformDispatcher.instance.locale.languageCode.toLowerCase();

    return supportedLanguages.contains(systemLang)
        ? systemLang
        : Texts.defaultLanguageIfMissing;
  }

  void toggleLanguage() {
    _currentLanguage = _currentLanguage == 'es' ? 'en' : 'es';
    notifyListeners();
  }

  void setLanguage(String lang) {
    _currentLanguage = lang;
    notifyListeners();
  }
}
