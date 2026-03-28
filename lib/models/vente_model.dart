class Vente {
  final String serveurId;
  final String serveurNom;
  final Map<String, int> produits; // nom → quantité
  final double total;
  final DateTime date;
  final String typeSession; // 'matin' ou 'midi'

  Vente({
    required this.serveurId,
    required this.serveurNom,
    required this.produits,
    required this.total,
    required this.date,
    required this.typeSession,
  });

  Map<String, dynamic> toJson() => {
        'serveurId': serveurId,
        'serveurNom': serveurNom,
        'produits': produits,
        'total': total,
        'date': date.toIso8601String(),
        'typeSession': typeSession,
      };

  factory Vente.fromJson(Map<String, dynamic> json) {
    return Vente(
      serveurId: json['serveurId'] ?? '',
      serveurNom: json['serveurNom'] ?? '',
      produits: json['produits'] != null
          ? Map<String, int>.from(json['produits'])
          : {},
      total: (json['total'] ?? 0).toDouble(),
      date: json['date'] != null
          ? DateTime.tryParse(json['date'].toString()) ?? DateTime.now()
          : DateTime.now(),
      typeSession: json['typeSession'] ?? 'matin',
    );
  }
}