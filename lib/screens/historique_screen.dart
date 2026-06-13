import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lavage.dart';
import '../services/firestore_service.dart';
import '../services/superviseur_service.dart';

class HistoriqueScreen extends StatefulWidget {
  final VoidCallback? onHome;
  const HistoriqueScreen({super.key, this.onHome});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  final FirestoreService _service = FirestoreService();
  String _filtreService = '';

  static const _bgPage = Color(0xFF0a1628);
  static const _bgAttente = Color(0xFF0e201a);
  static const _bgEnCours = Color(0xFF111d2a);
  static const _badgeAttente = Color(0xFF4a9e8a);
  static const _badgeEnCours = Color(0xFF5a8ab0);
  static const _teal = Color(0xFF06b6d4);
  static const _violet = Color(0xFF818cf8);
  static const _bgRDV = Color(0xFF13112a);

  final List<String> _services = [
    'Tous', 'Lavage simple', 'Lavage complet',
    'Lavage + intérieur', 'Cire & polish',
  ];

  final Map<String, Map<String, int>> _prix = {
    'Lavage simple': {'Voiture': 2500, 'Moto': 1000, 'SUV / Pickup': 3500},
    'Lavage complet': {'Voiture': 4000, 'Moto': 1500, 'SUV / Pickup': 6000},
    'Lavage + intérieur': {'Voiture': 6000, 'Moto': 2000, 'SUV / Pickup': 9000},
    'Cire & polish': {'Voiture': 10000, 'Moto': 0, 'SUV / Pickup': 15000},
  };

