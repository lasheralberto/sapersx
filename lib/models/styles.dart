import 'package:flutter/material.dart';
import 'package:loading_indicator/loading_indicator.dart';

class AppStyles {
  // Main color palette - Elegant Orange Theme
  static const Color _orangePrimary = Color(0xFFFF9900);
  static const Color _orangeLight = Color(0xFFFFB74D);
  static const Color _orangeDark = Color(0xFFE88A00);
  static const Color _pureWhite = Colors.white;
  static const Color _warmWhite = Color(0xFFFAF9F6);
  static const Color _lightGray = Color(0xFFF5F5F5);
  static const Color _mediumGray = Color(0xFFE0E0E0);
  static const Color _darkGray = Color(0xFF232F3E);
  static const Color _darkerGray = Color(0xFF191C1F);

  // Text colors
  static const Color textColor = _darkGray;
  static const Color textColorLight = _mediumGray;
  static const Color textColorDark = _darkerGray;

  // Background colors
  static const Color scaffoldBackgroundColorBright = _warmWhite;
  static const Color scaffoldBackgroundColorDark = _darkGray;
  static const Color cardBackgroundColor = _pureWhite;
  static const Color inputBackgroundColor = _pureWhite;

  // Border and icon colors
  static const Color borderColor = _mediumGray;
  static const Color iconColor = _darkGray;

  // Avatar and selection colors
  static const bool showAvatars = false;
  static const Color colorAvatarBorder = _orangePrimary;
  static const Color colorAvatarBorderLighter = Color(0xFFFFCCB3);

  // Card colors
  static const Color postCardColorSelected = _lightGray;
  static const Color postCardColor = Colors.transparent;
  static const Color postCardReplyColor = _pureWhite;

  // Scaffold color
  static const Color scaffoldColor = _pureWhite;

  // Button colors
  static const Color sendButtonColor = _orangeDark;
  static const Color sendButtonColorDisabled = _mediumGray;
  static const Color buttonHoverColor = Color(0xFFFFF3E0);

  // Dimensions
  static const double borderRadiusValue = 8.0;
  static const double avatarSize = 33.0;
  static const double cardElevation = 2.0;
  static const double dialogBorderRadius = 12.0;

  // Typography
  static const double fontSize = 11.0;
  static const double fontSizeMedium = 12.0;
  static const double fontSizeLarge = 16.0;
  static const double fontSizeHeading = 20.0;

  // Assets
  static const String tabMarkerImage = 'assets/images/tabmarker.png';
  static const String logoImage = 'assets/images/logo.png';

  // Spacing
  static const double spacingSmall = 8.0;
  static const double spacingMedium = 16.0;
  static const double spacingLarge = 24.0;

  // Icon sizes
  static const double iconSizeSmall = 16.0;
  static const double iconSizeMedium = 24.0;
  static const double iconSizeLarge = 32.0;
  static const double iconSizeExtraLarge = 40.0;

  Widget progressIndicatorCreatePostButton() {
    return const CircularProgressIndicator(
      valueColor: AlwaysStoppedAnimation<Color>(AppStyles._orangeDark),
    );
  }

  double getFontSize(BuildContext context, {double? fontSize}) {
    return fontSize != null ? fontSize.toDouble() : 12;
  }

