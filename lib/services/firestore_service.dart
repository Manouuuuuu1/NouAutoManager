import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/vehicule.dart';
import '../models/lavage.dart';
import '../models/laveur.dart';
import 'cache_service.dart';
import 'package:rxdart/rxdart.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final CacheService _cache = CacheService();

  // ── VÉHICULES ──────────────────────────────────────

  Future<void> ajouterVehicule(Vehicule v) async {
    await _db.collection('vehicules').add(v.toMap());
  }

  Stream<List<Vehicule>> getVehicules() {
    return _db.collection('vehicules').snapshots().map(
        (snap) => snap.docs
            .map((d) => Vehicule.fromMap(d.id, d.data()))
            .toList());
  }

  Future<void> supprimerVehicule(String id) async {
    await _db.collection('vehicules').doc(id).delete();
  }

  // ── LAVAGES ────────────────────────────────────────

  Future<void> ajouterLavage(Lavage l) async {
    await _db.collection('lavages').add(l.toMap());
  }

  Stream<List<Lavage>> getLavages() {
    // Émettre immédiatement le cache si disponible
    if (_cache.isLoaded) {
      return Stream.value(_cache.lavages)
          .asyncExpand((_) => _cache.lavagesStream
              .startWith(_cache.lavages));
    }
    return _cache.lavagesStream;
  }

  Future<void> mettreAJourStatut(
      String id, String statut) async {
    final Map<String, dynamic> data = {'statut': statut};
    final now = DateTime.now().toIso8601String();
    if (statut == 'En cours') {
      data['debutLavage'] = now;
    } else if (statut == 'Terminé') {
      data['finLavage'] = now;
    }
    await _db.collection('lavages').doc(id).update(data);
  }

  Future<void> modifierLavage(
      String id, Map<String, dynamic> data) async {
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
    if (_cache.isLoaded) {
      return Stream.value(_cache.laveurs)
          .asyncExpand((_) => _cache.laveursStream
              .startWith(_cache.laveurs));
    }
    return _cache.laveursStream;
  }

  Future<void> modifierLaveur(
      String id, Map<String, dynamic> data) async {
    await _db.collection('laveurs').doc(id).update(data);
  }

  Future<void> supprimerLaveur(String id) async {
    await _db.collection('laveurs').doc(id).delete();
  }

  // ── SUPERVISEUR PIN ────────────────────────────────

  Future<bool> verifierPinSuperviseur(String pin) async {
    final doc = await _db
        .collection('config')
        .doc('superviseur')
        .get();
    if (!doc.exists) return false;
    return doc.data()?['pin'] == pin;
  }

  Future<void> definirPinSuperviseur(String pin) async {
    await _db
        .collection('config')
        .doc('superviseur')
        .set({'pin': pin});
  }
}