import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sapers/components/screens/details_user_profile_signup.dart';
import 'package:sapers/models/auth_service.dart';
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
    final size = MediaQuery.of(context).size;
    final isSmallScreen = size.width < 600;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.background,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Theme.of(context).scaffoldBackgroundColor,
            border: Border(
              bottom: BorderSide(
                color: Theme.of(context).dividerColor.withOpacity(0.1),
              ),
            ),
          ),
          child: AppBar(
            centerTitle: true,
            title: Text(
              _isSignUp
                  ? Texts.translate(
                      'crearCuenta', LanguageProvider().currentLanguage)
                  : Texts.translate(
                      'iniciarSesion', LanguageProvider().currentLanguage),
              style: TextStyle(
                color: AppStyles().getButtonColor(context),
                fontWeight: FontWeight.w600,
              ),
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.close),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            width: isSmallScreen ? size.width : 400,
            margin: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 24 : 0,
              vertical: isSmallScreen ? 0 : 32,
            ),
            child: Card(
              elevation: AppStyles().getCardElevation(context),
              shadowColor: Colors.black.withOpacity(0.1),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(24),
              ),
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Logo section
                      _buildLogoSection(),
                      const SizedBox(height: 32),

                      // Form fields section
                      _buildFormFields(),

                      // Error message
                      if (_errorMessage != null) _buildErrorMessage(),
                      const SizedBox(height: 32),

                      // Action buttons
                      _buildActionButtons(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLogoSection() {
    return Hero(
      tag: 'login_logo',
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Theme.of(context).colorScheme.surface,
        ),
        child: Image.asset(
          AppStyles.tabMarkerImage,
          height: 80,
          width: 80,
          fit: BoxFit.contain,
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Column(
      children: [
        _buildAnimatedTextField(
          controller: _emailController,
          label:
              Texts.translate('emailField', LanguageProvider().currentLanguage),
          icon: Icons.email_outlined,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return Texts.translate(
                  'emailValidate', LanguageProvider().currentLanguage);
            }
            if (!value.contains('@')) {
              return Texts.translate(
                  'emailWrong', LanguageProvider().currentLanguage);
            }
            return null;
          },
        ),
        const SizedBox(height: 20),
        _buildAnimatedTextField(
          controller: _passwordController,
          label:
              Texts.translate('Password', LanguageProvider().currentLanguage),
          icon: Icons.lock_outline,
          obscureText: true,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return Texts.translate(
                  'passError', LanguageProvider().currentLanguage);
            }
            if (_isSignUp && value.length < 6) {
              return Texts.translate(
                  'passErrorLen', LanguageProvider().currentLanguage);
            }
            return null;
          },
        ),
        if (_isSignUp) ...[
          const SizedBox(height: 20),
          _buildAnimatedTextField(
            controller: _confirmPasswordController,
            label: Texts.translate(
                'confirmarContraseña', LanguageProvider().currentLanguage),
            icon: Icons.lock_outline,
            obscureText: true,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return Texts.translate('porFavorConfirmaTuContraseña',
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
      ],
    );
  }

  Widget _buildAnimatedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    required String? Function(String?) validator,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).dividerColor.withOpacity(0.2),
          width: 1.5,
        ),
      ),
      child: TextFormField(
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(
            fontSize: 14,
            color:
                Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.7),
          ),
          prefixIcon: Icon(
            icon,
            size: 18,
            color:
                Theme.of(context).textTheme.bodyMedium?.color?.withOpacity(0.5),
          ),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        style: const TextStyle(fontSize: 15),
        obscureText: obscureText,
        validator: validator,
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade100),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.red.shade700, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(
                  color: Colors.red.shade700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton(
          onPressed: _isLoading
              ? null
              : () async {
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
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
            elevation: 0,
            textStyle: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.3,
            ),
          ).copyWith(
            overlayColor: MaterialStateProperty.resolveWith<Color?>(
              (Set<MaterialState> states) {
                if (states.contains(MaterialState.pressed)) {
                  return Colors.black12;
                }
                if (states.contains(MaterialState.hovered)) {
                  return Colors.black.withOpacity(0.05);
                }
                return null;
              },
            ),
          ),
          child: _isLoading
              ? SizedBox(
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).colorScheme.onPrimary,
                    ),
                  ),
                )
              : Text(
                  _isSignUp
                      ? Texts.translate(
                          'crearCuenta', LanguageProvider().currentLanguage)
                      : Texts.translate(
                          'iniciarSesion', LanguageProvider().currentLanguage),
                ),
        ),
        const SizedBox(height: 16),
        TextButton(
          onPressed: _isLoading ? null : _toggleMode,
          style: TextButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(25),
            ),
          ),
          child: Text(
            _isSignUp
                ? Texts.translate(
                    'iniciarSesion', LanguageProvider().currentLanguage)
                : Texts.translate(
                    'crearCuenta', LanguageProvider().currentLanguage),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppStyles().getButtonColor(context),
            ),
          ),
        ),
      ],
    );
  }
}
