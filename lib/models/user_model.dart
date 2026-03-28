// lib/models/user_model.dart

class UserModel {
  final String uid;
  final String email;
  final String nomCafe;
  final String nomChef;
  final String role;
  final String? chefId; // null si chef, sinon uid du chef parent
  final DateTime? premiumUntil;

  UserModel({
    required this.uid,
    required this.email,
    required this.nomCafe,
    required this.nomChef,
    required this.role,
    this.chefId,
    this.premiumUntil,
  });

  bool get isChef => role == 'chef';
  bool get isServeur => role == 'serveur';

  UserModel copyWith({
    String? uid,
    String? email,
    String? nomCafe,
    String? nomChef,
    String? role,
    String? chefId,
    DateTime? premiumUntil,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      nomCafe: nomCafe ?? this.nomCafe,
      nomChef: nomChef ?? this.nomChef,
      role: role ?? this.role,
      chefId: chefId ?? this.chefId,
      premiumUntil: premiumUntil ?? this.premiumUntil,
    );
  }

  Map<String, dynamic> toJson() => {
        'uid': uid,
        'email': email,
        'nomCafe': nomCafe,
        'nomChef': nomChef,
        'role': role,
        'chefId': chefId,
        'premiumUntil': premiumUntil?.toIso8601String(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json, String uid) {
    return UserModel(
      uid: uid,
      email: json['email'] ?? '',
      nomCafe: json['nomCafe'] ?? '',
      nomChef: json['nomChef'] ?? '',
      role: json['role'] ?? 'serveur',
      chefId: json['chefId'],
      premiumUntil: json['premiumUntil'] != null
          ? DateTime.tryParse(json['premiumUntil'])
          : null,
    );
  }
}