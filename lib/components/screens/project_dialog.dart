import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/utils_sapers.dart'; // Para UtilsSapers()

class CreateProjectScreen extends StatefulWidget {
  final UserInfoPopUp? user;
  const CreateProjectScreen({Key? key, required this.user}) : super(key: key);

  @override
  State<CreateProjectScreen> createState() => _CreateProjectScreenState();
}

class _CreateProjectScreenState extends State<CreateProjectScreen> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();
  bool isCreatingProject = false;

  AppStyles styles = AppStyles();

  @override
  void dispose() {
    _projectNameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) => DateFormat('dd-MM-yyyy').format(date);

  Future<void> _createProject() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        isCreatingProject = true;
      });

      try {
        if (_projectNameController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(Texts.translate('nombreProyectoRequerido', LanguageProvider().currentLanguage)),
            ),
          );
          return;
        }

        final project = Project(
          projectid: UtilsSapers().generateSimpleUID(),
          projectName: _projectNameController.text.trim(),
          description: _descriptionController.text.trim(),
          tags: _tagsController.text
              .trim()
              .split(',')
              .map((tag) => tag.trim())
              .where((tag) => tag.isNotEmpty)
              .toList(),
          createdBy: widget.user!.username,
          createdIn: _formatDate(DateTime.now()),
          members: [],
        );

        // Navegación de regreso con el proyecto creado
        Navigator.of(context).pop(project);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
          ),
        );
      } finally {
        setState(() {
          isCreatingProject = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    var mediaQuery = MediaQuery.of(context).size;
    bool isMobile = mediaQuery.width < 600;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          Texts.translate('nuevoProyecto', LanguageProvider().currentLanguage),
          style: AppStyles().getTextStyle(
            context,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isMobile)
            Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: isCreatingProject
                  ? Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Theme.of(context).colorScheme.onPrimary,
                          strokeWidth: 2,
                        ),
                      ),
                    )
                  : FilledButton(
                      style: styles.getButtonStyle(context),
                      onPressed: _createProject,
                      child: Text(
                        Texts.translate('crear', LanguageProvider().currentLanguage).toUpperCase(),
                      ),
                    ),
            ),
        ],
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints viewportConstraints) {
            return SingleChildScrollView(
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: viewportConstraints.maxHeight,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: Container(
                      constraints: const BoxConstraints(
                        maxWidth: 800, // Ancho máximo para tablets y desktop
                      ),
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Campo para el nombre del proyecto
                            TextField(
                              controller: _projectNameController,
                              decoration: styles.getInputDecoration(
                                Texts.translate('nombreDelProyecto', LanguageProvider().currentLanguage),
                                null,
                                context,
                              ),
                            ),
                            const SizedBox(height: 16),
                            // Campo para la descripción
                            TextField(
                              controller: _descriptionController,
                              decoration: styles.getInputDecoration(
                                Texts.translate('descripcion', LanguageProvider().currentLanguage),
                                null,
                                context,
                              ),
                              maxLines: (mediaQuery.height * 0.3 / 24).round(),
                            ),
                            const SizedBox(height: 16),
                            // Campo para los tags
                            TextField(
                              controller: _tagsController,
                              decoration: styles.getInputDecoration(
                                Texts.translate('tagsSeparadosPorComas', LanguageProvider().currentLanguage),
                                null,
                                context,
                              ),
                            ),
                            if (!isMobile) const SizedBox(height: 24),
                            if (!isMobile)
                              // Botones de acción para tablets y desktop
                              Align(
                                alignment: Alignment.centerRight,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text(
                                        Texts.translate('cancelar', LanguageProvider().currentLanguage),
                                        style: const TextStyle(color: Colors.grey),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                  ],
                                ),
                              ),
                            const SizedBox(height: 50), // Espacio adicional para mejor UX
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
      // Botones para dispositivos móviles
      bottomNavigationBar: isMobile
          ? BottomAppBar(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        Texts.translate('cancelar', LanguageProvider().currentLanguage),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    FilledButton(
                      style: styles.getButtonStyle(context),
                      onPressed: isCreatingProject ? null : _createProject,
                      child: isCreatingProject
                          ? SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Theme.of(context).colorScheme.onPrimary,
                                strokeWidth: 2,
                              ),
                            )
                          : Text(
                              Texts.translate('crear', LanguageProvider().currentLanguage).toUpperCase(),
                            ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}