import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sapers/components/screens/details_user_profile_signup.dart' as details_screen;
import 'package:sapers/main.dart' as app_main;
import 'package:sapers/models/firebase_service.dart' as firebase_service;
import 'package:sapers/models/styles.dart' as styles;
import 'package:sapers/models/texts.dart' as texts;

class LoginDialog extends StatefulWidget {
  const LoginDialog({super.key});

  @override
  State createState() => _LoginDialogState();
}

class _LoginDialogState extends State<LoginDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = firebase_service.AuthService();
  final _styles = styles.AppStyles();
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSignUp = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<bool?> _submitForm(String email, String pass) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        if (_isSignUp) {
          await _authService.signUp(email, pass);
          await FirebaseAuth.instance.authStateChanges().first;
          await details_screen.UserProfilePopup.show(context);
          return true;
        } else {
          final user = await _authService.signIn(email, pass);
          return user != null;
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message;
        });
        return false;
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
    return false;
  }

  void _toggleMode() {
    setState(() {
      _isSignUp = !_isSignUp;
      _errorMessage = null;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(styles.AppStyles.borderRadiusValue),
      ),
      elevation: 0,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
          constraints: const BoxConstraints(maxWidth: 360),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _isSignUp
                      ? texts.Texts.translate('crearCuenta', app_main.globalLanguage)
                      : texts.Texts.translate('iniciarSesion', app_main.globalLanguage),
                  style: _styles.getTextStyle(context,
                      fontSize: 18, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: _styles.getInputDecoration(
                      texts.Texts.translate('emailField', app_main.globalLanguage),
                      null,
                      context),
                  style: const TextStyle(fontSize: 16),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return texts.Texts.translate('emailValidate', app_main.globalLanguage);
                    }
                    if (!value.contains('@')) {
                      return texts.Texts.translate('emailWrong', app_main.globalLanguage);
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: _styles.getInputDecoration(
                      texts.Texts.translate('Password', app_main.globalLanguage),
                      null,
                      context),
                  style: const TextStyle(fontSize: 16),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return texts.Texts.translate('passError', app_main.globalLanguage);
                    }
                    if (_isSignUp && value.length < 6) {
                      return texts.Texts.translate('passErrorLen', app_main.globalLanguage);
                    }
                    return null;
                  },
                ),
                if (_isSignUp) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: _styles.getInputDecoration(
                        texts.Texts.translate('confirmarContraseña', app_main.globalLanguage),
                        null,
                        context),
                    style: const TextStyle(fontSize: 16),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return texts.Texts.translate(
                            'porFavorConfirmaTuContraseña', app_main.globalLanguage);
                      }
                      if (value != _passwordController.text) {
                        return texts.Texts.translate(
                            'lasContraseñasNoCoinciden', app_main.globalLanguage);
                      }
                      return null;
                    },
                  ),
                ],
                if (_errorMessage != null) ...[
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: BorderRadius.circular(styles.AppStyles.borderRadiusValue),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: TextStyle(
                        color: Colors.red[700],
                        fontSize: 13,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ],
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () async {
                    if (!_isLoading) {
                      var isLogued = await _submitForm(
                        _emailController.text,
                        _passwordController.text,
                      );
                      if (isLogued == true) {
                        Navigator.pop(context, true);
                      }
                    }
                  },
                  style: _styles.getButtonStyle(context),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          _isSignUp
                              ? texts.Texts.translate('crearCuenta', app_main.globalLanguage)
                              : texts.Texts.translate('iniciarSesion', app_main.globalLanguage),
                          style: _styles.getTextStyle(context,
                              fontSize: 18,
                              fontWeight: FontWeight.normal,
                              color: Colors.white),
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : _toggleMode,
                  style: TextButton.styleFrom(
                    foregroundColor: styles.AppStyles.colorAvatarBorder,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    _isSignUp
                        ? texts.Texts.translate('iniciarSesion', app_main.globalLanguage)
                        : texts.Texts.translate('crearCuenta', app_main.globalLanguage),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}