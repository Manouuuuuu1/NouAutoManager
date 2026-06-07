import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lavage.dart';
import '../services/firestore_service.dart';

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
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAjouterLavage(context),
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
                      color: selected
                          ? const Color(0xFF185FA5)
                          : Colors.white,
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
                  itemBuilder: (context, i) =>
                      _LavageItem(lavage: lavages[i], service: _service),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAjouterLavage(BuildContext context) {
    final plaqueCtrl = TextEditingController();
    final clientCtrl = TextEditingController();
    String service = 'Lavage simple';
    String typeVehicule = 'Voiture';

    final Map<String, Map<String, int>> prix = {
      'Lavage simple': {'Voiture': 2500, 'Moto': 1000, 'SUV / Pickup': 3500},
      'Lavage complet': {'Voiture': 4000, 'Moto': 1500, 'SUV / Pickup': 6000},
      'Lavage + intérieur': {'Voiture': 6000, 'Moto': 2000, 'SUV / Pickup': 9000},
      'Cire & polish': {'Voiture': 10000, 'Moto': 0, 'SUV / Pickup': 15000},
    };

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final prixAuto = prix[service]?[typeVehicule] ?? 0;
          return Padding(
            padding: EdgeInsets.only(
              left: 20, right: 20, top: 20,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Nouveau lavage',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
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
                  value: service,
                  decoration: const InputDecoration(
                    labelText: 'Service',
                    border: OutlineInputBorder(),
                  ),
                  items: prix.keys
                      .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                      .toList(),
                  onChanged: (v) => setModalState(() => service = v!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: typeVehicule,
                  decoration: const InputDecoration(
                    labelText: 'Type de véhicule',
                    border: OutlineInputBorder(),
                  ),
                  items: ['Voiture', 'Moto', 'SUV / Pickup']
                      .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                      .toList(),
                  onChanged: (v) => setModalState(() => typeVehicule = v!),
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
                          style: TextStyle(color: Color(0xFF185FA5), fontSize: 13)),
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
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (plaqueCtrl.text.isEmpty || clientCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Plaque et client requis')),
                        );
                        return;
                      }
                      await _service.ajouterLavage(Lavage(
                        id: '',
                        plaque: plaqueCtrl.text.trim().toUpperCase(),
                        client: clientCtrl.text.trim(),
                        service: service,
                        prix: prixAuto,
                        statut: 'En attente',
                        typeVehicule: typeVehicule,
                        dateHeure: DateTime.now(),
                      ));
                      if (context.mounted) Navigator.pop(context);
                    },
                    child: const Text('Enregistrer',
                        style: TextStyle(fontSize: 15)),
                  ),
                ),
              ],
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
  const _LavageItem({required this.lavage, required this.service});

  Color get _statusColor {
    switch (lavage.statut) {
      case 'Terminé': return const Color(0xFF3B6D11);
      case 'En cours': return const Color(0xFF185FA5);
      default: return const Color(0xFF854F0B);
    }
  }

  void _changerStatut(BuildContext context) async {
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
      child: Row(
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
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
                Text(
                  '${lavage.dateHeure.day}/${lavage.dateHeure.month}/${lavage.dateHeure.year} ${lavage.dateHeure.hour}:${lavage.dateHeure.minute.toString().padLeft(2, '0')}',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                ),
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
                onTap: () => _changerStatut(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(99),
                    border: Border.all(
                        color: _statusColor.withOpacity(0.3)),
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
    );
  }
}