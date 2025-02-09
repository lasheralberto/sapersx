import 'package:flutter/material.dart';
import 'package:sapers/components/widgets/profile_avatar.dart';

class StackedAvatars extends StatelessWidget {
  final List<String> members;
  final double overlap; // Cantidad de superposición entre avatares (0-1)
  final int maxDisplayed; // Máximo número de avatares a mostrar
  final double minAvatarSize; // Tamaño mínimo del avatar
  final double maxAvatarSize; // Tamaño máximo del avatar

  const StackedAvatars({
    Key? key,
    required this.members,
    this.overlap = 0.3,
    this.maxDisplayed = 5,
    this.minAvatarSize = 20, // Tamaño mínimo por defecto
    this.maxAvatarSize = 40, // Tamaño máximo por defecto
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Calculamos el tamaño del avatar basado en el espacio disponible
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;

        // Calculamos el tamaño base del avatar según el espacio disponible
        double avatarSize =
            (availableHeight * 0.8).clamp(minAvatarSize, maxAvatarSize);

        // Ajustamos el tamaño si no hay suficiente espacio horizontal
        final totalWidth =
            avatarSize + ((members.length - 1) * avatarSize * (1 - overlap));
        if (totalWidth > availableWidth) {
          // Recalculamos el tamaño para que quepa en el espacio disponible
          avatarSize =
              (availableWidth / (1 + (members.length - 1) * (1 - overlap)))
                  .clamp(minAvatarSize, maxAvatarSize);
        }

        return SizedBox(
          height: avatarSize,
          width: members.isEmpty
              ? 0
              : avatarSize +
                  ((members.length - 1) * avatarSize * (1 - overlap)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              for (var i = 0; i < members.length; i++)
                if (i < maxDisplayed)
                  Positioned(
                    left: i * avatarSize * (1 - overlap),
                    child: Tooltip(
                      message: members[i],
                      child: ProfileAvatar(
                        seed: members[i],
                        size: avatarSize,
                      ),
                    ),
                  )
                else if (i == maxDisplayed)
                  Positioned(
                    left: i * avatarSize * (1 - overlap),
                    child: Container(
                      width: avatarSize,
                      height: avatarSize,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Center(
                        child: Text(
                          '+${members.length - maxDisplayed}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onPrimary,
                            fontWeight: FontWeight.bold,
                            fontSize: avatarSize *
                                0.4, // Texto proporcional al avatar
                          ),
                        ),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
