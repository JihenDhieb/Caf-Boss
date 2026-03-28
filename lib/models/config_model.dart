class Chef {
  final String id;
  final String nomCafe;
  final String nomChef;
  final DateTime dateInstallation;

  Chef({
    required this.id,
    required this.nomCafe,
    required this.nomChef,
    required this.dateInstallation,
  });

  factory Chef.fromJson(Map<String, dynamic> json, String id) {
    return Chef(
      id: id,
      nomCafe: json['nomCafe'] ?? '',
      nomChef: json['nomChef'] ?? '',
      dateInstallation: DateTime.parse(json['dateInstallation']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nomCafe': nomCafe,
      'nomChef': nomChef,
      'dateInstallation': dateInstallation.toIso8601String(),
    };
  }
}