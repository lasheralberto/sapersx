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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future _submitForm(email, pass) async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      try {
        if (_isSignUp) {
          await _authService.signUp(email, pass);
          //Añadir para que rellene información adicional sobre él.
          Future.delayed(Duration(milliseconds: 100), () {
            UserProfilePopup.show(context);
          });
        } else {
          var isLoguedIn = await _authService.signIn(email, pass);

          if (isLoguedIn == true) {
            Navigator.of(context).pop();
        
          } else {
            showBottomSheet(
                context: context,
                builder: (context) {
                  return Container(
                    height: 100,
                    color: Colors.red,
                    child: const Center(
                      child: Text('Error al iniciar sesión.'),
                    ),
                  );
                });
          }
        }
      } on FirebaseAuthException catch (e) {
        setState(() {
          _errorMessage = e.message;
        });
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
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
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
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
                      ? Texts.translate('crearCuenta', globalLanguage)
                      : Texts.translate('iniciarSesion', globalLanguage),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  decoration: _styles.getInputDecoration(
                      Texts.translate('emailField', globalLanguage),
                      null,
                      context),
                  style: const TextStyle(fontSize: 16),
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
                TextFormField(
                  controller: _passwordController,
                  decoration: _styles.getInputDecoration(
                      Texts.translate('Password', globalLanguage),
                      null,
                      context),
                  style: const TextStyle(fontSize: 16),
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
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: _styles.getInputDecoration(
                        Texts.translate('confirmarContraseña', globalLanguage),
                        null,
                        context),
                    style: const TextStyle(fontSize: 16),
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
                      borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
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
                      await _submitForm(
                        _emailController.text,
                        _passwordController.text,
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius:BorderRadius.circular(AppStyles.borderRadiusValue),
                    ),
                    elevation: 0,
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
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _isLoading ? null : _toggleMode,
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.blue[600],
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
    );
  }
}