  Future<bool> _verifierSuperviseur() async {
    final pinCtrl = TextEditingController();
    bool? resultat = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a2744),
        title: const Text('Accès superviseur',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Entrez le code PIN superviseur',
                style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 24, letterSpacing: 8, color: Colors.white),
              decoration: InputDecoration(
                counterText: '',
                enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                        color: Colors.white.withValues(alpha: 0.3))),
                focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: _teal)),
                hintText: '••••',
                hintStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.3)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Annuler',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6)))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer',
                  style: TextStyle(color: _teal))),
        ],
      ),
    );
    if (resultat == true) {
      final valide = await SuperviseurService.verifierPin(pinCtrl.text);
      if (!valide && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Code PIN incorrect'),
              backgroundColor: Colors.red),
        );
      }
      SuperviseurService.seDeconnecter();
      return valide;
    }
    return false;
  }

  void _confirmerSuppression(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a2744),
        title: const Text('Supprimer ce lavage ?',
            style: TextStyle(color: Colors.white)),
        content: Text('Cette action est irréversible.',
            style:
                TextStyle(color: Colors.white.withValues(alpha: 0.7))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Annuler',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6)))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) await _service.supprimerLavage(id);
  }

  void _showFormulaireLavage(BuildContext context,
      {Lavage? lavage, String typeAccueil = 'Présentiel'}) async {
    final laveurs = await _service.getLaveurs().first;
    final nomsLaveurs = laveurs.map((l) => l.nomComplet).toList();
    if (nomsLaveurs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Aucun employé enregistré.')),
        );
      }
      return;
    }

    final plaqueCtrl = TextEditingController(text: lavage?.plaque ?? '');
    final clientCtrl = TextEditingController(text: lavage?.client ?? '');
    final telCtrl = TextEditingController(text: lavage?.telephone ?? '');
    String service = lavage?.service ?? 'Lavage simple';
    String typeVehicule = lavage?.typeVehicule ?? 'Voiture';
    String laveur = lavage?.laveur.isNotEmpty == true
        ? lavage!.laveur
        : nomsLaveurs.first;
    String accueil = lavage?.typeAccueil ?? typeAccueil;
    DateTime? dateRDV = lavage?.dateRDV;
    String heureRDV = lavage?.heureRDV ?? '';
    final bool estModification = lavage != null;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0f1f35),
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final prixAuto = _prix[service]?[typeVehicule] ?? 0;
          final estRDV = accueil == 'RDV';
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 24,
              bottom: MediaQuery.of(context).viewInsets.bottom + 24,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 40, height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Text(
                    estModification
                        ? 'Modifier le lavage'
                        : 'Nouveau lavage',
                    style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                  const SizedBox(height: 16),

                  // Toggle Présentiel / RDV
                  if (!estModification)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.1)),
                      ),
                      child: Row(
                        children: ['Présentiel', 'RDV'].map((type) {
                          final selected = accueil == type;
                          return Expanded(
                            child: GestureDetector(
                              onTap: () =>
                                  setModalState(() => accueil = type),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 10),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? _teal
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      type == 'Présentiel'
                                          ? Icons.directions_walk
                                          : Icons.calendar_today_outlined,
                                      size: 16,
                                      color: selected
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(type,
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: selected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                          color: selected
                                              ? Colors.white
                                              : Colors.white
                                                  .withValues(alpha: 0.5),
                                        )),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),

                  const SizedBox(height: 12),
                  _DarkField(
                      controller: plaqueCtrl,
                      label: 'Plaque du véhicule',
                      hint: 'ex: CI-1234-A'),
                  const SizedBox(height: 12),
                  _DarkField(
                      controller: clientCtrl, label: 'Nom du client'),
                  const SizedBox(height: 12),

                  // Champs RDV uniquement
                  if (estRDV) ...[
                    _DarkField(
                      controller: telCtrl,
                      label: 'Téléphone',
                      hint: '+225 07 00 00 00',
                    ),
                    const SizedBox(height: 12),

                    // Date RDV
                    GestureDetector(
                      onTap: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: dateRDV ?? DateTime.now(),
                          firstDate: DateTime.now(),
                          lastDate: DateTime.now()
                              .add(const Duration(days: 365)),
                        );
                        if (picked != null) {
                          setModalState(() => dateRDV = picked);
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.calendar_today_outlined,
                                size: 18,
                                color:
                                    Colors.white.withValues(alpha: 0.5)),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Date du RDV',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white
                                            .withValues(alpha: 0.5))),
                                Text(
                                  dateRDV != null
                                      ? '${dateRDV!.day}/${dateRDV!.month}/${dateRDV!.year}'
                                      : 'Choisir une date',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: dateRDV != null
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.3)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Heure RDV
                    GestureDetector(
                      onTap: () async {
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay.now(),
                        );
                        if (picked != null) {
                          setModalState(() => heureRDV =
                              '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}');
                        }
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color:
                                  Colors.white.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.access_time_outlined,
                                size: 18,
                                color:
                                    Colors.white.withValues(alpha: 0.5)),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Heure du RDV',
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white
                                            .withValues(alpha: 0.5))),
                                Text(
                                  heureRDV.isNotEmpty
                                      ? heureRDV
                                      : 'Choisir une heure',
                                  style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500,
                                      color: heureRDV.isNotEmpty
                                          ? Colors.white
                                          : Colors.white
                                              .withValues(alpha: 0.3)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],

                  _DarkDropdown<String>(
                    label: 'Service',
                    value: service,
                    items: _prix.keys.toList(),
                    onChanged: (v) =>
                        setModalState(() => service = v!),
                  ),
                  const SizedBox(height: 12),
                  _DarkDropdown<String>(
                    label: 'Type de véhicule',
                    value: typeVehicule,
                    items: ['Voiture', 'Moto', 'SUV / Pickup'],
                    onChanged: (v) =>
                        setModalState(() => typeVehicule = v!),
                  ),
                  const SizedBox(height: 12),
                  _DarkDropdown<String>(
                    label: 'Laveur assigné',
                    value: laveur,
                    items: nomsLaveurs,
                    onChanged: (v) => setModalState(() => laveur = v!),
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: _teal.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: _teal.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Prix calculé automatiquement',
                            style: TextStyle(
                                color: _teal.withValues(alpha: 0.9),
                                fontSize: 13)),
                        Text('$prixAuto F CFA',
                            style: const TextStyle(
                                color: _teal,
                                fontWeight: FontWeight.w700,
                                fontSize: 16)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _teal,
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 8,
                        shadowColor: _teal.withValues(alpha: 0.5),
                      ),
                      onPressed: () async {
                        if (plaqueCtrl.text.isEmpty ||
                            clientCtrl.text.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content:
                                    Text('Plaque et client requis')),
                          );
                          return;
                        }
                        if (estRDV && dateRDV == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'Choisissez une date de RDV')),
                          );
                          return;
                        }
                        if (estModification) {
                          await _service.modifierLavage(lavage.id, {
                            'plaque':
                                plaqueCtrl.text.trim().toUpperCase(),
                            'client': clientCtrl.text.trim(),
                            'telephone': telCtrl.text.trim(),
                            'service': service,
                            'typeVehicule': typeVehicule,
                            'laveur': laveur,
                            'prix': prixAuto,
                            'dateRDV': dateRDV?.toIso8601String(),
                            'heureRDV': heureRDV,
                          });
                        } else {
                          await _service.ajouterLavage(Lavage(
                            id: '',
                            plaque:
                                plaqueCtrl.text.trim().toUpperCase(),
                            client: clientCtrl.text.trim(),
                            telephone: telCtrl.text.trim(),
                            service: service,
                            prix: prixAuto,
                            statut: 'En attente',
                            typeVehicule: typeVehicule,
                            laveur: laveur,
                            typeAccueil: accueil,
                            dateHeure: DateTime.now(),
                            dateRDV: dateRDV,
                            heureRDV: heureRDV,
                          ));
                        }
                        if (context.mounted) {
  Navigator.of(context, rootNavigator: true).pop();
}
                      },
                      child: Text(
                        estModification
                            ? 'Enregistrer les modifications'
                            : 'Enregistrer',
                        style: const TextStyle(
                            fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1a2744),
        title: const Text('Déconnexion',
            style: TextStyle(color: Colors.white)),
        content: Text('Veux-tu vraiment te déconnecter ?',
            style: TextStyle(
                color: Colors.white.withValues(alpha: 0.7))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Annuler',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.6)))),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Déconnecter',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) {
      SuperviseurService.seDeconnecter();
      await FirebaseAuth.instance.signOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bgPage,
      appBar: AppBar(
        backgroundColor: const Color(0xFF0f1f35),
        elevation: 0,
        title: GestureDetector(
          onTap: () => widget.onHome?.call(),
          child: Image.asset('assets/images/logo.png', height: 32),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.white54),
            tooltip: 'Déconnexion',
            onPressed: _deconnecter,
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.extended(
            heroTag: 'rdv',
            onPressed: () =>
                _showFormulaireLavage(context, typeAccueil: 'RDV'),
            backgroundColor: _violet,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.calendar_today_outlined),
            label: const Text('RDV',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          FloatingActionButton.extended(
            heroTag: 'presentiel',
            onPressed: () => _showFormulaireLavage(context,
                typeAccueil: 'Présentiel'),
            backgroundColor: _teal,
            foregroundColor: Colors.white,
            elevation: 8,
            icon: const Icon(Icons.add),
            label: const Text('Présentiel',
                style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
      body: StreamBuilder<List<Lavage>>(
        stream: _service.getLavages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: _teal));
          }
          if (snapshot.hasError) {
            return Center(
                child: Text('Erreur de connexion',
                    style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6))));
          }

          final tousLavages = snapshot.data ?? [];
          var lavagesFiltres = tousLavages;
          if (_filtreService.isNotEmpty) {
            lavagesFiltres = tousLavages
                .where((l) => l.service == _filtreService)
                .toList();
          }

          final enAttente = lavagesFiltres
              .where((l) => l.statut == 'En attente').toList();
          final enCours = lavagesFiltres
              .where((l) => l.statut == 'En cours').toList();
          final presentiels = enAttente
              .where((l) => l.typeAccueil == 'Présentiel').toList();
          final rdvs = enAttente
              .where((l) => l.typeAccueil == 'RDV').toList();

          return Column(
            children: [
              // Filtre services
              Container(
                color: const Color(0xFF0f1f35),
                child: SizedBox(
                  height: 48,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 8),
                    itemCount: _services.length,
                    itemBuilder: (context, i) {
                      final selected =
                          _filtreService == _services[i] ||
                              (_filtreService.isEmpty &&
                                  _services[i] == 'Tous');
                      return GestureDetector(
                        onTap: () => setState(() => _filtreService =
                            _services[i] == 'Tous'
                                ? ''
                                : _services[i]),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? _teal
                                : Colors.white.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(99),
                            border: Border.all(
                              color: selected
                                  ? _teal
                                  : Colors.white.withValues(alpha: 0.15),
                            ),
                          ),
                          child: Text(
                            _services[i],
                            style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.6),
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // ── Présentiels ──────────────────────────
                      _SectionHeader(
                        titre: 'Présentiels',
                        count: presentiels.length,
                        couleur: _badgeAttente,
                        bgColor: _bgAttente,
                        icon: Icons.directions_walk,
                      ),
                      const SizedBox(height: 10),
                      if (presentiels.isEmpty)
                        _EmptyCard(
                            message: 'Aucun présentiel en attente')
                      else
                        ...presentiels.map((l) => _LavageCard(
                              lavage: l,
                              service: _service,
                              accentColor: _badgeAttente,
                              onModifier: () async {
                                final ok = await _verifierSuperviseur();
                                if (ok && context.mounted) {
                                  _showFormulaireLavage(context,
                                      lavage: l);
                                }
                              },
                              onSupprimer: () async {
                                final ok = await _verifierSuperviseur();
                                if (ok) _confirmerSuppression(l.id);
                              },
                            )),

                      const SizedBox(height: 20),

                      // ── Rendez-vous ───────────────────────────
                      _SectionHeader(
                        titre: 'Rendez-vous',
                        count: rdvs.length,
                        couleur: _violet,
                        bgColor: _bgRDV,
                        icon: Icons.calendar_today_outlined,
                      ),
                      const SizedBox(height: 10),
                      if (rdvs.isEmpty)
                        _EmptyCard(
                            message: 'Aucun rendez-vous en attente')
                      else
                        ...rdvs.map((l) => _LavageCard(
                              lavage: l,
                              service: _service,
                              accentColor: _violet,
                              onModifier: () async {
                                final ok = await _verifierSuperviseur();
                                if (ok && context.mounted) {
                                  _showFormulaireLavage(context,
                                      lavage: l);
                                }
                              },
                              onSupprimer: () async {
                                final ok = await _verifierSuperviseur();
                                if (ok) _confirmerSuppression(l.id);
                              },
                            )),

                      const SizedBox(height: 20),

                      // ── Lavages en cours ──────────────────────
                      _SectionHeader(
                        titre: 'Lavages en cours',
                        count: enCours.length,
                        couleur: _badgeEnCours,
                        bgColor: _bgEnCours,
                        icon: Icons.water_drop_outlined,
                      ),
                      const SizedBox(height: 10),
                      if (enCours.isEmpty)
                        _EmptyCard(message: 'Aucun lavage en cours')
                      else
                        ...enCours.map((l) => _LavageCard(
                              lavage: l,
                              service: _service,
                              accentColor: _badgeEnCours,
                              onModifier: () async {
                                final ok = await _verifierSuperviseur();
                                if (ok && context.mounted) {
                                  _showFormulaireLavage(context,
                                      lavage: l);
                                }
                              },
                              onSupprimer: () async {
                                final ok = await _verifierSuperviseur();
                                if (ok) _confirmerSuppression(l.id);
                              },
                            )),

                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ── Widgets utilitaires ────────────────────────────────────────────────────

class _DarkField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? hint;

  const _DarkField({
    required this.controller,
    required this.label,
    this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        hintStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.3)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF06b6d4)),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
      ),
    );
  }
}

class _DarkDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final ValueChanged<T?> onChanged;
  final IconData? icon;

  const _DarkDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      value: value,
      dropdownColor: const Color(0xFF1a2744),
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
            TextStyle(color: Colors.white.withValues(alpha: 0.6)),
        prefixIcon: icon != null
            ? Icon(icon, color: Colors.white.withValues(alpha: 0.5))
            : null,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide:
              BorderSide(color: Colors.white.withValues(alpha: 0.2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFF06b6d4)),
        ),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.05),
      ),
      items: items
          .map((item) => DropdownMenuItem<T>(
                value: item,
                child: Text(item.toString(),
                    style: const TextStyle(color: Colors.white)),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String titre;
  final int count;
  final Color couleur;
  final Color bgColor;
  final IconData icon;

  const _SectionHeader({
    required this.titre,
    required this.count,
    required this.couleur,
    required this.bgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
          const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: couleur.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, color: couleur, size: 20),
          const SizedBox(width: 10),
          Text(titre,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: couleur)),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(
                horizontal: 10, vertical: 3),
            decoration: BoxDecoration(
              color: couleur,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text('$count',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;
  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1b2a),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Text(message,
          textAlign: TextAlign.center,
          style: TextStyle(
              color: Colors.white.withValues(alpha: 0.3),
              fontSize: 13)),
    );
  }
}

