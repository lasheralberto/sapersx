import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:random_avatar/random_avatar.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';

class UserProfilePopup extends StatelessWidget {
  const UserProfilePopup({super.key});

  @override
  Widget build(BuildContext context) {
    return Container();
  }

  static void show(BuildContext context) {
    final TextEditingController nameController = TextEditingController();
    final TextEditingController bioController = TextEditingController();
    final TextEditingController locationController = TextEditingController();
    final TextEditingController websiteController = TextEditingController();
    final TextEditingController specialtyController = TextEditingController();
    final TextEditingController rateController = TextEditingController();
    final TextEditingController experienceController = TextEditingController();
    const charLimit = 160;
    bool isExpertMode = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.9,
                constraints: const BoxConstraints(maxWidth: 800),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Header (sin cambios)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                              width: 1,
                            ),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.close,
                                  color: Colors.black87),
                              onPressed: () => Navigator.pop(context),
                            ),
                            Text(
                              Texts.translate('editarPerfil', globalLanguage),
                              style: AppStyles().getTextStyle(context),
                            ),
                            TextButton(
                              onPressed: () async {
                                if (nameController.text.trim().isEmpty ||
                                    bioController.text.trim().isEmpty ||
                                    locationController.text.trim().isEmpty ||
                                    websiteController.text.trim().isEmpty ||
                                    (isExpertMode &&
                                        (specialtyController.text
                                                .trim()
                                                .isEmpty ||
                                            rateController.text
                                                .trim()
                                                .isEmpty))) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        Texts.translate(
                                            'createPerfilRequiredFields',
                                            globalLanguage),
                                      ),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                  return;
                                }

                                await FirebaseService().saveUserInfo(
                                  UserInfoPopUp(
                                    uid: UtilsSapers().userUniqueUid(
                                      FirebaseAuth.instance.currentUser!.email
                                          .toString(),
                                    ),
                                    username: nameController.text
                                        .trim()
                                        .toLowerCase(),
                                    bio: bioController.text.trim(),
                                    location: locationController.text.trim(),
                                    website: websiteController.text
                                        .trim()
                                        .toLowerCase(),
                                    isExpert: isExpertMode,
                                    specialty: specialtyController.text.trim(),
                                    hourlyRate: double.tryParse(
                                            rateController.text.trim()) ??
                                        0.0,
                                    email: FirebaseAuth
                                        .instance.currentUser!.email
                                        .toString()
                                        .trim()
                                        .toLowerCase(),
                                    experience:
                                        experienceController.text.trim(),
                                  ),
                                );
                                Navigator.pop(context);
                              },
                              style: TextButton.styleFrom(
                                backgroundColor:
                                    AppStyles().getButtonColor(context),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                              ),
                              child: Text(
                                Texts.translate('guardar', globalLanguage),
                                style: AppStyles().getTextStyle(context),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Profile Picture and Banner (sin cambios)
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          Container(
                            height: 120,
                            color: Colors.blue.shade200,
                          ),
                          Positioned(
                            left: 16,
                            bottom: -40,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 4,
                                ),
                              ),
                              child: CircleAvatar(
                                backgroundColor: Colors.blue.shade100,
                                radius: 80,
                                child: RandomAvatar(
                                  FirebaseAuth.instance.currentUser?.email ??
                                      'U',
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 50),

                      // Expert Mode Toggle
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isExpertMode
                                ? Colors.blue.withOpacity(0.1)
                                : Colors.grey.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
                            border: Border.all(
                              color: isExpertMode
                                  ? Colors.blue.withOpacity(0.3)
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.workspace_premium,
                                    color: isExpertMode
                                        ? Colors.blue
                                        : Colors.grey,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Modo Experto SAP',
                                          style: TextStyle(
                                            fontWeight: FontWeight.bold,
                                            color: isExpertMode
                                                ? Colors.blue
                                                : Colors.grey[700],
                                          ),
                                        ),
                                        Text(
                                          'Activa esta opción si quieres ofrecer servicios de consultoría SAP',
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Switch(
                                    value: isExpertMode,
                                    onChanged: (value) {
                                      setState(() {
                                        isExpertMode = value;
                                      });
                                    },
                                    activeColor: Colors.blue,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),

                      // Form Fields
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            _buildTextField(
                              controller: nameController,
                              label: Texts.translate(
                                  'nombreField', globalLanguage),
                              maxLength: 50,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: bioController,
                              label:
                                  Texts.translate('bioField', globalLanguage),
                              maxLength: charLimit,
                              maxLines: 3,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: locationController,
                              label: Texts.translate(
                                  'locationField', globalLanguage),
                              prefixIcon: Icons.location_on_outlined,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: websiteController,
                              label: Texts.translate(
                                  'websiteField', globalLanguage),
                              prefixIcon: Icons.link,
                            ),

                            // Campos adicionales para modo experto
                            if (isExpertMode) ...[
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: specialtyController,
                                label: 'Especialidad SAP',
                                prefixIcon: Icons.work_outline,
                                hint: 'Ej: ABAP, FI, SD, MM, etc.',
                              ),
                              _buildTextField(
                                controller: experienceController,
                                label: 'Experiencia/Proyectos realizados',
                                maxLines: 3,
                                maxLength: 200,
                                hint: 'Ej: 5 años de experiencia en...',
                              ),
                              const SizedBox(height: 16),
                              _buildTextField(
                                controller: rateController,
                                label: 'Tarifa por hora',
                                prefixIcon: Icons.euro,
                                hint: 'Ej: 60',
                                keyboardType: TextInputType.number,
                                inputFormatters: [
                                  FilteringTextInputFormatter.digitsOnly,
                                ],
                                suffix: const Text('€/h'),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  static Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    IconData? prefixIcon,
    int? maxLength,
    int maxLines = 1,
    String? hint,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    Widget? suffix,
  }) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: maxLines,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
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
          borderRadius:BorderRadius.circular(AppStyles.borderRadiusValue),
          borderSide: const BorderSide(
            color: Colors.blue,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }
}
