import 'firestore_service.dart';

class SuperviseurService {
  static bool _estSuperviseur = false;
  static final FirestoreService _service = FirestoreService();

  static bool get estSuperviseur => _estSuperviseur;

  static Future<bool> verifierPin(String pin) async {
    final valide = await _service.verifierPinSuperviseur(pin);
    if (valide) _estSuperviseur = true;
    return valide;
  }

  static void seDeconnecter() {
    _estSuperviseur = false;
  }
}