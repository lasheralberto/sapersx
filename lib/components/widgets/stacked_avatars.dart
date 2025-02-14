import 'package:flutter/material.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';
import 'package:sapers/models/project.dart';

class StackedAvatars extends StatelessWidget {
  final List<Member> members;
  final double
      overlap; // Value between 0 and 1, where 0 means no overlap and 1 means complete overlap
  final int maxDisplayed;
  final double minAvatarSize;
  final double maxAvatarSize;
  final bool showTooltips;
  final bool showBorder;

  const StackedAvatars({
    Key? key,
    required this.members,
    this.overlap = 0.25, // 25% overlap by default
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

        double avatarSize =
            _calculateBaseSize(maxWidth, maxHeight, totalAvatars);

        // Adjust for device pixel ratio
        final media = MediaQuery.of(context);
        avatarSize = avatarSize / media.devicePixelRatio;

        // Clamp size within bounds
        avatarSize = avatarSize.clamp(minAvatarSize, maxAvatarSize);

        // Calculate total width needed
        final totalWidth = _calculateTotalWidth(avatarSize, totalAvatars);

        return SizedBox(
          height: avatarSize,
          width: totalWidth,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (int i = 0; i < totalAvatars; i++)
                Positioned(
                  // Key positioning change: multiply by overlap factor
                  left: i * (avatarSize * (1 - overlap)),
                  child: _buildAvatar(
                    context,
                    index: i,
                    avatarSize: avatarSize,
                    member: i < effectiveMembers.length
                        ? effectiveMembers[i]
                        : effectiveMembers.last,
                    isOverflow: hasOverflow && i == totalAvatars - 1,
                    overflowCount: members.length - maxDisplayed,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  double _calculateBaseSize(
      double maxWidth, double maxHeight, int totalAvatars) {
    // Calculate size based on available width and number of avatars
    // Account for overlap in width calculation
    final widthBasedSize =
        maxWidth / (totalAvatars - ((totalAvatars - 1) * overlap));

    // Use 90% of available height as maximum
    final heightBasedSize = maxHeight * 0.9;

    // Return smaller of the two to ensure fitting in container
    return widthBasedSize < heightBasedSize ? widthBasedSize : heightBasedSize;
  }

  double _calculateTotalWidth(double avatarSize, int totalAvatars) {
    if (totalAvatars <= 1) return avatarSize;
    // Calculate total width accounting for overlap
    return avatarSize + (avatarSize * (1 - overlap) * (totalAvatars - 1));
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

    return AnimatedContainer(
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
    );
  }

  Widget _buildProfileAvatar(BuildContext context, double size, Member member) {
    return Material(
      type: MaterialType.transparency,
      child: showTooltips
          ? Tooltip(
              message: member.memberId,
              preferBelow: false,
              verticalOffset: -size,
              child: ProfileAvatar(
                seed: member.memberId,
                size: size - (showBorder ? 4 : 0),
                userInfoPopUp: member.userInfo,
                showBorder: member.userInfo.isExpert as bool,
              ),
            )
          : ProfileAvatar(
              userInfoPopUp: member.userInfo,
              showBorder: member.userInfo.isExpert as bool,
              seed: member.memberId,
              size: size - (showBorder ? 4 : 0),
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
