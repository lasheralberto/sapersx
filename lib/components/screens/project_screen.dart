import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/components/widgets/stacked_avatars.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/user.dart';

class ProjectDetailScreen extends StatefulWidget {
  final Project project;

  ProjectDetailScreen({
    Key? key,
    required this.project,
  }) : super(key: key);

  @override
  State<ProjectDetailScreen> createState() => _ProjectDetailScreenState();
}

class _ProjectDetailScreenState extends State<ProjectDetailScreen> {
  final FirebaseService _firebaseService = FirebaseService();
  bool isOwner = false;

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    isOwnerCheck().then((value) {
      setState(() {
        isOwner = value;
      });
    });
  }

  Future<bool> isOwnerCheck() async {
    final userinfo = await FirebaseService().getUserInfoByEmail(
        FirebaseAuth.instance.currentUser!.email.toString());
    return widget.project.createdBy == userinfo!.username;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: MediaQuery.of(context).size.height * 0.3,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeader(context),
            ),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (isOwner)
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () => _editProjectDetails(context),
                ),
            ],
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProjectDescription(context),
                  const SizedBox(height: 30),
                  _buildRequirementsSection(context, isOwner),
                  const SizedBox(height: 30),
                  _buildMemberSection(context, widget.project.members),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: isOwner
          ? FloatingActionButton(
              backgroundColor:
                  AppStyles().getProjectCardColor(widget.project.projectid),
              child: const Icon(Icons.add, color: Colors.white),
              onPressed: () => _addRequirement(context),
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppStyles().getProjectCardColor(widget.project.projectid),
            AppStyles().getProjectCardColor(widget.project.projectid),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                widget.project.projectName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  shadows: [
                    Shadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 10,
                      offset: const Offset(2, 2),
                    )
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectDescription(BuildContext context) {
    return Card(
      color: Colors.white,
      elevation: AppStyles().getCardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Descripción del Proyecto',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 10),
            Text(
              widget.project.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRequirementsSection(BuildContext context, bool isOwner) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Requerimientos',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            if (isOwner)
              IconButton(
                icon: const Icon(Icons.edit),
                onPressed: () => _editRequirements(context),
              ),
          ],
        ),
        const SizedBox(height: 15),
        StreamBuilder<QuerySnapshot>(
          stream: _firebaseService
              .getProjectRequirementsStream(widget.project.projectid),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError) {
              return Center(child: Text('Error: ${snapshot.error}'));
            }
            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return const Center(child: Text('No hay requerimientos'));
            }

            final requirements = snapshot.data!.docs;
            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: requirements.length,
              itemBuilder: (context, index) {
                final requirement = requirements[index];
                final data = requirement.data() as Map<String, dynamic>;
                return _buildRequirementItem(
                    requirement.id, data, isOwner, context);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildRequirementItem(
      String id, Map<String, dynamic> data, bool isOwner, context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        title: Text(data['title']),
        subtitle: Text(data['description']),
        trailing: isOwner
            ? IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () => _deleteRequirement(id, context),
              )
            : null,
        onTap: () => _editRequirement(id, data, context),
      ),
    );
  }

  Widget _buildMemberSection(BuildContext context, List<Member> members) {
    return StackedAvatars(members: members);
  }

  void _addRequirement(BuildContext context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => const RequirementDialog(),
    );

    if (result != null) {
      await _firebaseService.addProjectRequirement(
        projectId: widget.project.projectid,
        title: result['title'],
        description: result['description'],
      );
    }
  }

  void _editRequirement(String id, Map<String, dynamic> data, context) async {
    final result = await showDialog(
      context: context,
      builder: (context) => RequirementDialog(initialData: data),
    );

    if (result != null) {
      await _firebaseService.updateProjectRequirement(
        projectId: widget.project.projectid,
        requirementId: id,
        title: result['title'],
        description: result['description'],
      );
    }
  }

  void _deleteRequirement(String id, context) async {
    final confirm = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Requerimiento'),
        content: const Text('¿Estás seguro de eliminar este requerimiento?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await _firebaseService.deleteProjectRequirement(
        projectId: widget.project.projectid,
        requirementId: id,
      );
    }
  }

  void _editProjectDetails(BuildContext context) {
    // Implementar lógica para editar detalles del proyecto
  }

  void _editRequirements(BuildContext context) {
    // Implementar lógica para editar múltiples requerimientos
  }
}

class RequirementDialog extends StatefulWidget {
  final String? requirementId;
  final Map<String, dynamic>? initialData;

  const RequirementDialog({this.requirementId, this.initialData});

  @override
  _RequirementDialogState createState() => _RequirementDialogState();
}

class _RequirementDialogState extends State<RequirementDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.initialData != null) {
      _titleController.text = widget.initialData!['title'];
      _descriptionController.text = widget.initialData!['description'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.requirementId == null
          ? 'Añadir Requerimiento'
          : 'Editar Requerimiento'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Título'),
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Descripción'),
                maxLines: 3,
                validator: (value) => value!.isEmpty ? 'Requerido' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _submit,
          child: const Text('Guardar'),
        ),
      ],
    );
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context, {
        'title': _titleController.text,
        'description': _descriptionController.text,
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }
}
