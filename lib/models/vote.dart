enum VoteType {
  up,
  down,
  none;

  static VoteType fromString(String value) {
    return VoteType.values.firstWhere(
      (e) => e.toString() == 'VoteType.$value',
      orElse: () => VoteType.none,
    );
  }
}

class Vote {
  final String userId;
  final VoteType type;
  final DateTime timestamp;

  Vote({
    required this.userId,
    required this.type,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'type': type.toString().split('.').last,
      'timestamp': timestamp,
    };
  }

  factory Vote.fromMap(Map<String, dynamic> map) {
    return Vote(
      userId: map['userId'] as String,
      type: VoteType.fromString(map['type'] as String),
      timestamp: map['timestamp'].toDate(),
    );
  }
}
