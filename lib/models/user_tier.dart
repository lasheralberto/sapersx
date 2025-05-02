import 'package:flutter/material.dart';

class UserTier {
  final String level;
  final Color color;
  final String description;

  const UserTier._internal(this.level, this.color, this.description);

  static const L1 =
      UserTier._internal('L1', Color(0xFF9E9E9E), 'Novice'); // Grey
  static const L2 =
      UserTier._internal('L2', Color(0xFF4CAF50), 'Advanced'); // Green
  static const L3 =
      UserTier._internal('L3', Color(0xFF2196F3), 'Expert'); // Blue
  static const L4 =
      UserTier._internal('L4', Color(0xFF9C27B0), 'Master'); // Purple
  static const L5 =
      UserTier._internal('L5', Color(0xFFFFD700), 'Elite'); // Gold

  static UserTier fromString(String level) {
    switch (level.toUpperCase()) {
      case 'L2':
        return L2;
      case 'L3':
        return L3;
      case 'L4':
        return L4;
      case 'L5':
        return L5;
      default:
        return L1;
    }
  }
}
