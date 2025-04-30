import 'package:flutter/material.dart';
import 'package:sapers/models/styles.dart';

class CommentButton extends StatelessWidget {
  final int replyCount;
  final double iconSize;
  final Color iconColor;
  final VoidCallback? onPressed; // Add this line

  const CommentButton({
    Key? key,
    required this.replyCount,
    required this.iconSize,
    required this.iconColor,
    this.onPressed, // Add this line
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onPressed, // Add this line
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.mode_comment_outlined,
            size: iconSize,
            weight: 100.0,
            color: iconColor ?? Theme.of(context).iconTheme.color,
          ),
          const SizedBox(width: 5),
          Text(
            replyCount.toString(),
            style: TextStyle(
              color: iconColor ?? Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: iconSize * 0.8,
            ),
          ),
        ],
      ),
    );
  }
}
