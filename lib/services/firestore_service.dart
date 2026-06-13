import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicule.dart';
import '../models/lavage.dart';
import '../models/laveur.dart';

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
  final Map<String, dynamic> data = {'statut': statut};
  final now = DateTime.now().toIso8601String();

  // Enregistrer automatiquement les timestamps
  if (statut == 'En cours') {
    data['debutLavage'] = now;
  } else if (statut == 'Terminé') {
    data['finLavage'] = now;
  }

  await _db.collection('lavages').doc(id).update(data);
}

  Future<void> modifierLavage(String id, Map<String, dynamic> data) async {
    await _db.collection('lavages').doc(id).update(data);
  }

  Future<void> supprimerLavage(String id) async {
    await _db.collection('lavages').doc(id).delete();
  }

  // ── LAVEURS ────────────────────────────────────────

  Future<void> ajouterLaveur(Laveur l) async {
    await _db.collection('laveurs').add(l.toMap());
  }

  Stream<List<Laveur>> getLaveurs() {
    return _db
        .collection('laveurs')
        .orderBy('nom')
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => Laveur.fromMap(d.id, d.data())).toList());
  }

  Future<void> modifierLaveur(String id, Map<String, dynamic> data) async {
    await _db.collection('laveurs').doc(id).update(data);
  }

  Future<void> supprimerLaveur(String id) async {
    await _db.collection('laveurs').doc(id).delete();
  }

  // ── SUPERVISEUR PIN ────────────────────────────────

  Future<bool> verifierPinSuperviseur(String pin) async {
    final doc = await _db.collection('config').doc('superviseur').get();
    if (!doc.exists) return false;
    return doc.data()?['pin'] == pin;
  }

  Future<void> definirPinSuperviseur(String pin) async {
    await _db.collection('config').doc('superviseur').set({'pin': pin});
  }
}