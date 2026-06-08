class Lavage {
  final String id;
  final String plaque;
  final String client;
  final String service;
  final int prix;
  final String statut;
  final String typeVehicule;
  final String laveur;
  final DateTime dateHeure;

  Lavage({
    required this.id,
    required this.plaque,
    required this.client,
    required this.service,
    required this.prix,
    required this.statut,
    required this.typeVehicule,
    required this.dateHeure,
    this.laveur = '',
  });

  Map<String, dynamic> toMap() {
    return {
      'plaque': plaque,
      'client': client,
      'service': service,
      'prix': prix,
      'statut': statut,
      'typeVehicule': typeVehicule,
      'laveur': laveur,
      'dateHeure': dateHeure.toIso8601String(),
    };
  }

  factory Lavage.fromMap(String id, Map<String, dynamic> map) {
    return Lavage(
      id: id,
      plaque: map['plaque'] ?? '',
      client: map['client'] ?? '',
      service: map['service'] ?? '',
      prix: map['prix'] ?? 0,
      statut: map['statut'] ?? 'En attente',
      typeVehicule: map['typeVehicule'] ?? 'Voiture',
      laveur: map['laveur'] ?? '',
      dateHeure: DateTime.parse(map['dateHeure']),
    );
  }
}