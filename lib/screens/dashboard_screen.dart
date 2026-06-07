import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lavage.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('AutoWash',
            style: TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF185FA5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('lavages')
            .orderBy('dateHeure', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Erreur de connexion'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final lavages = snapshot.data!.docs
              .map((d) => Lavage.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();

          final today = DateTime.now();
          final lavagesAujourdhui = lavages.where((l) =>
              l.dateHeure.day == today.day &&
              l.dateHeure.month == today.month &&
              l.dateHeure.year == today.year).toList();

          final recettes = lavagesAujourdhui
              .where((l) => l.statut == 'Terminé')
              .fold(0, (sum, l) => sum + l.prix);

          final enAttente = lavagesAujourdhui
              .where((l) => l.statut == 'En attente' || l.statut == 'En cours')
              .length;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Métriques
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.6,
                  children: [
                    _MetricCard(
                      label: "Lavages aujourd'hui",
                      value: '${lavagesAujourdhui.length}',
                      icon: Icons.local_car_wash,
                      color: const Color(0xFF185FA5),
                    ),
                    _MetricCard(
                      label: 'Recettes du jour',
                      value: '${recettes.toString()} F',
                      icon: Icons.payments_outlined,
                      color: const Color(0xFF3B6D11),
                    ),
                    _MetricCard(
                      label: 'En attente',
                      value: '$enAttente',
                      icon: Icons.hourglass_empty,
                      color: const Color(0xFF854F0B),
                    ),
                    _MetricCard(
                      label: 'Total lavages',
                      value: '${lavages.length}',
                      icon: Icons.history,
                      color: const Color(0xFF3C3489),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Derniers lavages
                const Text('Derniers lavages',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),

                if (lavages.isEmpty)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text('Aucun lavage enregistré',
                          style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  ...lavages.take(5).map((l) => _LavageCard(lavage: l)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _MetricCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Icon(icon, color: color, size: 22),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600, color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _LavageCard extends StatelessWidget {
  final Lavage lavage;
  const _LavageCard({required this.lavage});

  Color get _statusColor {
    switch (lavage.statut) {
      case 'Terminé': return const Color(0xFF3B6D11);
      case 'En cours': return const Color(0xFF185FA5);
      default: return const Color(0xFF854F0B);
    }
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
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFE6F1FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.directions_car, color: Color(0xFF185FA5), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(lavage.plaque,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                Text('${lavage.service} · ${lavage.client}',
                    style: const TextStyle(color: Colors.grey, fontSize: 12)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${lavage.prix} F',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(lavage.statut,
                    style: TextStyle(color: _statusColor, fontSize: 11)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}