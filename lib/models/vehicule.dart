class Vehicule {
  final String id;
  final String plaque;
  final String proprietaire;
  final String marque;
  final String modele;
  final String couleur;
  final String type; // Voiture, Moto, SUV/Pickup
  final int totalVisites;
  final DateTime? dernierLavage;

  Vehicule({
    required this.id,
    required this.plaque,
    required this.proprietaire,
    required this.marque,
    required this.modele,
    required this.couleur,
    required this.type,
    this.totalVisites = 0,
    this.dernierLavage,
  });

  // Convertir en Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'plaque': plaque,
      'proprietaire': proprietaire,
      'marque': marque,
      'modele': modele,
      'couleur': couleur,
      'type': type,
      'totalVisites': totalVisites,
      'dernierLavage': dernierLavage?.toIso8601String(),
    };
  }

  // Créer un Vehicule depuis Firebase
  factory Vehicule.fromMap(String id, Map<String, dynamic> map) {
    return Vehicule(
      id: id,
      plaque: map['plaque'] ?? '',
      proprietaire: map['proprietaire'] ?? '',
      marque: map['marque'] ?? '',
      modele: map['modele'] ?? '',
      couleur: map['couleur'] ?? '',
      type: map['type'] ?? 'Voiture',
      totalVisites: map['totalVisites'] ?? 0,
      dernierLavage: map['dernierLavage'] != null
          ? DateTime.parse(map['dernierLavage'])
          : null,
    );
  }
}