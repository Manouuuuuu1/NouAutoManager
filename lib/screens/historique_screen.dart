import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lavage.dart';
import '../services/firestore_service.dart';
import 'package:prowash/services/superviseur_service.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  final FirestoreService _service = FirestoreService();
  String _filtreService = '';

  // ── MÉTHODE PIN SUPERVISEUR ────────────────────────
  Future<bool> _verifierSuperviseur() async {
    if (SuperviseurService.estSuperviseur) return true;

    final pinCtrl = TextEditingController();
    bool? resultat = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Accès superviseur'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Entrez le code PIN superviseur',
                style: TextStyle(color: Colors.grey, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: pinCtrl,
              keyboardType: TextInputType.number,
              obscureText: true,
              maxLength: 4,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 24, letterSpacing: 8),
              decoration: const InputDecoration(
                counterText: '',
                border: OutlineInputBorder(),
                hintText: '••••',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Confirmer')),
        ],
      ),
    );

    if (resultat == true) {
      final valide = await SuperviseurService.verifierPin(pinCtrl.text);
      if (!valide && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Code PIN incorrect'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return valide;
    }
    return false;
  }
  // ──────────────────────────────────────────────────

  final List<String> _services = [
    'Tous',
    'Lavage simple',
    'Lavage complet',
    'Lavage + intérieur',
    'Cire & polish',
  ];

  final List<String> _laveurs = [
    'Koné Mamadou',
    'Traoré Seydou',
    'Bamba Inza',
    'Coulibaly Adama',
  ];

  final Map<String, Map<String, int>> _prix = {
    'Lavage simple': {'Voiture': 2500, 'Moto': 1000, 'SUV / Pickup': 3500},
    'Lavage complet': {'Voiture': 4000, 'Moto': 1500, 'SUV / Pickup': 6000},
    'Lavage + intérieur': {'Voiture': 6000, 'Moto': 2000, 'SUV / Pickup': 9000},
    'Cire & polish': {'Voiture': 10000, 'Moto': 0, 'SUV / Pickup': 15000},
  };

  void _deconnecter() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Déconnexion'),
        content: const Text('Veux-tu vraiment te déconnecter ?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Déconnecter',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) await FirebaseAuth.instance.signOut();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Historique',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF185FA5),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Déconnexion',
            onPressed: _deconnecter,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormulaireLavage(context),
        backgroundColor: const Color(0xFF185FA5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau lavage'),
      ),
      body: Column(
        children: [
          // Filtre services
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: _services.length,
              itemBuilder: (context, i) {
                final selected = _filtreService == _services[i] ||
                    (_filtreService.isEmpty && _services[i] == 'Tous');
                return GestureDetector(
                  onTap: () => setState(() =>
                      _filtreService = _services[i] == 'Tous' ? '' : _services[i]),
                  child: Container(
                    margin: const EdgeInsets.only(right: 8),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    decoration: BoxDecoration(
                      color: selected ? const Color(0xFF185FA5) : Colors.white,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: selected
                            ? const Color(0xFF185FA5)
                            : Colors.grey.shade300,
                      ),
                    ),
                    child: Text(
                      _services[i],
                      style: TextStyle(
                        fontSize: 12,
                        color: selected ? Colors.white : Colors.grey.shade700,
                        fontWeight:
                            selected ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Liste des lavages
          Expanded(
            child: StreamBuilder<List<Lavage>>(
              stream: _service.getLavages(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(child: Text('Erreur de connexion'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                var lavages = snapshot.data ?? [];
                if (_filtreService.isNotEmpty) {
                  lavages = lavages
                      .where((l) => l.service == _filtreService)
                      .toList();
                }

                if (lavages.isEmpty) {
                  return const Center(
                    child: Text('Aucun lavage enregistré',
                        style: TextStyle(color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: lavages.length,
                  itemBuilder: (context, i) => _LavageItem(
  lavage: lavages[i],
  service: _service,
  onModifier: () async {
    final ok = await _verifierSuperviseur();
    if (ok && context.mounted) {
      _showFormulaireLavage(context, lavage: lavages[i]);
    }
  },
  onSupprimer: () async {
    final ok = await _verifierSuperviseur();
    if (ok) _confirmerSuppression(lavages[i].id);
  },
),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _confirmerSuppression(String id) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer ce lavage ?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Supprimer',
                  style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirm == true) await _service.supprimerLavage(id);
  }

  void _showFormulaireLavage(BuildContext context, {Lavage? lavage}) {
    final plaqueCtrl =
        TextEditingController(text: lavage?.plaque ?? '');
    final clientCtrl =
        TextEditingController(text: lavage?.client ?? '');
    String service = lavage?.service ?? 'Lavage simple';
    String typeVehicule = lavage?.typeVehicule ?? 'Voiture';
    String laveur = lavage?.laveur ?? _laveurs.first;
    final bool estModification = lavage != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final prixAuto = _prix[service]?[typeVehicule] ?? 0;
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    estModification ? 'Modifier le lavage' : 'Nouveau lavage',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: plaqueCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Plaque du véhicule',
                      hintText: 'ex: CI-1234-A',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: clientCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Nom du client',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: service,
                    decoration: const InputDecoration(
                      labelText: 'Service',
                      border: OutlineInputBorder(),
                    ),
                    items: _prix.keys
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => service = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: typeVehicule,
                    decoration: const InputDecoration(
                      labelText: 'Type de véhicule',
                      border: OutlineInputBorder(),
                    ),
                    items: ['Voiture', 'Moto', 'SUV / Pickup']
                        .map((t) =>
                            DropdownMenuItem(value: t, child: Text(t)))
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => typeVehicule = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: laveur,
                    decoration: const InputDecoration(
                      labelText: 'Nom du laveur',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    items: _laveurs
                        .map((l) =>
                            DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) =>
                        setModalState(() => laveur = v!),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F1FB),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Prix calculé automatiquement',
                            style: TextStyle(
                                color: Color(0xFF185FA5), fontSize: 13)),
                        Text('$prixAuto F CFA',
                            style: const TextStyle(
                                color: Color(0xFF185FA5),
                                fontWeight: FontWeight.w600,
                                fontSize: 15)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF185FA5),
                        foregroundColor: Colors.white,
                        padding:
                            const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
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
                        if (estModification) {
                          await _service.modifierLavage(lavage.id, {
                            'plaque': plaqueCtrl.text.trim().toUpperCase(),
                            'client': clientCtrl.text.trim(),
                            'service': service,
                            'typeVehicule': typeVehicule,
                            'laveur': laveur,
                            'prix': prixAuto,
                          });
                        } else {
                          await _service.ajouterLavage(Lavage(
                            id: '',
                            plaque: plaqueCtrl.text.trim().toUpperCase(),
                            client: clientCtrl.text.trim(),
                            service: service,
                            prix: prixAuto,
                            statut: 'En attente',
                            typeVehicule: typeVehicule,
                            laveur: laveur,
                            dateHeure: DateTime.now(),
                          ));
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: Text(
                        estModification ? 'Enregistrer les modifications' : 'Enregistrer',
                        style: const TextStyle(fontSize: 15),
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
}

class _LavageItem extends StatelessWidget {
  final Lavage lavage;
  final FirestoreService service;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const _LavageItem({
    required this.lavage,
    required this.service,
    required this.onModifier,
    required this.onSupprimer,
  });

  Color get _statusColor {
    switch (lavage.statut) {
      case 'Terminé': return const Color(0xFF3B6D11);
      case 'En cours': return const Color(0xFF185FA5);
      default: return const Color(0xFF854F0B);
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
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1FB),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.directions_car,
                    color: Color(0xFF185FA5), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(lavage.plaque,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text('${lavage.service} · ${lavage.client}',
                        style: const TextStyle(
                            color: Colors.grey, fontSize: 12)),
                    if (lavage.laveur.isNotEmpty)
                      Text('Laveur : ${lavage.laveur}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 11)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('${lavage.prix} F',
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: _changerStatut,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(99),
                        border: Border.all(
                            color: _statusColor.withValues(alpha: 0.3)),
                      ),
                      child: Text(lavage.statut,
                          style: TextStyle(
                              color: _statusColor, fontSize: 11)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${lavage.dateHeure.day}/${lavage.dateHeure.month}/${lavage.dateHeure.year} ${lavage.dateHeure.hour}:${lavage.dateHeure.minute.toString().padLeft(2, '0')}',
                style: const TextStyle(color: Colors.grey, fontSize: 11),
              ),
              Row(
                children: [
                  GestureDetector(
                    onTap: onModifier,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE6F1FB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Modifier',
                          style: TextStyle(
                              color: Color(0xFF185FA5), fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 6),
                  GestureDetector(
                    onTap: onSupprimer,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFCEBEB),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text('Supprimer',
                          style: TextStyle(
                              color: Color(0xFFA32D2D), fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}