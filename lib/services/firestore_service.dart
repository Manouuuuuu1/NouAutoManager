import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicule.dart';
import '../models/lavage.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ── VÉHICULES ──────────────────────────────────────

  Future<void> ajouterVehicule(Vehicule v) async {
    await _db.collection('vehicules').add(v.toMap());
  }

  Stream<List<Vehicule>> getVehicules() {
    return _db.collection('vehicules').snapshots().map((snap) =>
        snap.docs.map((d) => Vehicule.fromMap(d.id, d.data())).toList());
  }

  Future<void> supprimerVehicule(String id) async {
    await _db.collection('vehicules').doc(id).delete();
  }

  // ── LAVAGES ────────────────────────────────────────

  Future<void> ajouterLavage(Lavage l) async {
    await _db.collection('lavages').add(l.toMap());
  }

  Stream<List<Lavage>> getLavages() {
    return _db
        .collection('lavages')
        .orderBy('dateHeure', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Lavage.fromMap(d.id, d.data())).toList());
  }

  Future<void> mettreAJourStatut(String id, String statut) async {
    await _db.collection('lavages').doc(id).update({'statut': statut});
  }

  Future<void> modifierLavage(String id, Map<String, dynamic> data) async {
    await _db.collection('lavages').doc(id).update(data);
  }

  Future<void> supprimerLavage(String id) async {
    await _db.collection('lavages').doc(id).delete();
  }
}