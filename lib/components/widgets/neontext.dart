import 'package:flutter/material.dart';

class NeonChatText extends StatefulWidget {
  final bool isPanelClosed;

  const NeonChatText({Key? key, required this.isPanelClosed}) : super(key: key);

  @override
  _NeonChatTextState createState() => _NeonChatTextState();
}

class _NeonChatTextState extends State<NeonChatText> 
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _glowAnimation = Tween<double>(begin: 0.5, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: widget.isPanelClosed ? 1.0 : 0.0,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Text(
              'Chatea con sapIA',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[200],
                shadows: [
                  Shadow(
                    color: Colors.orange.withOpacity(_glowAnimation.value * 0.7),
                    blurRadius: 10 * _glowAnimation.value,
                    offset: const Offset(0, 0),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
