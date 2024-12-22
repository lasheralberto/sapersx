import 'package:flutter/material.dart';
import 'package:sapers/models/styles.dart';

class CommentButton extends StatelessWidget {
  final int replyCount;
  final VoidCallback? onTap;
  final Color? iconColor;
  final double iconSize;
  final EdgeInsetsGeometry padding;

  const CommentButton({
    super.key,
    required this.replyCount,
    this.onTap,
    this.iconColor,
    this.iconSize = 20.0,
    this.padding = const EdgeInsets.all(8.0),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppStyles.borderRadiusValue),
      child: Padding(
        padding: padding,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.mode_comment_outlined,
              size: iconSize,
              weight: 300.0,
              color: iconColor ?? Theme.of(context).iconTheme.color,
            ),
            const SizedBox(width: 5),
            Text(
              replyCount.toString(),
              style: TextStyle(
                color:
                    iconColor ?? Theme.of(context).textTheme.bodyMedium?.color,
                fontSize: iconSize * 0.8,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
