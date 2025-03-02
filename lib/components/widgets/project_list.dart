import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';
import 'package:go_router/go_router.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:provider/provider.dart';
import 'package:sapers/components/screens/project_screen.dart';
import 'package:sapers/components/widgets/mustbeloggedsection.dart';
import 'package:sapers/components/widgets/stacked_avatars.dart';
import 'package:sapers/main.dart';
import 'package:sapers/models/auth_provider.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/language_provider.dart';
import 'package:sapers/models/project.dart';
import 'package:sapers/models/styles.dart';
import 'package:sapers/models/texts.dart';
import 'package:sapers/models/user.dart';

class ProjectListView extends StatefulWidget {
  final Future<List<Project>> future;
  final bool isMobile;
  final VoidCallback onRefresh;
  final bool isRefreshing;

  const ProjectListView({
    Key? key,
    required this.future,
    required this.isMobile,
    required this.onRefresh,
    this.isRefreshing = false,
  }) : super(key: key);

  @override
  State<ProjectListView> createState() => _ProjectListViewState();
}

class _ProjectListViewState extends State<ProjectListView> {
  UserInfoPopUp? currentUser;
  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    currentUser =
        Provider.of<AuthProviderSapers>(context, listen: false).userInfo;
  }

  @override
  Widget build(BuildContext context) {
    return currentUser == null
        ? LoginRequiredWidget(
            onTap: () {
              AuthService().isUserLoggedIn(context);
            },
          )
        : FutureBuilder<List<Project>>(
            future: widget.future,
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return _buildErrorState(snapshot.error.toString());
              }

              if (snapshot.connectionState == ConnectionState.waiting) {
                return _buildLoadingState();
              }

              final projects = snapshot.data ?? [];
              if (projects.isEmpty) {
                return _buildEmptyState();
              }

              return RefreshIndicator(
                onRefresh: () async => widget.onRefresh(),
                child: CustomScrollView(
                  physics: const BouncingScrollPhysics(),
                  slivers: [
                    if (widget.isRefreshing)
                      SliverToBoxAdapter(
                        child: Container(
                          padding: const EdgeInsets.only(top: 16),
                          child: const Center(
                            child: LinearProgressIndicator(
                              backgroundColor: Colors.transparent,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.blue),
                            ),
                          ),
                        ),
                      ),
                    SliverPadding(
                      padding: EdgeInsets.symmetric(
                        horizontal: widget.isMobile ? 12.0 : 24.0,
                        vertical: 8.0,
                      ),
                      sliver: _buildListView(projects),
                    ),
                    const SliverPadding(padding: EdgeInsets.only(bottom: 24)),
                  ],
                ),
              );
            },
          );
  }

  Widget _buildListView(List<Project> projects) {
    return AnimationLimiter(
      child: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: _buildProjectListCard(projects[index], context),
                ),
              ),
            ),
          ),
          childCount: projects.length,
        ),
      ),
    );
  }

  Widget _buildProjectListCard(Project project, context) {
    return Card(
      color: Theme.of(context).cardColor,
      elevation: AppStyles().getCardElevation(context),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
      ),
      child: InkWell(
        onTap: () => _handleProjectTap(project, context),
        borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
        child: Container(
          //height: 120,
          padding: const EdgeInsets.all(30),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.projectName,
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.description,
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .onSurfaceVariant,
                                  ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    StackedAvatars(
                      maxAvatarSize: 30,
                      members: project.members,
                    ),
                    const SizedBox(
                      height: 14,
                    ),
                    Row(
                      children: [
                        Icon(
                          EvaIcons.person,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          project.createdBy,
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                        const Spacer(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(String error) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 48, color: Colors.red),
          const SizedBox(height: 16),
          SelectableText(
            'Error: $error',
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(
            'Loading projects...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.folder_open, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            Texts.translate('noprojects', LanguageProvider().currentLanguage),
            style: TextStyle(color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: widget.onRefresh,
            icon: const Icon(Icons.refresh),
            label: const Text('Refresh'),
          ),
        ],
      ),
    );
  }

  void _handleProjectTap(Project project, BuildContext context) {
    bool isUserLogued = AuthService().isUserLoggedIn(context);
    if (isUserLogued) {
      context.push('/project/${project.projectid}', extra: project);
// O si prefieres go():
// context.go('/project/${project.id}', extra: project);
      // Navigator.push(
      //   context,
      //   MaterialPageRoute(
      //     builder: (context) => ProjectDetailScreen(
      //       project: project,
      //     ),
      //   ),
      // );
    }
  }
}
