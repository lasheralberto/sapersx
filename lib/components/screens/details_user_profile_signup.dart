import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/auth_provider.dart' as zauth;

class UserProfileFullScreenPage extends StatefulWidget {
  final String email;
  const UserProfileFullScreenPage({super.key, required this.email});

  static Future<bool?> show(BuildContext context, email) async {
    return Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => UserProfileFullScreenPage(email: email),
      ),
    );
  }

  @override
  State<UserProfileFullScreenPage> createState() => _UserProfileFullScreenPageState();
}

class _UserProfileFullScreenPageState extends State<UserProfileFullScreenPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _bioController;
  late final TextEditingController _locationController;
  late final TextEditingController _websiteController;
  late final TextEditingController _specialtyController;
  late final TextEditingController _rateController;
  late final TextEditingController _experienceController;

  bool _isExpertMode = false;
  bool _isSaving = false;
  static const int _charLimit = 160;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadUserData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _specialtyController.dispose();
    _rateController.dispose();
    _experienceController.dispose();
    super.dispose();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _bioController = TextEditingController();
    _locationController = TextEditingController();
    _websiteController = TextEditingController();
    _specialtyController = TextEditingController();
    _rateController = TextEditingController();
    _experienceController = TextEditingController();
  }

  Future<void> _loadUserData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final userInfo =
              Provider.of<zauth.AuthProviderSapers>(context, listen: false).userInfo;
        if (userInfo != null && mounted) {
          setState(() {
            _nameController.text = userInfo.username;
            _bioController.text = userInfo.bio.toString();
            _locationController.text = userInfo.location.toString();
            _websiteController.text = userInfo.website.toString();
            _specialtyController.text = userInfo.specialty.toString();
            _rateController.text = userInfo.hourlyRate.toString();
            _experienceController.text = userInfo.experience.toString();
            _isExpertMode = userInfo.isExpert as bool;
          });
        }
      } catch (e) {
        print('Error loading user data: $e');
      }
    }
  }

  Future<void> _saveProfile(email) async {
    if (!_formKey.currentState!.validate()) return;

    try {
      setState(() => _isSaving = true);

      final userInfo = UserInfoPopUp(
        uid: UtilsSapers().userUniqueUid(email),
        username: _nameController.text.trim().toLowerCase().replaceAll(' ', ''),
        bio: _bioController.text.trim(),
        location: _locationController.text.trim(),
        website:
            _websiteController.text.trim().toLowerCase().replaceAll(' ', ''),
        isExpert: _isExpertMode,
        joinDate: Timestamp.fromDate(DateTime.now()),
        specialty: _specialtyController.text.trim(),
        hourlyRate:
            double.tryParse(_rateController.text.trim().replaceAll(' ', '')) ??
                0.0,
        email: email.trim().toLowerCase().replaceAll(' ', ''),
        experience: _experienceController.text.trim(),
      );

      await FirebaseService().saveUserInfo(userInfo);

      if (mounted) {
        final authProvider =
            Provider.of<zauth.AuthProviderSapers>(context, listen: false);
        await authProvider.refreshUserInfo();
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _confirmExit() async {
    if (_hasUnsavedChanges()) {
      return await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(Texts.translate(
                  'confirmExit', LanguageProvider().currentLanguage)),
              content: Text(Texts.translate(
                  'confirmExitMessage', LanguageProvider().currentLanguage)),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(Texts.translate(
                      'cancel', LanguageProvider().currentLanguage)),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(Texts.translate(
                      'exit', LanguageProvider().currentLanguage)),
                ),
              ],
            ),
          ) ??
          false;
    }
    return true;
  }

  bool _hasUnsavedChanges() {
    return _nameController.text.isNotEmpty ||
        _bioController.text.isNotEmpty ||
        _locationController.text.isNotEmpty ||
        _websiteController.text.isNotEmpty ||
        (_isExpertMode &&
            (_specialtyController.text.isNotEmpty ||
                _rateController.text.isNotEmpty ||
                _experienceController.text.isNotEmpty));
  }

  PreferredSizeWidget _buildAppBar(email) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.close),
        onPressed: () async {
          if (await _confirmExit()) {
            Navigator.pop(context, false);
          }
        },
      ),
      title: Text(
        Texts.translate('editarPerfil', LanguageProvider().currentLanguage),
        style: AppStyles().getTextStyle(context,
            fontSize: AppStyles.fontSizeLarge, fontWeight: FontWeight.bold),
      ),
      actions: [
        TextButton(
          onPressed: () async {
            _isSaving ? null : await _saveProfile(email);
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.white,
            backgroundColor: AppStyles().getButtonColor(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
            ),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
              : Text(
                  Texts.translate('guardar', LanguageProvider().currentLanguage),
                  style: AppStyles()
                      .getTextStyle(context)
                      .copyWith(fontSize: 14, color: Colors.white),
                ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildProfilePicture(isExpert, email) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Align(
        alignment: Alignment.topLeft,
        child: ProfileAvatar(
            seed: email ?? 'U',
            size: AppStyles.avatarSize + 20,
            showBorder: isExpert),
      ),
    );
  }

  Widget _buildExpertModeToggle() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _isExpertMode
              ? Colors.blue.withOpacity(0.1)
              : Colors.grey.withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
          border: Border.all(
            color: _isExpertMode
                ? Colors.blue.withOpacity(0.3)
                : Colors.grey.withOpacity(0.3),
          ),
        ),
        child: Row(
          children: [
            Icon(
              Icons.workspace_premium,
              color: _isExpertMode ? Colors.blue : Colors.grey,
              size: 28,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Modo Experto SAP',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: _isExpertMode ? Colors.blue : Colors.grey[700],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Activa para ofrecer servicios de consultoría SAP',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Switch(
              value: _isExpertMode,
              onChanged: (value) => setState(() => _isExpertMode = value),
              activeColor: Colors.blue,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormFields() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          _buildTextField(
            controller: _nameController,
            label: Texts.translate(
                'nombreField', LanguageProvider().currentLanguage),
            maxLength: 50,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return Texts.translate(
                    'fieldRequired', LanguageProvider().currentLanguage);
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _bioController,
            label:
                Texts.translate('bioField', LanguageProvider().currentLanguage),
            maxLength: _charLimit,
            maxLines: 3,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return Texts.translate(
                    'fieldRequired', LanguageProvider().currentLanguage);
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _locationController,
            label: Texts.translate(
                'locationField', LanguageProvider().currentLanguage),
            prefixIcon: Icons.location_on_outlined,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return Texts.translate(
                    'fieldRequired', LanguageProvider().currentLanguage);
              }
              return null;
            },
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: _websiteController,
            label: Texts.translate(
                'websiteField', LanguageProvider().currentLanguage),
            prefixIcon: Icons.link,
            validator: (value) {
              if (value?.isEmpty ?? true) {
                return Texts.translate(
                    'fieldRequired', LanguageProvider().currentLanguage);
              }
              return null;
            },
          ),
          if (_isExpertMode) ...[
            const SizedBox(height: 20),
            _buildTextField(
              controller: _specialtyController,
              label: 'Especialidad SAP',
              prefixIcon: Icons.work_outline,
              hint: 'Ej: ABAP, FI, SD, MM, etc.',
              validator: (value) {
                if (_isExpertMode && (value?.isEmpty ?? true)) {
                  return Texts.translate(
                      'fieldRequired', LanguageProvider().currentLanguage);
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _experienceController,
              label: 'Experiencia/Proyectos realizados',
              maxLines: 3,
              maxLength: 200,
              hint: 'Ej: 5 años de experiencia en...',
              validator: (value) {
                if (_isExpertMode && (value?.isEmpty ?? true)) {
                  return Texts.translate(
                      'fieldRequired', LanguageProvider().currentLanguage);
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            _buildTextField(
              controller: _rateController,
              label: 'Tarifa por hora',
              prefixIcon: Icons.euro,
              hint: 'Ej: 60',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              suffix: const Text('€/h'),
              validator: (value) {
                if (_isExpertMode) {
                  if (value?.isEmpty ?? true) {
                    return Texts.translate(
                        'fieldRequired', LanguageProvider().currentLanguage);
                  }
                  final rate = double.tryParse(value!);
                  if (rate == null || rate <= 0) {
                    return 'Ingrese una tarifa válida';
                  }
                }
                return null;
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    int? maxLength,
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 200, // Ancho mínimo para pantallas pequeñas
          maxWidth: 500, // Ancho máximo para pantallas grandes
        ),
        child: TextFormField(
          controller: controller,
          maxLength: maxLength,
          maxLines: maxLines,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          decoration: InputDecoration(
            labelText: label,
            hintText: hint,
            isDense: true,
            prefixIcon: prefixIcon != null ? Icon(prefixIcon) : null,
            suffix: suffix,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
              borderSide: BorderSide(
                color: Colors.grey.withOpacity(0.3),
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
              borderSide: const BorderSide(
                color: Colors.blue,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
              borderSide: BorderSide(
                color: Colors.red.withOpacity(0.5),
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
              borderSide: const BorderSide(
                color: Colors.red,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _confirmExit,
      child: Scaffold(
        appBar: _buildAppBar(widget.email),
        body: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.only(
              bottom: MediaQuery.of(context).viewInsets.bottom,
              left: 16,
              right: 16,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildProfilePicture(_isExpertMode, widget.email),
                const SizedBox(height: 20),
                _buildExpertModeToggle(),
                _buildFormFields(),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}