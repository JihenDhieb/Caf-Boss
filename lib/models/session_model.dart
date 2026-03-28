// lib/models/session_model.dart

class Session {
  final String id;
  final String type; // 'matin' ou 'midi'
  final double fondCaisse;
  final double total;
  final DateTime date;
  final String serveurId;
  final String serveurNom;

  final Map<String, int> _produits; // clé = nom produit, valeur = quantité

  Session({
    required this.id,
    required this.type,
    required this.fondCaisse,
    required this.total,
    required this.date,
    required this.serveurId,
    required this.serveurNom,
    Map<String, int>? produits,
  }) : _produits = produits ?? {};

  Map<String, int> get produits => Map.unmodifiable(_produits);

  Map<String, dynamic> toJson() => {
        'type': type,
        'fondCaisse': fondCaisse,
        'total': total,
        'date': date.toIso8601String(),
        'serveurId': serveurId,
        'serveurNom': serveurNom,
        'produits': _produits,
      };

  factory Session.fromJson(Map<String, dynamic> json, String id) {
    final prodMap = json['produits'] != null
        ? Map<String, int>.from(json['produits'])
        : <String, int>{};

    return Session(
      id: id,
      type: json['type'] ?? 'matin',
      fondCaisse: (json['fondCaisse'] ?? 0).toDouble(),
      total: (json['total'] ?? 0).toDouble(),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      serveurId: json['serveurId'] ?? '',
      serveurNom: json['serveurNom'] ?? '',
      produits: prodMap,
    );
  }
}