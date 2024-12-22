// Clase para la información del usuario
class UserInfoPopUp {
  String uid;
  String username;
  String email;
  String? bio;
  String? location;
  String? website;
  bool? isExpert;
  String? specialty;
  double? hourlyRate;
  String? joinDate;
  bool? isAvailable;
  String? experience;
  List<Map<String,dynamic>>? reviews;

  UserInfoPopUp({
    required this.uid,
    required this.username,
    required this.email,
    this.bio,
    this.location,
    this.website,
    this.isExpert,
    this.specialty,
    this.hourlyRate,
    this.isAvailable,
    this.joinDate,
    this.experience,
    this.reviews
  });

  // Convertir objeto a Map para guardarlo en Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'bio': bio,
      'location': location,
      'website': website,
      'isExpert': isExpert,
      'specialty': specialty,
      'hourlyRate': hourlyRate,
      'joinDate': joinDate,
      'isAvailable': isAvailable,
      'experience': experience,
      'reviews': reviews
    };
  }

  // Crear un objeto UserInfo desde un documento de Firebase
  factory UserInfoPopUp.fromMap(Map<String, dynamic> map) {
    return UserInfoPopUp(
        uid: map['uid'] ?? '',
        username: map['username'] ?? '',
        email: map['email'] ?? '',
        bio: map['bio'] ?? '',
        location: map['location'] ?? '',
        website: map['website'] ?? '',
        isExpert: map['isExpert'] ?? false,
        specialty: map['specialty'] ?? '',
        hourlyRate: (map['hourlyRate'] ?? 0.0).toDouble(),
        joinDate: map['joinDate'] ?? DateTime.now().toString(),
        isAvailable: map['isAvailable'] ?? false,
        reviews: map['reviews'] ?? [],
        experience: map['experience'] ?? '');
  }
}
