import 'package:flutter/material.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/styles.dart';
import 'package:flutter/animation.dart';
import 'package:animate_do/animate_do.dart';

class EditProfileScreen extends StatefulWidget {
  final UserInfoPopUp user;

  const EditProfileScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _bioController;
  late TextEditingController _locationController;
  late TextEditingController _specialtyController;
  late TextEditingController _websiteController;
  late TextEditingController _experienceController;
  late TextEditingController _tarifaController =
      TextEditingController(text: widget.user.hourlyRate.toString());
  bool _isLoading = false;

  late final AnimationController _animationController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.user.bio);
    _locationController = TextEditingController(text: widget.user.location);
    _specialtyController = TextEditingController(text: widget.user.specialty);
    _websiteController = TextEditingController(text: widget.user.website);
    _experienceController = TextEditingController(text: widget.user.experience);

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    final maxWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: FadeIn(
          duration: const Duration(milliseconds: 500),
          child: const Text(
            'Editar Perfil',
            style: TextStyle(color: AppStyles.colorAvatarBorder),
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          color: AppStyles.colorAvatarBorder,
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (_isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            FadeIn(
              duration: const Duration(milliseconds: 500),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppStyles.colorAvatarBorder,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                  onPressed: _saveChanges,
                  icon: const Icon(Icons.save_outlined, size: 18),
                  label: const Text('Guardar'),
                ),
              ),
            ),
        ],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : maxWidth * 0.1,
            vertical: 24,
          ),
          child: FadeInUp(
            duration: const Duration(milliseconds: 600),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 800),
              decoration: BoxDecoration(
                color: Theme.of(context).cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Profile Picture and Basic Info
                      Center(
                        child: Stack(
                          children: [
                            // CircleAvatar(
                            //   radius: 50,
                            //   backgroundColor:
                            //       AppStyles.colorAvatarBorder.withOpacity(0.1),
                            //   child: Text(
                            //     widget.user.username[0].toUpperCase(),
                            //     style: TextStyle(
                            //       fontSize: 40,
                            //       color: AppStyles.colorAvatarBorder,
                            //     ),
                            //   ),
                            // ),
                            // Positioned(
                            //   bottom: 0,
                            //   right: 0,
                            //   child: Container(
                            //     padding: const EdgeInsets.all(4),
                            //     decoration: BoxDecoration(
                            //       color: AppStyles.colorAvatarBorder,
                            //       shape: BoxShape.circle,
                            //     ),
                            //     child: const Icon(
                            //       Icons.camera_alt,
                            //       size: 20,
                            //       color: Colors.white,
                            //     ),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      // const SizedBox(height: 32),

                      // Form Fields in Grid
                      Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _buildAnimatedField(
                            flex: 2,
                            child: _buildTextField(
                              controller: _bioController,
                              label: Texts.translate(
                                  'bio', LanguageProvider().currentLanguage),
                              maxLines: 3,
                              icon: Icons.person_outline,
                            ),
                          ),
                          _buildAnimatedField(
                            child: _buildTextField(
                              controller: _locationController,
                              label: Texts.translate('location',
                                  LanguageProvider().currentLanguage),
                              icon: Icons.location_on_outlined,
                            ),
                          ),
                          _buildAnimatedField(
                            child: _buildTextField(
                              controller: _specialtyController,
                              label: Texts.translate('specialty',
                                  LanguageProvider().currentLanguage),
                              icon: Icons.work_outline,
                            ),
                          ),
                          _buildAnimatedField(
                            child: _buildTextField(
                              controller: _websiteController,
                              label: Texts.translate('website',
                                  LanguageProvider().currentLanguage),
                              icon: Icons.link_outlined,
                            ),
                          ),
                          widget.user.isExpert == true
                              ? _buildAnimatedField(
                                  child: _buildTextField(
                                    controller: _experienceController,
                                    label: Texts.translate('experience',
                                        LanguageProvider().currentLanguage),
                                    maxLines: 3,
                                    icon: Icons.stars_outlined,
                                  ),
                                )
                              : const SizedBox.shrink(),
                          widget.user.isExpert == true
                              ? _buildAnimatedField(
                                  child: _buildTextField(
                                    controller: _tarifaController,
                                    label: Texts.translate('tarife',
                                        LanguageProvider().currentLanguage),
                                    icon: Icons.attach_money_outlined,
                                  ),
                                )
                              : const SizedBox.shrink(),
                        ],
                      ),
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

  Widget _buildAnimatedField({required Widget child, int flex = 1}) {
    return FadeInUp(
      duration: const Duration(milliseconds: 600),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: 300,
          maxWidth: flex == 2 ? double.infinity : 400,
        ),
        child: child,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: AppStyles.colorAvatarBorder),
        prefixIcon: Icon(icon, color: AppStyles.colorAvatarBorder),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppStyles.colorAvatarBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: AppStyles.colorAvatarBorder, width: 2),
        ),
        filled: true,
        fillColor: AppStyles.colorAvatarBorder.withOpacity(0.05),
      ),
    );
  }

  Future<void> _saveChanges() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);

      try {
        final UserInfoPopUp updateUser = UserInfoPopUp(
          uid: widget.user.uid,
          username: widget.user.username,
          email: widget.user.email,
          bio: _bioController.text,
          location: _locationController.text,
          specialty: _specialtyController.text,
          website: _websiteController.text,
          experience: _experienceController.text,
        );

        await FirebaseService().updateUserProfile(updateUser);

        if (mounted) {
          Navigator.pop(context, updateUser);
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error al guardar los cambios')),
        );
      } finally {
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    }
  }
}
