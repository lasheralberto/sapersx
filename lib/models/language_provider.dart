import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:web/web.dart';

class LanguageProvider with ChangeNotifier {
  String _currentLanguage = 'es'; // Idioma por defecto (español)

  String get currentLanguage => _currentLanguage;

  // Método para alternar el idioma
  void toggleLanguage() {
    _currentLanguage = _currentLanguage == 'es' ? 'en' : 'es';
    notifyListeners(); // Notifica a los widgets que están escuchando este provider
  }

  String getSystemLanguageWeb(){

    return window.navigator.language;
  }

  String getSystemLanguageMobile() {
    return PlatformDispatcher.instance.locale.toLanguageTag();
  }
}
