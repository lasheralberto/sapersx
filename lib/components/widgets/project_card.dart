import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sapers/components/screens/project_screen.dart';
import 'package:sapers/components/widgets/stacked_avatars.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/user.dart';

class ProjectCard extends StatelessWidget {
  final Project project;
  final bool isMobile;
  final UserInfoPopUp userinfo;

  const ProjectCard({
    Key? key,
    required this.project,
    required this.userinfo,
    this.isMobile = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        double scale = constraints.maxWidth / 500;

        // Definimos una altura fija más pequeña para garantizar el aspecto rectangular
        double fixedHeight = 120.0 * scale; // Altura base más pequeña

        final theme = Theme.of(context);
        final colorScheme = theme.colorScheme;

        return Card(
          color: Colors.white,
          elevation: 2,
          margin: EdgeInsets.all(isMobile ? 4 * scale : 8 * scale),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8 * scale),
            side: BorderSide(
              color: colorScheme.outline.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: InkWell(
            borderRadius: BorderRadius.circular(8 * scale),
            onTap: () {
              context.go('/project/${project.projectid}', extra: project);
 
            },
            hoverColor: colorScheme.primary.withOpacity(0.05),
            splashColor: colorScheme.primary.withOpacity(0.1),
            child: SizedBox(
              // Cambiamos Container por SizedBox para mayor eficiencia
              height: fixedHeight, // Usamos la altura fija
              child: Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: 16.0 * scale,
                  vertical: 12.0 * scale,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 45 *
                          scale, // Reducimos ligeramente el tamaño del ícono
                      height: 45 * scale,
                      decoration: BoxDecoration(
                        color:
                            AppStyles().getProjectCardColor(project.projectid),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.work_outline,
                        color: colorScheme.onPrimary,
                        size: 22 * scale,
                      ),
                    ),
                    SizedBox(width: 16 * scale),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            project.projectName.toUpperCase(),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontSize:
                                  (theme.textTheme.titleLarge?.fontSize ?? 20) *
                                      scale,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.5 * scale,
                              color: colorScheme.primary,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          SizedBox(height: 8 * scale),
                          _buildMetadataRow(
                            icon: Icons.person_outline,
                            text: project.createdBy,
                            context: context,
                            scale: scale,
                          ),
                        ],
                      ),
                    ),
                    StackedAvatars(
                      members: project.members,
                      maxDisplayed: 2,
                      overlap: 0.35,
                      minAvatarSize: 30,
                      maxAvatarSize: 35,
                      showTooltips: false,
                      showBorder: true,
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
}
