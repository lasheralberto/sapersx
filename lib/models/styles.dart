import 'package:flutter/material.dart';

import 'package:flutter/material.dart';

class AppStyles {
  // Paleta de colores principal - Amazon Inspired
  static const Color _amazonOrange = Color(0xFFFF9900);
  static const Color _amazonLightOrange = Color(0xFFFFAB40);
  static const Color _amazonDarkOrange = Color(0xFFE88A00);
  static const Color _pureWhite = Colors.white;
  static const Color _warmWhite = Color(0xFFFAF9F6);
  static const Color _lightGray = Color(0xFFF5F5F5);
  static const Color _mediumGray = Color(0xFFE0E0E0);
  static const Color _darkGray = Color(0xFF232F3E);
  static const Color _darkerGray = Color(0xFF191C1F);

  // Colores del Scaffold
  static const scaffoldBackgroundColorBright = _warmWhite;
  static const scaffoldBackgroundColorDar = _darkGray;

  // Colores de las tarjetas
  static const postCardColorSelected = Color(0xFFFFECCC); // Naranja muy claro
  static const postCardColor = Colors.transparent;
  static const postCardReplyColor = _pureWhite;
  static const Color colorAvatarBorder = _amazonOrange;

  // Colores de los botones
  static const sendButtonColor = _amazonDarkOrange;
  static const sendButtonColorDisabled = _mediumGray;

  //Redondez de los botones
  static const double borderRadiusValue = 8;

  //Tamaño de los avatars de perfil
  static const double avatarSize = 35.0;

  //Progress indicator button
  Widget progressIndicatorButton() {
    return const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(_amazonDarkOrange),
    );
  }

  Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? scaffoldBackgroundColorDar
        : scaffoldBackgroundColorBright;
  }

  ButtonStyle getButtonStyle(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return ButtonStyle(
      padding: WidgetStateProperty.all(
        const EdgeInsets.symmetric(
          horizontal: 24.0,
          vertical: 12.0,
        ),
      ),
      backgroundColor: WidgetStateProperty.resolveWith<Color>((states) {
        if (states.contains(WidgetState.disabled)) {
          return sendButtonColorDisabled;
        }
        return sendButtonColor;
      }),
      elevation: WidgetStateProperty.resolveWith<double>((states) {
        if (states.contains(WidgetState.pressed)) {
          return 0;
        }
        return 0;
      }),
      shape: WidgetStateProperty.all<RoundedRectangleBorder>(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12 * 2),
          side: const BorderSide(
            color: Colors.transparent,
            width: 1.0,
          ),
        ),
      ),
      textStyle: WidgetStateProperty.resolveWith<TextStyle>(
        (states) {
          return getButtontTextStyle(context);
        },
      ),
      overlayColor: WidgetStateProperty.resolveWith<Color?>((states) {
        if (states.contains(WidgetState.pressed)) {
          return _amazonOrange.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return _amazonOrange.withOpacity(0.05);
        }
        return null;
      }),
      animationDuration: const Duration(milliseconds: 200),
      mouseCursor: WidgetStateProperty.resolveWith<MouseCursor>((states) {
        if (states.contains(WidgetState.disabled)) {
          return SystemMouseCursors.forbidden;
        }
        return SystemMouseCursors.click;
      }),
    );
  }

  double getCardElevation(context) {
    return 5.0;
  }

  Color getButtonColor(context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _amazonLightOrange
        : _amazonOrange;
  }

  Color getTextFieldColor(context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkerGray
        : _pureWhite;
  }

  Color getCardColor(context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _darkGray
        : _pureWhite;
  }

  TextStyle getButtontTextStyle(context) {
    return TextStyle(
        fontWeight: FontWeight.w300,
        fontSize: 12,
        fontStyle: FontStyle.normal,
        color: Theme.of(context).brightness == Brightness.dark
            ? _darkGray
            : _pureWhite);
  }

  TextStyle getTextStyle(context) {
    return TextStyle(
        fontWeight: FontWeight.w300,
        fontSize: 12,
        fontStyle: FontStyle.normal,
        color: Theme.of(context).brightness == Brightness.dark
            ? _warmWhite
            : _darkGray);
  }

  InputDecoration getInputDecoration(
      String label, Widget? suffixIcon, context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      suffixIcon: suffixIcon,
      labelText: label,
      labelStyle: getTextStyle(context),
      filled: true,
      fillColor: isDarkMode ? _darkerGray : _lightGray,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _amazonOrange, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  double getScreenWidth(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return screenWidth * 0.95;
    } else if (screenWidth < 1024) {
      return screenWidth * 0.65;
    } else {
      return screenWidth * 0.75;
    }
  }

  double getSearchBarHeight(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return screenHeight < 700 ? 40 : 45;
  }
}

class TwitterColors {
  static const Color primary = Color(0xFF1DA1F2);
  static const Color secondary = Color(0xFF657786);
  static const Color background = Colors.white;
  static const Color darkGray = Color(0xFF14171A);
  static const Color lightGray = Color(0xFFAAB8C2);
  static const Color extraLightGray = Color(0xFFE1E8ED);
}

class TwitterDimensions {
  static const double avatarSizeLarge = 90.0;
  static const double avatarSizeMedium = 60.0;
  static const double avatarSizeSmall = 40.0;
  static const double borderRadius = 12.0;
  static const double spacing = 16.0;
  static const double spacingSmall = 8.0;
}
