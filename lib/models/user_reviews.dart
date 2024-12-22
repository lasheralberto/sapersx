class UserReviews {
  final String username;
  final List<String> review;
  final String date = DateTime.now().toString();
  final String rating;
  final int countReviews = 0;

  UserReviews(
      {required this.username,
      required this.review,
      date,
      required this.rating, 
      countReviews});

  factory UserReviews.fromMap(Map<String, dynamic> map) {
    return UserReviews(
      username: map['username'],
      review: map['review'],
      date: map['date'],
      rating: map['rating'],
      countReviews: map['countReviews'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'username': username,
      'review': review,
      'date': date,
      'rating': rating,
      'countReviews': countReviews,
    };
  }
}
