import 'package:flutter/material.dart';
import 'package:sapers/models/styles.dart';

enum ButtonVariant { filled, outlined, text }

class CustomButton extends StatefulWidget {
  final String text;
  final String? subtext;
  final VoidCallback onPressed;
  final bool isLoading;
  final double? width;
  final ButtonVariant variant;
  final IconData? leadingIcon;
  final IconData? trailingIcon;
  final bool disabled;
  final Color? customColor;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.subtext,
    this.isLoading = false,
    this.width,
    this.variant = ButtonVariant.filled,
    this.leadingIcon,
    this.trailingIcon,
    this.disabled = false,
    this.customColor,
  });

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnimation;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _setupAnimation();
  }

  void _setupAnimation() {
    _pressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurvedAnimation(parent: _pressController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  ButtonStyle _getButtonStyle(BuildContext context, AppStyles styles) {
    final theme = Theme.of(context);
    final defaultColor = widget.customColor ?? AppStyles.sendButtonColor;

    final baseStyle = ButtonStyle(
      elevation: WidgetStateProperty.all(0),
      overlayColor: WidgetStateProperty.all(Colors.transparent),
      textStyle: WidgetStateProperty.all(styles.getTextStyle(context)),
      shape: WidgetStateProperty.all(
        RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue)),
      ),
    );

    switch (widget.variant) {
      case ButtonVariant.filled:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return theme.colorScheme.onSurface.withOpacity(0.12);
            }
            return states.contains(WidgetState.pressed)
                ? defaultColor.withOpacity(0.9)
                : defaultColor;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? theme.colorScheme.onSurface.withOpacity(0.38)
                : Colors.white;
          }),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );

      case ButtonVariant.outlined:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.pressed)
                ? defaultColor.withOpacity(0.1)
                : Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? theme.colorScheme.onSurface.withOpacity(0.38)
                : defaultColor;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            return BorderSide(
              color: states.contains(WidgetState.disabled)
                  ? theme.colorScheme.onSurface.withOpacity(0.12)
                  : defaultColor,
            );
          }),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
        );

      case ButtonVariant.text:
        return baseStyle.copyWith(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.pressed)
                ? defaultColor.withOpacity(0.1)
                : Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            return states.contains(WidgetState.disabled)
                ? theme.colorScheme.onSurface.withOpacity(0.38)
                : defaultColor;
          }),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          ),
        );
    }
  }

  Widget _buildButtonContent(BuildContext context) {
    if (widget.isLoading) {
      return const SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (widget.leadingIcon != null) ...[
          Icon(widget.leadingIcon, size: 16),
          const SizedBox(width: 8),
        ],
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(widget.text, style: AppStyles().getButtontTextStyle(context)),
            if (widget.subtext != null) ...[
              const SizedBox(height: 2),
              Text(widget.subtext!, style: AppStyles().getTextStyle(context)),
            ],
          ],
        ),
        if (widget.trailingIcon != null) ...[
          const SizedBox(width: 8),
          Icon(widget.trailingIcon, size: 16),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final styles = AppStyles();

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: SizedBox(
            width: widget.width,
            child: Listener(
              onPointerDown: (_) {
                if (!widget.disabled && !widget.isLoading) {
                  setState(() => _isPressed = true);
                  _pressController.forward();
                }
              },
              onPointerUp: (_) {
                if (!widget.disabled && !widget.isLoading) {
                  setState(() => _isPressed = false);
                  _pressController.reverse();
                }
              },
              child: ElevatedButton(
                onPressed: (widget.disabled || widget.isLoading)
                    ? null
                    : widget.onPressed,
                style: _getButtonStyle(context, styles),
                child: _buildButtonContent(context),
              ),
            ),
          ),
        );
      },
    );
  }
}
