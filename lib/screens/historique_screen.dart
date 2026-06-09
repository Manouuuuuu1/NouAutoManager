import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lavage.dart';
import '../models/laveur.dart';
import '../services/firestore_service.dart';
import '../services/superviseur_service.dart';

class HistoriqueScreen extends StatefulWidget {
  const HistoriqueScreen({super.key});

  @override
  State<HistoriqueScreen> createState() => _HistoriqueScreenState();
}

class _HistoriqueScreenState extends State<HistoriqueScreen> {
  final FirestoreService _service = FirestoreService();
  String _filtreService = '';

  final List<String> _services = [
    'Tous',
    'Lavage simple',
    'Lavage complet',
    'Lavage + intérieur',
    'Cire & polish',
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

  void _showFormulaireLavage(BuildContext context, {Lavage? lavage}) async {
    final laveurs = await _service.getLaveurs().first;
    final nomsLaveurs = laveurs.map((l) => l.nomComplet).toList();
    if (nomsLaveurs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Aucun employé enregistré. Ajoutez un employé d\'abord.')),
        );
      }
      return;
    }

    final plaqueCtrl = TextEditingController(text: lavage?.plaque ?? '');
    final clientCtrl = TextEditingController(text: lavage?.client ?? '');
    String service = lavage?.service ?? 'Lavage simple';
    String typeVehicule = lavage?.typeVehicule ?? 'Voiture';
    String laveur = lavage?.laveur.isNotEmpty == true
        ? lavage!.laveur
        : nomsLaveurs.first;
    final bool estModification = lavage != null;

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
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
                        border: OutlineInputBorder()),
                    items: _prix.keys
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setModalState(() => service = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: typeVehicule,
                    decoration: const InputDecoration(
                        labelText: 'Type de véhicule',
                        border: OutlineInputBorder()),
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
                      labelText: 'Laveur assigné',
                      prefixIcon: Icon(Icons.person_outline),
                      border: OutlineInputBorder(),
                    ),
                    items: nomsLaveurs
                        .map((l) =>
                            DropdownMenuItem(value: l, child: Text(l)))
                        .toList(),
                    onChanged: (v) => setModalState(() => laveur = v!),
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
                                content: Text('Plaque et client requis')),
                          );
                          return;
                        }
                        if (estModification) {
                          await _service.modifierLavage(lavage.id, {
                            'plaque':
                                plaqueCtrl.text.trim().toUpperCase(),
                            'client': clientCtrl.text.trim(),
                            'service': service,
                            'typeVehicule': typeVehicule,
                            'laveur': laveur,
                            'prix': prixAuto,
                          });
                        } else {
                          await _service.ajouterLavage(Lavage(
                            id: '',
                            plaque:
                                plaqueCtrl.text.trim().toUpperCase(),
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
                        estModification
                            ? 'Enregistrer les modifications'
                            : 'Enregistrer',
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        toolbarHeight: 0,
        elevation: 0,
        backgroundColor: const Color(0xFF185FA5),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormulaireLavage(context),
        backgroundColor: const Color(0xFF185FA5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Nouveau lavage'),
      ),
      body: StreamBuilder<List<Lavage>>(
        stream: _service.getLavages(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur de connexion'));
          }

          final tousLavages = snapshot.data ?? [];

          // Filtrer par service
          var lavagesFiltres = tousLavages;
          if (_filtreService.isNotEmpty) {
            lavagesFiltres = tousLavages
                .where((l) => l.service == _filtreService)
                .toList();
          }

          final enAttente = lavagesFiltres
              .where((l) => l.statut == 'En attente')
              .toList();
          final enCours = lavagesFiltres
              .where((l) => l.statut == 'En cours')
              .toList();

          return Column(
            children: [
              // Filtre services
              Container(
                color: const Color(0xFF185FA5),
                child: SizedBox(
                  height: 52,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                    itemCount: _services.length,
                    itemBuilder: (context, i) {
                      final selected = _filtreService == _services[i] ||
                          (_filtreService.isEmpty &&
                              _services[i] == 'Tous');
                      return GestureDetector(
                        onTap: () => setState(() => _filtreService =
                            _services[i] == 'Tous' ? '' : _services[i]),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14),
                          decoration: BoxDecoration(
                            color: selected
                                ? Colors.white
                                : Colors.white
                                    .withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            _services[i],
                            style: TextStyle(
                              fontSize: 12,
                              color: selected
                                  ? const Color(0xFF185FA5)
                                  : Colors.white,
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

              // Contenu
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section 1 — En attente
                      _SectionHeader(
                        titre: 'Lavages à venir',
                        count: enAttente.length,
                        couleur: const Color(0xFF854F0B),
                        bgColor: const Color(0xFFFAEEDA),
                        icon: Icons.hourglass_empty,
                      ),
                      const SizedBox(height: 10),
                      if (enAttente.isEmpty)
                        _EmptyState(message: 'Aucun lavage en attente')
                      else
                        ...enAttente.map((l) => _LavageCard(
                              lavage: l,
                              service: _service,
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

                      // Section 2 — En cours
                      _SectionHeader(
                        titre: 'Lavages en cours',
                        count: enCours.length,
                        couleur: const Color(0xFF185FA5),
                        bgColor: const Color(0xFFE6F1FB),
                        icon: Icons.local_car_wash,
                      ),
                      const SizedBox(height: 10),
                      if (enCours.isEmpty)
                        _EmptyState(message: 'Aucun lavage en cours')
                      else
                        ...enCours.map((l) => _LavageCard(
                              lavage: l,
                              service: _service,
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

                      const SizedBox(height: 80),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: couleur.withValues(alpha: 0.2)),
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
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
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

class _EmptyState extends StatelessWidget {
  final String message;
  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(message,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.grey, fontSize: 13)),
    );
  }
}

class _LavageCard extends StatelessWidget {
  final Lavage lavage;
  final FirestoreService service;
  final VoidCallback onModifier;
  final VoidCallback onSupprimer;

  const _LavageCard({
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

  Color get _nextColor {
    switch (lavage.statut) {
      case 'En attente': return const Color(0xFF185FA5);
      case 'En cours': return const Color(0xFF3B6D11);
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
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Infos principales
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.directions_car,
                      color: _statusColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(lavage.plaque,
                          style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(lavage.client,
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 13)),
                      Text('${lavage.service} · ${lavage.typeVehicule}',
                          style: const TextStyle(
                              color: Colors.grey, fontSize: 12)),
                      if (lavage.laveur.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.person_outline,
                                size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(lavage.laveur,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 12)),
                          ],
                        ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${lavage.prix} F',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(
                      '${lavage.dateHeure.hour}:${lavage.dateHeure.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(
                          color: Colors.grey, fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Barre d'actions
          Container(
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: const BorderRadius.vertical(
                  bottom: Radius.circular(12)),
              border: Border(
                  top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Row(
              children: [
                // Bouton modifier
                Expanded(
                  child: TextButton.icon(
                    onPressed: onModifier,
                    icon: const Icon(Icons.edit_outlined, size: 16),
                    label: const Text('Modifier'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF185FA5),
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Container(
                    width: 1, height: 36,
                    color: Colors.grey.shade200),

                // Bouton changer statut — plus grand et visible
                Expanded(
                  flex: 2,
                  child: TextButton.icon(
                    onPressed: _changerStatut,
                    icon: Icon(_nextIcon, size: 18),
                    label: Text(_nextStatut,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600)),
                    style: TextButton.styleFrom(
                      foregroundColor: _nextColor,
                      padding:
                          const EdgeInsets.symmetric(vertical: 10),
                    ),
                  ),
                ),
                Container(
                    width: 1, height: 36,
                    color: Colors.grey.shade200),

                // Bouton supprimer
                Expanded(
                  child: TextButton.icon(
                    onPressed: onSupprimer,
                    icon: const Icon(Icons.delete_outline, size: 16),
                    label: const Text('Suppr.'),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFFA32D2D),
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