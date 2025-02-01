import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sapers/components/screens/details_user_profile_signup.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';

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
  final _authService = AuthService();
  final _styles = AppStyles();
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSignUp = false;

  // Estilo Mesomórfico
  static const _mesoShadow = [
    BoxShadow(
      color: Color(0x22000000),
      blurRadius: 20,
      spreadRadius: 2,
      offset: Offset(8, 8),
    ),
    BoxShadow(
      color: Color(0x44FFFFFF),
      blurRadius: 20,
      spreadRadius: 2,
      offset: Offset(-8, -8),
    ),
  ];

  static const _mesoBorder = BorderSide(
    color: Color(0x44FFFFFF),
    width: 2,
  );

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
          await UserProfilePopup.show(context);
          return true;
        } else {
          final user = await _authService.signIn(email, pass);
          if (user != null) {
            return true;
          } else {
            return false;
          }
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
        borderRadius: BorderRadius.circular(20),
      ),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(20),
          boxShadow: null,
          border:
              Border.all(color: _mesoBorder.color, width: _mesoBorder.width),
        ),
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
                  Image.asset(
                    AppStyles.tabMarkerImage,
                    height: 80,
                    width: 80,
                    fit: BoxFit.contain,
                  ),
                  Text(
                    _isSignUp
                        ? Texts.translate('crearCuenta', globalLanguage)
                        : Texts.translate('iniciarSesion', globalLanguage),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppStyles().getButtonColor(context),
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),
                  _buildTextField(
                    controller: _emailController,
                    label: Texts.translate('emailField', globalLanguage),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return Texts.translate('emailValidate', globalLanguage);
                      }
                      if (!value.contains('@')) {
                        return Texts.translate('emailWrong', globalLanguage);
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _passwordController,
                    label: Texts.translate('Password', globalLanguage),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return Texts.translate('passError', globalLanguage);
                      }
                      if (_isSignUp && value.length < 6) {
                        return Texts.translate('passErrorLen', globalLanguage);
                      }
                      return null;
                    },
                  ),
                  if (_isSignUp) ...[
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _confirmPasswordController,
                      label: Texts.translate(
                          'confirmarContraseña', globalLanguage),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return Texts.translate(
                              'porFavorConfirmaTuContraseña', globalLanguage);
                        }
                        if (value != _passwordController.text) {
                          return Texts.translate(
                              'lasContraseñasNoCoinciden', globalLanguage);
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
                        borderRadius: BorderRadius.circular(12),
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
                      if (_isLoading == false) {
                        var isLogued = await _submitForm(
                          _emailController.text,
                          _passwordController.text,
                        );

                        if (isLogued == true) {
                          Navigator.pop(context, true);
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppStyles().getButtonColor(context),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 4,
                      shadowColor: Colors.black.withOpacity(0.2),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            _isSignUp
                                ? Texts.translate('crearCuenta', globalLanguage)
                                : Texts.translate(
                                    'iniciarSesion', globalLanguage),
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: _isLoading ? null : _toggleMode,
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      _isSignUp
                          ? Texts.translate('iniciarSesion', globalLanguage)
                          : Texts.translate('crearCuenta', globalLanguage),
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    bool obscureText = false,
    required String? Function(String?) validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: null,
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: AppStyles().getTextStyle(context, fontWeight: FontWeight.bold),
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }
}
