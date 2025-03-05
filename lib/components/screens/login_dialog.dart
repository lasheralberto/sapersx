import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sapers/components/screens/details_user_profile_signup.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

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
          bool? islogued = await UserProfileFullScreenPage.show(context, email);
          if (islogued == true) {
            await _authService.signUp(email, pass);
            await FirebaseAuth.instance.authStateChanges().first;
            return true;
          } else {
            return false;
          }
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
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isSignUp
              ? Texts.translate(
                  'crearCuenta', LanguageProvider().currentLanguage)
              : Texts.translate(
                  'iniciarSesion', LanguageProvider().currentLanguage),
          style: TextStyle(
            color: AppStyles().getButtonColor(context),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: SizedBox(
              width: MediaQuery.of(context).size.width < 500
                  ? double.infinity
                  : MediaQuery.of(context).size.width * 0.4,
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(
                      child: Image.asset(
                        AppStyles.tabMarkerImage,
                        height: 120,
                        width: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 32),
                    _buildTextField(
                      controller: _emailController,
                      label: Texts.translate(
                          'emailField', LanguageProvider().currentLanguage),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return Texts.translate('emailValidate',
                              LanguageProvider().currentLanguage);
                        }
                        if (!value.contains('@')) {
                          return Texts.translate(
                              'emailWrong', LanguageProvider().currentLanguage);
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    _buildTextField(
                      controller: _passwordController,
                      label: Texts.translate(
                          'Password', LanguageProvider().currentLanguage),
                      obscureText: true,
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return Texts.translate(
                              'passError', LanguageProvider().currentLanguage);
                        }
                        if (_isSignUp && value.length < 6) {
                          return Texts.translate('passErrorLen',
                              LanguageProvider().currentLanguage);
                        }
                        return null;
                      },
                    ),
                    if (_isSignUp) ...[
                      const SizedBox(height: 16),
                      _buildTextField(
                        controller: _confirmPasswordController,
                        label: Texts.translate('confirmarContraseña',
                            LanguageProvider().currentLanguage),
                        obscureText: true,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return Texts.translate(
                                'porFavorConfirmaTuContraseña',
                                LanguageProvider().currentLanguage);
                          }
                          if (value != _passwordController.text) {
                            return Texts.translate('lasContraseñasNoCoinciden',
                                LanguageProvider().currentLanguage);
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
                          borderRadius: BorderRadius.circular(
                              AppStyles.borderRadiusValue),
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
                                  ? Texts.translate('crearCuenta',
                                      LanguageProvider().currentLanguage)
                                  : Texts.translate('iniciarSesion',
                                      LanguageProvider().currentLanguage),
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
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        _isSignUp
                            ? Texts.translate('iniciarSesion',
                                LanguageProvider().currentLanguage)
                            : Texts.translate('crearCuenta',
                                LanguageProvider().currentLanguage),
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
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
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        boxShadow: null,
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
              borderSide: BorderSide.none),
          filled: true,
          fillColor: Theme.of(context).colorScheme.surface,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
        style: AppStyles().getTextStyle(context,
            fontSize: AppStyles.fontSizeMedium, fontWeight: FontWeight.w100),
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }
}
