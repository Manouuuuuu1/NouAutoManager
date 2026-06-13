import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lavage.dart';
import '../models/laveur.dart';

class CacheService {
  // Singleton — une seule instance dans toute l'app
  static final CacheService _instance = CacheService._internal();
  factory CacheService() => _instance;
  CacheService._internal();

  // Cache en mémoire
  List<Lavage> _lavages = [];
  List<Laveur> _laveurs = [];
  bool _isLoaded = false;

  // Streams pour notifier les écrans en temps réel
  final _lavagesController =
      StreamController<List<Lavage>>.broadcast();
  final _laveursController =
      StreamController<List<Laveur>>.broadcast();

  Stream<List<Lavage>> get lavagesStream =>
      _lavagesController.stream;
  Stream<List<Laveur>> get laveursStream =>
      _laveursController.stream;

  List<Lavage> get lavages => _lavages;
  List<Laveur> get laveurs => _laveurs;
  bool get isLoaded => _isLoaded;

  StreamSubscription? _lavagesSub;
  StreamSubscription? _laveursSub;

  // Démarrer le préchargement
  void init() {
    // Éviter de démarrer deux fois
    if (_lavagesSub != null) return;

    _lavagesSub = FirebaseFirestore.instance
        .collection('lavages')
        .orderBy('dateHeure', descending: true)
        .snapshots()
        .listen((snap) {
      _lavages = snap.docs
          .map((d) => Lavage.fromMap(d.id, d.data()))
          .toList();
      _lavagesController.add(_lavages);
      _isLoaded = true;
    });

    _laveursSub = FirebaseFirestore.instance
        .collection('laveurs')
        .orderBy('nom')
        .snapshots()
        .listen((snap) {
      _laveurs = snap.docs
          .map((d) => Laveur.fromMap(d.id, d.data()))
          .toList();
      _laveursController.add(_laveurs);
    });
  }

  // Arrêter les listeners à la déconnexion
  void dispose() {
    _lavagesSub?.cancel();
    _laveursSub?.cancel();
    _lavagesSub = null;
    _laveursSub = null;
    _lavages = [];
    _laveurs = [];
    _isLoaded = false;
  }
}