class _LavageCard extends StatelessWidget {
  final Lavage lavage;
  final FirestoreService service;
  final Color accentColor;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const _LavageCard({
    required this.lavage,
    required this.service,
    required this.accentColor,
    required this.onModifier,
    required this.onSupprimer,
  });

  String get _nextStatut {
    switch (lavage.statut) {
      case 'En attente': return 'Démarrer';
      case 'En cours': return 'Terminer';
      default: return 'Rouvrir';
    }
  }

  IconData get _nextIcon {
    switch (lavage.statut) {
      case 'En attente': return Icons.play_arrow_rounded;
      case 'En cours': return Icons.check_circle_rounded;
      default: return Icons.refresh_rounded;
    }
  }

  void _changerStatut() async {
    final statuts = ['En attente', 'En cours', 'Terminé'];
    final idx = statuts.indexOf(lavage.statut);
    final next = statuts[(idx + 1) % statuts.length];
    await service.mettreAJourStatut(lavage.id, next);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0d1b2a),
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: accentColor.withValues(alpha: 0.25)),
        boxShadow: [
          BoxShadow(
            color: accentColor.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: accentColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: accentColor.withValues(alpha: 0.3)),
                  ),
                  child: Icon(Icons.directions_car,
                      color: accentColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lavage.plaque,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(lavage.client,
                          style: TextStyle(
                              color:
                                  Colors.white.withValues(alpha: 0.6),
                              fontSize: 13)),
                      Text(
                          '${lavage.service} · ${lavage.typeVehicule}',
                          style: TextStyle(
                              color:
                                  Colors.white.withValues(alpha: 0.4),
                              fontSize: 12)),
                      if (lavage.laveur.isNotEmpty)
                        Row(children: [
                          Icon(Icons.person_outline,
                              size: 12,
                              color: Colors.white
                                  .withValues(alpha: 0.4)),
                          const SizedBox(width: 4),
                          Text(lavage.laveur,
                              style: TextStyle(
                                  color: Colors.white
                                      .withValues(alpha: 0.4),
                                  fontSize: 12)),
                        ]),
                      // Infos RDV
                      if (lavage.typeAccueil == 'RDV' &&
                          lavage.dateRDV != null)
                        Row(children: [
                          Icon(Icons.calendar_today_outlined,
                              size: 12,
                              color: const Color(0xFF818cf8)
                                  .withValues(alpha: 0.8)),
                          const SizedBox(width: 4),
                          Text(
                            'RDV : ${lavage.dateRDV!.day}/${lavage.dateRDV!.month}/${lavage.dateRDV!.year}'
                            '${lavage.heureRDV.isNotEmpty ? ' à ${lavage.heureRDV}' : ''}',
                            style: const TextStyle(
                                color: Color(0xFF818cf8),
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ]),
                      if (lavage.telephone.isNotEmpty)
                        Row(children: [
                          Icon(Icons.phone_outlined,
                              size: 12,
                              color: Colors.white
                                  .withValues(alpha: 0.4)),
                          const SizedBox(width: 4),
                          Text(lavage.telephone,
                              style: TextStyle(
                                  color: Colors.white
                                      .withValues(alpha: 0.4),
                                  fontSize: 12)),
                        ]),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${lavage.prix} F',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: accentColor)),
                    const SizedBox(height: 4),
                    Text(
  '${lavage.dateHeure.hour}:${lavage.dateHeure.minute.toString().padLeft(2, '0')}',
  style: TextStyle(
      color: Colors.white.withValues(alpha: 0.4),
      fontSize: 12),
),
if (lavage.dureeLavageMinutes != null)
  Container(
    margin: const EdgeInsets.only(top: 4),
    padding: const EdgeInsets.symmetric(
        horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: const Color(0xFF3B6D11).withValues(alpha: 0.2),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(
          color: const Color(0xFF3B6D11)
              .withValues(alpha: 0.4)),
    ),
    child: Text(
      '${lavage.dureeLavageMinutes} min',
      style: const TextStyle(
          color: Color(0xFF4ade80),
          fontSize: 11,
          fontWeight: FontWeight.w600),
    ),
  ),
                  ],
                ),
              ],
            ),
          ),

          // Barre d'actions
          Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.03),
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(14)),
              border: Border(
                  top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.07))),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextButton.icon(
                    onPressed: onModifier,
                    icon: const Icon(Icons.edit_outlined, size: 15),
                    label: const Text('Modifier'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Colors.white.withValues(alpha: 0.6),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withValues(alpha: 0.07)),
                Expanded(
                  flex: 2,
                  child: TextButton.icon(
                    onPressed: _changerStatut,
                    icon: Icon(_nextIcon, size: 18),
                    label: Text(_nextStatut,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      foregroundColor: accentColor,
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Container(
                    width: 1,
                    height: 30,
                    color: Colors.white.withValues(alpha: 0.07)),
                Expanded(
                  child: TextButton.icon(
                    onPressed: onSupprimer,
                    icon: const Icon(Icons.delete_outline, size: 15),
                    label: const Text('Suppr.'),
                    style: TextButton.styleFrom(
                      foregroundColor:
                          Colors.red.withValues(alpha: 0.7),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}