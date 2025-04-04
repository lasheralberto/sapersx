import 'dart:math';
import 'package:flutter/material.dart';

class NebulaEffect extends StatefulWidget {
  final bool shouldMove;

  const NebulaEffect({Key? key, this.shouldMove = false}) : super(key: key);

  @override
  _NebulaEffectState createState() => _NebulaEffectState();
}

class _NebulaEffectState extends State<NebulaEffect>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _movementController;
  late Animation<double> _scaleAnimation;
  double _dx = 0;
  double _dy = 0;

  final Random _random = Random();

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 3),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 4.1).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _movementController = AnimationController(
      vsync: this,
      duration: Duration(seconds: 10),
    )..addListener(() {
        if (widget.shouldMove) {
          setState(() {
            _dx = (_random.nextDouble() - 0.5) * 5;
            _dy = (_random.nextDouble() - 0.5) * 2;
          });
        }
      });

    if (widget.shouldMove) {
      _movementController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant NebulaEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.shouldMove && !_movementController.isAnimating) {
      _movementController.repeat(reverse: true);
    } else if (!widget.shouldMove && _movementController.isAnimating) {
      _movementController.stop();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _movementController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 20,
      height: 20,
      child: AnimatedBuilder(
        animation: Listenable.merge([_scaleAnimation, _movementController]),
        builder: (context, child) {
          return Center(
            child: Transform.translate(
              offset: Offset(_dx, _dy),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Neblina exterior
                  Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            Colors.deepOrange.withOpacity(0.15),
                            Colors.orange.withOpacity(0.08),
                            Colors.transparent
                          ],
                          stops: const [0.2, 0.7, 1.0],
                        ),
                      ),
                    ),
                  ),
                  // Capa media
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.orangeAccent.withOpacity(0.3),
                          Colors.deepOrange.withOpacity(0.2),
                          Colors.orange,
                          Colors.transparent,
                        ],
                        stops: const [0.1, 0.6, 1.0, 1.5],
                      ),
                    ),
                  ),
                  // Glow intenso
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white,
                          Colors.deepOrangeAccent.withOpacity(0.6),
                          Colors.deepOrange.withOpacity(0.1),
                          Colors.transparent
                        ],
                        stops: const [0.1, 0.2, 1.0, 2.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