  Widget progressIndicatorButton(context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Si el ancho disponible es pequeño (típico de un botón), usamos un tamaño reducido
        final isSmall = constraints.maxWidth < 350;

        final size = isSmall ? 5.0 : 60.0;

        return SizedBox(
          width: size,
          height: size,
          child: const LoadingIndicator(
            indicatorType: Indicator.ballRotate,
            colors: [_orangeLight, Colors.orange],
            strokeWidth: 2,
            backgroundColor: Colors.transparent,
            pathBackgroundColor: Colors.black,
          ),
        );
      },
    );
  }

  Color getBackgroundColor(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark
        ? scaffoldBackgroundColorDark
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
          return _orangePrimary.withOpacity(0.1);
        }
        if (states.contains(WidgetState.hovered)) {
          return _orangePrimary.withOpacity(0.05);
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
    return 1.0;
  }

  Color getButtonColor(context) {
    return Theme.of(context).brightness == Brightness.dark
        ? _orangeLight
        : _orangePrimary;
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
        fontSize: 11,
        fontStyle: FontStyle.normal,
        color: Theme.of(context).brightness == Brightness.dark
            ? _darkGray
            : _pureWhite);
  }

  TextStyle getTextStyle(
    BuildContext context, {
    Color? color,
    FontWeight? fontWeight,
    double? fontSize,
  }) {
    // Valores predeterminados

    const FontWeight defaultWeight = FontWeight.normal;
    const double defaultSize = 11;

    return TextStyle(
      fontWeight: fontWeight ?? defaultWeight,
      fontSize: fontSize ?? defaultSize,
      fontStyle: FontStyle.normal,
      color: color ??
          (Theme.of(context).brightness == Brightness.dark
              ? _warmWhite
              : _darkGray),
    );
  }

  double getMaxWidthDialog(context) {
    var mediaQuery = MediaQuery.of(context).size;
    // Calculate responsive width based on screen size
    double dialogWidth;
    if (mediaQuery.width < 600) {
      // Mobile screens - full width with small padding
      dialogWidth = mediaQuery.width;
    } else if (mediaQuery.width < 900) {
      // Tablet/smaller screens - 75% of screen width
      dialogWidth = mediaQuery.width * 0.75;
    } else {
      // Larger screens - 66% of screen width (original 1.5 ratio)
      dialogWidth = mediaQuery.width / 3;
    }

    return dialogWidth;
  }

  InputDecoration getInputDecoration(
      String label, Widget? suffixIcon, context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return InputDecoration(
      suffixIcon: suffixIcon,
      labelText: label,
      labelStyle: getTextStyle(context),
      filled: true,
      fillColor:
          isDarkMode ? _darkerGray : const Color.fromARGB(255, 255, 252, 252),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _orangeDark, width: 1.5),
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
      return screenWidth * 0.85;
    }
  }

  Color getProjectCardColor(String projectId) {
    final colors = [
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
      Colors.yellow,
      Colors.green,
      Colors.pink,
      Colors.red,
      Colors.deepPurple
    ];
    return colors[int.parse(projectId.hashCode.toString().substring(0, 1))];
  }

  double getFeedWith(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;

    if (screenWidth < 600) {
      return screenWidth * 0.99;
    } else if (screenWidth < 1024) {
      return screenWidth * 0.75;
    } else {
      return screenWidth * 0.85;
    }
  }

  double getSearchBarHeight(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;
    return screenHeight < 700 ? 35 : 45;
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

class AppTheme {
  static ThemeData getLightTheme() {
    return ThemeData(
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppStyles.colorAvatarBorder,
      ),
      useMaterial3: true,
      brightness: Brightness.light,
      primaryColor: AppStyles.colorAvatarBorder,
      scaffoldBackgroundColor: const Color.fromARGB(255, 255, 255, 255),
      colorScheme: const ColorScheme.light(
        primary: AppStyles.colorAvatarBorder,
        secondary: AppStyles._orangeLight,
        surface: AppStyles._pureWhite,
        background: AppStyles.scaffoldBackgroundColorBright,
        error: Colors.redAccent,
        onPrimary: AppStyles._pureWhite,
        onSecondary: AppStyles._pureWhite,
        onSurface: AppStyles.textColor,
        onBackground: AppStyles.textColor,
        onError: AppStyles._pureWhite,
      ),
      cardTheme: CardThemeData(
        color: AppStyles.cardBackgroundColor,
        elevation: AppStyles.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        ),
        margin: const EdgeInsets.all(AppStyles.spacingSmall),
      ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: AppStyles.iconColor,
        ),
        titleTextStyle: TextStyle(
          color: AppStyles.textColor,
          fontSize: AppStyles.fontSizeLarge,
          fontWeight: FontWeight.w600,
        ),
      ),
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: AppStyles.fontSizeLarge,
          fontWeight: FontWeight.bold,
          color: AppStyles.textColor,
        ),
        displayMedium: TextStyle(
          fontSize: AppStyles.fontSizeMedium,
          fontWeight: FontWeight.bold,
          color: AppStyles.textColor,
        ),
        displaySmall: TextStyle(
          fontSize: AppStyles.fontSize,
          fontWeight: FontWeight.bold,
          color: AppStyles.textColor,
        ),
        headlineMedium: TextStyle(
          fontSize: AppStyles.fontSizeHeading,
          fontWeight: FontWeight.w600,
          color: AppStyles.textColor,
        ),
        titleLarge: TextStyle(
          fontSize: AppStyles.fontSizeLarge,
          fontWeight: FontWeight.w600,
          color: AppStyles.textColor,
        ),
        bodyLarge: TextStyle(
          fontSize: AppStyles.fontSizeMedium,
          color: AppStyles.textColor,
        ),
        bodyMedium: TextStyle(
          fontSize: AppStyles.fontSize,
          color: AppStyles.textColor,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppStyles.inputBackgroundColor,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
          borderSide: const BorderSide(
            color: AppStyles.borderColor,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
          borderSide: const BorderSide(
            color: AppStyles.borderColor,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
          borderSide: const BorderSide(
            color: AppStyles.colorAvatarBorder,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppStyles.spacingMedium,
          vertical: AppStyles.spacingMedium,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppStyles.colorAvatarBorder,
          foregroundColor: AppStyles._pureWhite,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
          ),
          padding: const EdgeInsets.symmetric(
            horizontal: AppStyles.spacingLarge,
            vertical: AppStyles.spacingMedium,
          ),
          elevation: 0,
        ).copyWith(
          overlayColor: MaterialStateProperty.resolveWith<Color?>(
            (Set<MaterialState> states) {
              if (states.contains(MaterialState.hovered)) {
                return AppStyles.buttonHoverColor;
              }
              return null;
            },
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppStyles.colorAvatarBorder,
        foregroundColor: AppStyles._pureWhite,
        elevation: AppStyles.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
        ),
      ),
    );
  }

  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      primaryColor: AppStyles.colorAvatarBorder,
      scaffoldBackgroundColor: AppStyles.scaffoldBackgroundColorDark,

      colorScheme: const ColorScheme.dark(
        primary: AppStyles.colorAvatarBorder,
        secondary: AppStyles._orangeLight,
        surface: AppStyles._darkGray,
        background: AppStyles.scaffoldBackgroundColorDark,
        error: Colors.redAccent,
        onPrimary: AppStyles._pureWhite,
        onSecondary: AppStyles._pureWhite,
        onSurface: AppStyles._warmWhite,
        onBackground: AppStyles._warmWhite,
        onError: AppStyles._pureWhite,
      ),

      // Dark theme specific overrides
      cardTheme: CardThemeData(
        color: AppStyles._darkGray,
        elevation: AppStyles.cardElevation,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        ),
      ),

      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: AppStyles._warmWhite,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.bold,
          color: AppStyles._warmWhite,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: AppStyles._warmWhite,
        ),
        headlineMedium: TextStyle(
          fontSize: AppStyles.fontSizeHeading,
          fontWeight: FontWeight.w600,
          color: AppStyles._warmWhite,
        ),
        titleLarge: TextStyle(
          fontSize: AppStyles.fontSizeLarge,
          fontWeight: FontWeight.w600,
          color: AppStyles._warmWhite,
        ),
        bodyLarge: TextStyle(
          fontSize: AppStyles.fontSizeMedium,
          color: AppStyles._warmWhite,
        ),
        bodyMedium: TextStyle(
          fontSize: AppStyles.fontSize,
          color: AppStyles._warmWhite,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        fillColor: AppStyles._darkerGray,
        filled: true,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppStyles.dialogBorderRadius),
          borderSide: const BorderSide(
            color: AppStyles.borderColor,
          ),
        ),
      ),
    );
  }
}
