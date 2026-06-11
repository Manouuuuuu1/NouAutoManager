class Lavage {
  final String id;
  final String plaque;
  final String client;
  final String telephone;
  final String service;
  final int prix;
  final String statut;
  final String typeVehicule;
  final String laveur;
  final String typeAccueil;
  final DateTime dateHeure;
  final DateTime? dateRDV;
  final String heureRDV;

  Lavage({
    required this.id,
    required this.plaque,
    required this.client,
    required this.service,
    required this.prix,
    required this.statut,
    required this.typeVehicule,
    required this.dateHeure,
    this.telephone = '',
    this.laveur = '',
    this.typeAccueil = 'Présentiel',
    this.dateRDV,
    this.heureRDV = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'plaque': plaque,
      'client': client,
      'telephone': telephone,
      'service': service,
      'prix': prix,
      'statut': statut,
      'typeVehicule': typeVehicule,
      'laveur': laveur,
      'typeAccueil': typeAccueil,
      'dateHeure': dateHeure.toIso8601String(),
      'dateRDV': dateRDV?.toIso8601String(),
      'heureRDV': heureRDV,
    };
  }

  factory Lavage.fromMap(String id, Map<String, dynamic> map) {
    return Lavage(
      id: id,
      plaque: map['plaque'] ?? '',
      client: map['client'] ?? '',
      telephone: map['telephone'] ?? '',
      service: map['service'] ?? '',
      prix: map['prix'] ?? 0,
      statut: map['statut'] ?? 'En attente',
      typeVehicule: map['typeVehicule'] ?? 'Voiture',
      laveur: map['laveur'] ?? '',
      typeAccueil: map['typeAccueil'] ?? 'Présentiel',
      dateHeure: DateTime.parse(map['dateHeure']),
      dateRDV: map['dateRDV'] != null
          ? DateTime.parse(map['dateRDV'])
          : null,
      heureRDV: map['heureRDV'] ?? '',
    );
  }
}