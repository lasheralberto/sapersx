import 'package:flutter/material.dart';
import 'package:sapers/components/screens/project_screen.dart';
import 'package:sapers/components/widgets/stacked_avatars.dart';
import 'package:sapers/models/project.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final bool isMobile;

  const ProjectCard({
    Key? key,
    required this.project,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Usamos LayoutBuilder para obtener el ancho asignado a la tarjeta
    return LayoutBuilder(
      builder: (context, constraints) {
        // Definimos una base de 400 px; si el ancho asignado es menor, el scale será < 1
        double scale = constraints.maxWidth / 350;

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Card(
          elevation: 2,
          margin: EdgeInsets.all(isMobile ? 4 * scale : 8 * scale),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * scale),
            side: BorderSide(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(16 * scale),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProjectDetailScreen(project: project),
                ),
              );
            },
            hoverColor: colorScheme.primary.withOpacity(0.05),
            splashColor: colorScheme.primary.withOpacity(0.1),
            child: SizedBox.expand(
              child: Padding(
                padding: EdgeInsets.all(16.0 * scale),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 40 * scale,
                          height: 40 * scale,
                          decoration: BoxDecoration(
                            color: _getProjectColor(project.projectid),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.work_outline,
                            color: colorScheme.onPrimary,
                            size: 20 * scale,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          icon: Icon(Icons.more_vert, size: 20 * scale),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    SizedBox(height: 12 * scale),
                    // Título
                    Text(
                      project.projectName.toUpperCase(),
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontSize: (theme.textTheme.titleLarge?.fontSize ?? 20) *
                            scale,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5 * scale,
                        color: colorScheme.primary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 16 * scale),
                    // Metadatos
                    _buildMetadataRow(
                      icon: Icons.person_outline,
                      text: project.createdBy,
                      context: context,
                      scale: scale,
                    ),
                    SizedBox(height: 8 * scale),
                    _buildMetadataRow(
                      icon: Icons.calendar_today_outlined,
                      text: project.createdIn,
                      context: context,
                      scale: scale,
                    ),
                    SizedBox(height: 16 * scale),
                    // Progress Bar
                    SizedBox(
                      height: 6 * scale,
                      child: LinearProgressIndicator(
                        value: 0.75,
                        backgroundColor: colorScheme.surfaceVariant,
                        color: _getProjectColor(project.projectid),
                        minHeight: 6 * scale,
                      ),
                    ),
                    SizedBox(height: 12 * scale),
                    // Miembros
                    SizedBox(
                      height: 24 * scale,
                      child: Row(
                        children: [
                          Column(
                            children: [
                              const SizedBox(
                                height: 5,
                              ),
                              Expanded(
                                child: StackedAvatars(members: project.members),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMetadataRow({
    required IconData icon,
    required String text,
    required BuildContext context,
    required double scale,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16 * scale,
          color: Theme.of(context).colorScheme.outline,
        ),
        SizedBox(width: 8 * scale),
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize:
                      (Theme.of(context).textTheme.bodyMedium?.fontSize ?? 14) *
                          scale,
                  color:
                      Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildMemberAvatars(List<String> members, double scale) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (int i = 0; i < (members.length > 3 ? 3 : members.length); i++)
          Positioned(
            left: i * 20.0 * scale,
            child: CircleAvatar(
              radius: 12 * scale,
              backgroundColor: Colors.primaries[i % Colors.primaries.length],
              child: Text(
                members.isNotEmpty && members[i].isNotEmpty
                    ? members[i][0].toUpperCase()
                    : '?',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12 * scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
        if (members.length > 3)
          Positioned(
            left: 60.0 * scale,
            child: CircleAvatar(
              radius: 12 * scale,
              backgroundColor: Colors.grey.shade300,
              child: Text(
                '+${members.length - 3}',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontSize: 10 * scale,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Color _getProjectColor(String projectId) {
    final colors = [
      Colors.blueAccent,
      Colors.greenAccent,
      Colors.orangeAccent,
      Colors.purpleAccent,
    ];
    return colors[projectId.hashCode % colors.length];
  }
}
