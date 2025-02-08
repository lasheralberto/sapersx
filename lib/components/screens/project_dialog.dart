import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/user.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/main.dart'; // Para UtilsSapers()

class CreateProjectDialog extends StatefulWidget {
  final UserInfoPopUp? user;
  const CreateProjectDialog({Key? key, required this.user}) : super(key: key);

  @override
  State<CreateProjectDialog> createState() => _CreateProjectDialogState();
}

class _CreateProjectDialogState extends State<CreateProjectDialog> {
  final _formKey = GlobalKey<FormState>();
  final _projectNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _tagsController = TextEditingController();

  AppStyles styles = AppStyles();

  @override
  void dispose() {
    _projectNameController.dispose();
    _descriptionController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime date) => DateFormat('dd-MM-yyyy').format(date);

  @override
  Widget build(BuildContext context) {
    double dialogWidth = styles.getMaxWidthDialog(context);
    var mediaQuery = MediaQuery.of(context).size;

    return Dialog(
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: mediaQuery.height,
        ),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Encabezado con título y botón para cerrar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Text(
                        Texts.translate('nuevoProyecto', globalLanguage),
                        style: AppStyles().getTextStyle(
                          context,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Campo para el nombre del proyecto
                TextField(
                  controller: _projectNameController,
                  decoration: styles.getInputDecoration(
                    Texts.translate('nombreDelProyecto', globalLanguage),
                    null,
                    context,
                  ),
                ),
                const SizedBox(height: 16),
                // Campo para la descripción
                TextField(
                  controller: _descriptionController,
                  decoration: styles.getInputDecoration(
                    Texts.translate('descripcion', globalLanguage),
                    null,
                    context,
                  ),
                  maxLines: (mediaQuery.height * 0.2 / 24).round(),
                ),
                const SizedBox(height: 16),
                // Campo para los tags
                TextField(
                  controller: _tagsController,
                  decoration: styles.getInputDecoration(
                    Texts.translate('tagsSeparadosPorComas', globalLanguage),
                    null,
                    context,
                  ),
                ),
                const SizedBox(height: 24),
                // Botones de acción
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        Texts.translate('cancelar', globalLanguage),
                        style: const TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FilledButton(
                      style: styles.getButtonStyle(context),
                      onPressed: () {
                        if (_formKey.currentState!.validate()) {
                          final project = Project(
                            // La lógica se mantiene igual; se asume que el constructor de Project
                            // cuenta con estos campos, incluso si en otra parte de la app se usan otros atributos.
                            projectid: UtilsSapers().generateSimpleUID(),
                            projectName: _projectNameController.text.trim(),
                            description: _descriptionController.text.trim(),
                            tags: _tagsController.text
                                .trim()
                                .split(',')
                                .map((tag) => tag.trim())
                                .toList(),
                            createdBy: widget.user!.username,
                            createdIn: _formatDate(DateTime.now()),
                            members: [],
                          );
                          // FirebaseService().createProject(project);
                          Navigator.of(context).pop(project);
                        }
                      },
                      child: Text(
                        Texts.translate('crear', globalLanguage).toUpperCase(),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
