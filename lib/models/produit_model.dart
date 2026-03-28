// lib/models/produit_model.dart
class Produit {
  final String id;
  final String nom;
  final double prix;
  final String categorie;
  final String emoji; // ✅ ajouté

  Produit({
    required this.id,
    required this.nom,
    required this.prix,
    this.categorie = '',
    this.emoji = '☕', // valeur par défaut
  });

  Map<String, dynamic> toJson() => {
        'nom': nom,
        'prix': prix,
        'categorie': categorie,
        'emoji': emoji,
      };

  factory Produit.fromJson(Map<String, dynamic> json, String id) {
    return Produit(
      id: id,
      nom: json['nom'] ?? '',
      prix: (json['prix'] ?? 0).toDouble(),
      categorie: json['categorie'] ?? '',
      emoji: json['emoji'] ?? '☕', // ✅ fallback si absent en base
    );
  }
}