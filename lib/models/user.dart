// Clase para la información del usuario
import 'package:cloud_firestore/cloud_firestore.dart';

class UserInfoPopUp {
  String uid;
  String username;
  String email;
  String? bio;
  int reputation = 0;
  String level = 'Beginner';
  List<String> badges = [];
  Map<String, int> moduleExpertise = {};
  String? location;
  double? latitude;
  double? longitude;
  String? website;
  bool? isExpert;
  String? specialty;
  double? hourlyRate;
  Timestamp? joinDate;
  bool? isAvailable;
  String? experience;
  List<String>? following;
  List<String>? followers;
  List<Map<String, dynamic>>? reviews;
  int? weeklyPoints;
  String? userTier;

  UserInfoPopUp(
      {required this.uid,
      required this.username,
      required this.email,
      this.bio,
      this.location,
      this.latitude,
      this.longitude,
      this.website,
      this.isExpert,
      this.specialty,
      this.hourlyRate,
      this.isAvailable,
      this.joinDate,
      this.experience,
      this.following,
      this.followers,
      this.weeklyPoints = 0,
      this.userTier = 'L1',
      this.reviews});

  // Convertir objeto a Map para guardarlo en Firebase
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'username': username,
      'email': email,
      'bio': bio,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'website': website,
      'isExpert': isExpert,
      'specialty': specialty,
      'hourlyRate': hourlyRate,
      'following': following,
      'followers': followers,
      'joinDate': joinDate,
      'isAvailable': isAvailable,
      'weeklyPoints': weeklyPoints,
      'experience': experience,
      'reviews': reviews,
      'userTier': userTier,
    };
  }

  // Crear un objeto UserInfo desde un documento de Firebase
  factory UserInfoPopUp.fromMap(Map<String, dynamic> map) {
    return UserInfoPopUp(
      uid: map['uid'] as String? ?? '', // Manejo seguro de nulos
      username: map['username'] as String? ?? 'Usuario anónimo',
      email: map['email'] as String? ?? '',
      bio: map['bio'] as String?,
      location: map['location'] as String?,
      latitude: map['latitude'] as double?,
      longitude: map['longitude'] as double?,
      website: map['website'] as String?,
      isExpert: map['isExpert'] as bool? ?? false,
      specialty: map['specialty'] as String?,
      hourlyRate: _parseDouble(map['hourlyRate']), // Función auxiliar
      following: _parseStringList(map['following']), // Función auxiliar
      followers: _parseStringList(map['followers']), // Función auxiliar
      joinDate: map['joinDate'] != null ? map['joinDate'] as Timestamp : null,
      isAvailable: map['isAvailable'] as bool? ?? false,
      reviews: _parseReviews(map['reviews']), // Función auxiliar
      weeklyPoints: map['weeklyPoints'] as int? ?? 0,
      userTier: map['userTier'] as String? ?? 'L1',
      experience: map['experience'] as String?,
    );
  }

// Añade estas funciones auxiliares al final de tu clase
  static double _parseDouble(dynamic value) {
    if (value == null) return 0.0;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    return double.tryParse(value.toString()) ?? 0.0;
  }

  static List<String> _parseStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<String>().toList();
    return [];
  }

  static List<Map<String, dynamic>> _parseReviews(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.cast<Map<String, dynamic>>().toList();
    return [];
  }
}
