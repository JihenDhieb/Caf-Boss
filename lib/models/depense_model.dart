// lib/models/depense_model.dart
import 'package:cloud_firestore/cloud_firestore.dart';

class Depense {
  final String id;       // ✅ Added
  final String chefId;   // ✅ Added
  final double montant;
  final String note;
  final DateTime date;

  Depense({
    required this.id,
    required this.chefId,
    required this.montant,
    required this.note,
    required this.date,
  });

  Map<String, dynamic> toJson() => {
        'chefId': chefId,  // ✅ Added
        'montant': montant,
        'note': note,
        'date': date.toIso8601String(),
      };

  factory Depense.fromJson(Map<String, dynamic> json, [String id = '']) {
    return Depense(
      id: id,                                    // ✅ Added
      chefId: json['chefId'] ?? '',              // ✅ Added
      montant: (json['montant'] ?? 0).toDouble(),
      note: json['note'] ?? '',
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}