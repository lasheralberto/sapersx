import 'package:flutter/material.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/models/project.dart';

class StackedAvatars extends StatelessWidget {
  final List<Member> members;
  final double overlap;
  final int maxDisplayed;
  final double minAvatarSize;
  final double maxAvatarSize;
  final bool showTooltips;
  final bool showBorder;

  const StackedAvatars({
    Key? key,
    required this.members,
    this.overlap = 0.25,
    this.maxDisplayed = 5,
    this.minAvatarSize = 24,
    this.maxAvatarSize = 40,
    this.showTooltips = true,
    this.showBorder = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final effectiveMembers = members.take(maxDisplayed).toList();
    final hasOverflow = members.length > maxDisplayed;
    final totalAvatars = effectiveMembers.length + (hasOverflow ? 1 : 0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final maxHeight = constraints.maxHeight;

        // 1. Cálculo base del tamaño del avatar
        double avatarSize =
            _calculateBaseSize(maxWidth, maxHeight, totalAvatars);

        // 2. Ajuste final considerando densidad de pantalla
        final media = MediaQuery.of(context);
        avatarSize = avatarSize / media.devicePixelRatio;

        // 3. Validación de tamaño mínimo/máximo
        avatarSize = avatarSize.clamp(minAvatarSize, maxAvatarSize);

        return SizedBox(
          height: avatarSize,
          width: _calculateTotalWidth(avatarSize, totalAvatars),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < totalAvatars; i++)
                _buildAvatar(
                  context,
                  index: i,
                  avatarSize: avatarSize,
                  member: i < effectiveMembers.length
                      ? effectiveMembers[i]
                      : Member(
                          memberId: '',
                          userInfo: effectiveMembers[i]
                              .userInfo), // Provide a default Member object
                  isOverflow: hasOverflow && i == totalAvatars - 1,
                  overflowCount: members.length - maxDisplayed,
                ),
            ],
          ),
        );
      },
    );
  }

  double _calculateBaseSize(
      double maxWidth, double maxHeight, int totalAvatars) {
    // Tamaño basado en el ancho disponible y cantidad de avatares
    final widthBasedSize =
        (maxWidth / (1 + (totalAvatars - 1) * (1 - overlap)));

    // Tamaño basado en alto disponible
    final heightBasedSize = maxHeight * 0.9;

    // Usar el menor de los dos valores
    return widthBasedSize < heightBasedSize ? widthBasedSize : heightBasedSize;
  }

  double _calculateTotalWidth(double avatarSize, int totalAvatars) {
    return avatarSize * (1 + (totalAvatars - 1) * (1 - overlap));
  }

  Widget _buildAvatar(
    BuildContext context, {
    required int index,
    required double avatarSize,
    required Member member,
    required bool isOverflow,
    required int overflowCount,
  }) {
    final borderColor = Theme.of(context).colorScheme.surface;
    final borderRadius = avatarSize / 2;

    return Positioned(
      left: index * avatarSize * (1 - overlap),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        width: avatarSize,
        height: avatarSize,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          border: showBorder
              ? Border.all(
                  color: borderColor,
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignOutside,
                )
              : null,
          boxShadow: [
            if (showBorder)
              const BoxShadow(
                color: Colors.black12,
                blurRadius: 6,
                offset: Offset(0, 2),
              ),
          ],
        ),
        child: isOverflow
            ? _buildOverflowCounter(context, avatarSize, overflowCount)
            : _buildProfileAvatar(context, avatarSize, member),
      ),
    );
  }

  Widget _buildProfileAvatar(BuildContext context, double size, Member member) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(size / 2),
        onTap: () {}, // Añadir lógica de tap si es necesario
        child: showTooltips
            ? Tooltip(
                message: member.memberId,
                preferBelow: false,
                verticalOffset: -size,
                child: ProfileAvatar(
                  seed: member.memberId,
                  size: size - (showBorder ? 4 : 0),
                  showBorder: member.userInfo.isExpert as bool,
                ),
              )
            : ProfileAvatar(
                showBorder: member.userInfo.isExpert as bool,
                seed: member.memberId,
                size: size - (showBorder ? 4 : 0),
              ),
      ),
    );
  }

  Widget _buildOverflowCounter(BuildContext context, double size, int count) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.secondary,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Text(
          '+$count',
          style: TextStyle(
            color: Theme.of(context).colorScheme.onPrimaryContainer,
            fontWeight: FontWeight.bold,
            fontSize: size * 0.35,
            letterSpacing: -0.5,
          ),
        ),
      ),
    );
  }
}
