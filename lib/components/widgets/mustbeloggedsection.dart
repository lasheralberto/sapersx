import 'package:flutter/material.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';

class LoginRequiredWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onTap;
  final Color buttonColor;
  final Color textColor;

  const LoginRequiredWidget({
    super.key,
    this.message = '',
    this.onTap,
    this.buttonColor = AppStyles.colorAvatarBorder,
    this.textColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            message.isEmpty
                ? Texts.translate(
                    'mustBeLogged', LanguageProvider().currentLanguage)
                : message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              foregroundColor: textColor,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              Texts.translate(
                  'iniciarSesion', LanguageProvider().currentLanguage),
              style: TextStyle(
                fontSize: Theme.of(context).textTheme.bodySmall!.fontSize,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
