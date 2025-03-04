import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:sapers/components/screens/login_dialog.dart';
import 'package:sapers/models/firebase_service.dart';
import 'package:sapers/models/styles.dart';

class LikeButton extends StatefulWidget {
  final String postId;
  final String replyId;
  final int initialLikeCount;

  const LikeButton({
    Key? key,
    required this.postId,
    required this.replyId,
    required this.initialLikeCount,
  }) : super(key: key);

  @override
  _LikeButtonState createState() => _LikeButtonState();
}

class _LikeButtonState extends State<LikeButton>
    with SingleTickerProviderStateMixin {
  late Future<bool> _hasLikedFuture;
  final FirebaseService _likeService = FirebaseService();
  int _likeCount = 0;
  bool _isLiking = false;
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _likeCount = widget.initialLikeCount;
    _hasLikedFuture =
        _likeService.hasUserLiked(widget.postId, widget.replyId, context);

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1),
      vsync: this,
    );

    _scaleAnimation = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.5)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.5, end: 1.0)
            .chain(CurveTween(curve: Curves.elasticIn)),
        weight: 50,
      ),
    ]).animate(_controller);
  }

  void _showLoginDialog(BuildContext context) {
       Navigator.push(
  context,
  MaterialPageRoute(
    fullscreenDialog: true,
    builder: (context) => const LoginScreen(),
  ),
);
  }

  Future<void> _handleLikePress() async {
    if (FirebaseAuth.instance.currentUser == null) {
      _showLoginDialog(context);
      return;
    }

    if (_isLiking) return;
    setState(() => _isLiking = true);

    try {
      bool currentLikeState = await _hasLikedFuture;
      await _likeService.toggleLike(widget.postId, widget.replyId, context);
      _controller.forward().then((_) => _controller.reset());

      setState(() {
        _hasLikedFuture = Future.value(!currentLikeState);
        _likeCount += currentLikeState ? -1 : 1;
      });
    } finally {
      setState(() => _isLiking = false);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _hasLikedFuture,
      builder: (context, snapshot) {
        final hasLiked = snapshot.data ?? false;

        return Row(
          children: [
            InkWell(
              onTap: _isLiking ? null : _handleLikePress,
              child: AnimatedBuilder(
                animation: _scaleAnimation,
                builder: (context, child) => Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Icon(
                      hasLiked
                          ? Icons.thumb_up_alt
                          : Icons.thumb_up_alt_outlined,
                      size: 25,
                      color:
                          hasLiked ? AppStyles.colorAvatarBorder : Colors.grey,
                    ),
                  ),
                ),
              ),
            ),
            Text(
              '$_likeCount',
              style: TextStyle(
                color: hasLiked ? AppStyles.colorAvatarBorder : Colors.grey,
              ),
            ),
          ],
        );
      },
    );
  }
}

// Modelo para manejar los likes
class ReplyLike {
  final String userId;
  final DateTime timestamp;

  ReplyLike({
    required this.userId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'timestamp': timestamp,
    };
  }
}
