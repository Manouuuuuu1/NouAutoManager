class Laveur {
  final String id;
  final String nom;
  final String prenom;
  final DateTime dateNaissance;
  final String telephone;
  final String adresse;
  final String numeroCNI;
  final DateTime dateEmbauche;

  Laveur({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.dateNaissance,
    required this.telephone,
    required this.adresse,
    required this.numeroCNI,
    required this.dateEmbauche,
  });

  String get nomComplet => '$prenom $nom';

  Map<String, dynamic> toMap() {
    return {
      'nom': nom,
      'prenom': prenom,
      'dateNaissance': dateNaissance.toIso8601String(),
      'telephone': telephone,
      'adresse': adresse,
      'numeroCNI': numeroCNI,
      'dateEmbauche': dateEmbauche.toIso8601String(),
    };
  }

  factory Laveur.fromMap(String id, Map<String, dynamic> map) {
    return Laveur(
      id: id,
      nom: map['nom'] ?? '',
      prenom: map['prenom'] ?? '',
      dateNaissance: DateTime.parse(map['dateNaissance']),
      telephone: map['telephone'] ?? '',
      adresse: map['adresse'] ?? '',
      numeroCNI: map['numeroCNI'] ?? '',
      dateEmbauche: DateTime.parse(map['dateEmbauche']),
    );
  }
}