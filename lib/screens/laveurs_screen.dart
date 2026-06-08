import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lavage.dart';
import '../services/firestore_service.dart';

class LaveursScreen extends StatefulWidget {
  const LaveursScreen({super.key});

  @override
  State<LaveursScreen> createState() => _LaveursScreenState();
}

class _LaveursScreenState extends State<LaveursScreen> {
  final FirestoreService _service = FirestoreService();

  final List<String> _laveurs = [
    'Koné Mamadou',
    'Traoré Seydou',
    'Bamba Inza',
    'Coulibaly Adama',
  ];

  final Map<String, double> _commissions = {
    'Lavage simple': 0.30,
    'Lavage complet': 0.35,
    'Lavage + intérieur': 0.35,
    'Cire & polish': 0.40,
  };

  String _laveurSelectionne = 'Koné Mamadou';
  DateTime _dateDebut = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime _dateFin = DateTime.now();

  double _calculerCommission(Lavage l) {
    final taux = _commissions[l.service] ?? 0.30;
    return l.prix * taux;
  }

  Future<void> _choisirDate(bool estDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: estDebut ? _dateDebut : _dateFin,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      locale: const Locale('fr', 'FR'),
    );
    if (picked != null) {
      setState(() {
        if (estDebut) {
          _dateDebut = picked;
        } else {
          _dateFin = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
        }
      });
    }
  }

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
        title: const Text('Laveurs & Paie',
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

          // Filtrer par laveur et période
          final lavagesFiltres = tousLavages.where((l) =>
              l.laveur == _laveurSelectionne &&
              l.statut == 'Terminé' &&
              l.dateHeure.isAfter(_dateDebut.subtract(const Duration(seconds: 1))) &&
              l.dateHeure.isBefore(_dateFin.add(const Duration(seconds: 1)))).toList();

          // Calculs
          final totalLavages = lavagesFiltres.length;
          final chiffreAffaires = lavagesFiltres.fold(0, (sum, l) => sum + l.prix);
          final totalCommission = lavagesFiltres.fold(
              0.0, (sum, l) => sum + _calculerCommission(l));

          // Répartition par service
          final Map<String, int> parService = {};
          final Map<String, double> commissionParService = {};
          for (final l in lavagesFiltres) {
            parService[l.service] = (parService[l.service] ?? 0) + 1;
            commissionParService[l.service] =
                (commissionParService[l.service] ?? 0) + _calculerCommission(l);
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Sélection laveur
                _SectionTitle(title: 'Sélectionner un laveur'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 44,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _laveurs.length,
                    itemBuilder: (context, i) {
                      final selected = _laveurSelectionne == _laveurs[i];
                      return GestureDetector(
                        onTap: () => setState(
                            () => _laveurSelectionne = _laveurs[i]),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
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
                            _laveurs[i],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: selected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                              color: selected
                                  ? Colors.white
                                  : Colors.grey.shade700,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),

                // Sélection période
                _SectionTitle(title: 'Période'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _DateButton(
                        label: 'Du',
                        date: _dateDebut,
                        onTap: () => _choisirDate(true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateButton(
                        label: 'Au',
                        date: _dateFin,
                        onTap: () => _choisirDate(false),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Métriques
                _SectionTitle(title: 'Résumé — $_laveurSelectionne'),
                const SizedBox(height: 8),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1.7,
                  children: [
                    _MetricCard(
                      label: 'Lavages effectués',
                      value: '$totalLavages',
                      icon: Icons.local_car_wash,
                      color: const Color(0xFF185FA5),
                    ),
                    _MetricCard(
                      label: 'Chiffre d\'affaires',
                      value: '${chiffreAffaires.toStringAsFixed(0)} F',
                      icon: Icons.payments_outlined,
                      color: const Color(0xFF3B6D11),
                    ),
                    _MetricCard(
                      label: 'Commission totale',
                      value: '${totalCommission.toStringAsFixed(0)} F',
                      icon: Icons.account_balance_wallet_outlined,
                      color: const Color(0xFF854F0B),
                    ),
                    _MetricCard(
                      label: 'Commission moyenne',
                      value: totalLavages > 0
                          ? '${(totalCommission / totalLavages).toStringAsFixed(0)} F'
                          : '0 F',
                      icon: Icons.percent,
                      color: const Color(0xFF3C3489),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // Répartition par service
                if (parService.isNotEmpty) ...[
                  _SectionTitle(title: 'Répartition par service'),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: _commissions.keys.map((service) {
                        final nb = parService[service] ?? 0;
                        final comm = commissionParService[service] ?? 0;
                        final taux =
                            ((_commissions[service] ?? 0) * 100).toInt();
                        if (nb == 0) return const SizedBox.shrink();
                        return _ServiceRow(
                          service: service,
                          nb: nb,
                          commission: comm,
                          taux: taux,
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Bulletin de paie
                _SectionTitle(title: 'Bulletin de paie'),
                const SizedBox(height: 8),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('AutoWash',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 16,
                                  color: Color(0xFF185FA5))),
                          Text(
                            'Du ${_dateDebut.day}/${_dateDebut.month}/${_dateDebut.year} au ${_dateFin.day}/${_dateFin.month}/${_dateFin.year}',
                            style: const TextStyle(
                                fontSize: 11, color: Colors.grey),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      _BulletinRow(
                          label: 'Employé', value: _laveurSelectionne),
                      _BulletinRow(
                          label: 'Nombre de lavages',
                          value: '$totalLavages lavages'),
                      _BulletinRow(
                          label: 'Chiffre d\'affaires généré',
                          value: '${chiffreAffaires.toStringAsFixed(0)} F CFA'),
                      const Divider(height: 24),
                      ...commissionParService.entries.map((e) => _BulletinRow(
                            label:
                                '${e.key} (${((_commissions[e.key] ?? 0) * 100).toInt()}%)',
                            value: '${e.value.toStringAsFixed(0)} F CFA',
                          )),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('TOTAL À PAYER',
                              style: TextStyle(
                                  fontWeight: FontWeight.w700, fontSize: 15)),
                          Text(
                            '${totalCommission.toStringAsFixed(0)} F CFA',
                            style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 18,
                                color: Color(0xFF185FA5)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600));
  }
}

class _DateButton extends StatelessWidget {
  final String label;
  final DateTime date;
  final VoidCallback onTap;
  const _DateButton(
      {required this.label, required this.date, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined,
                size: 16, color: Color(0xFF185FA5)),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 11, color: Colors.grey)),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w600, fontSize: 13),
                ),
              ],
            ),
          ],
        ),
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
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: color)),
              Text(label,
                  style:
                      const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _ServiceRow extends StatelessWidget {
  final String service;
  final int nb;
  final double commission;
  final int taux;

  const _ServiceRow({
    required this.service,
    required this.nb,
    required this.commission,
    required this.taux,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey.shade100)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(service,
                    style: const TextStyle(
                        fontWeight: FontWeight.w500, fontSize: 13)),
                Text('$nb lavage${nb > 1 ? 's' : ''} · $taux% de commission',
                    style:
                        const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Text('${commission.toStringAsFixed(0)} F',
              style: const TextStyle(
                  fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}

class _BulletinRow extends StatelessWidget {
  final String label;
  final String value;
  const _BulletinRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style:
                  const TextStyle(fontSize: 13, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}