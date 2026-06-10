import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/lavage.dart';
import '../services/firestore_service.dart';
import '../services/superviseur_service.dart';

class DashboardScreen extends StatefulWidget {
  final VoidCallback? onHome;
  const DashboardScreen({super.key, this.onHome});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final FirestoreService _service = FirestoreService();
  String _periode = 'Aujourd\'hui';
  DateTime? _dateDebut;
  DateTime? _dateFin;

  final List<String> _periodes = [
    'Aujourd\'hui',
    'Cette semaine',
    'Ce mois',
    'Personnalisée',
  ];

  final Map<String, Color> _serviceColors = {
    'Lavage simple': const Color(0xFF185FA5),
    'Lavage complet': const Color(0xFF3B6D11),
    'Lavage + intérieur': const Color(0xFF854F0B),
    'Cire & polish': const Color(0xFF3C3489),
  };

  List<Lavage> _filtrerParPeriode(List<Lavage> lavages) {
    final now = DateTime.now();
    switch (_periode) {
      case 'Aujourd\'hui':
        return lavages.where((l) =>
            l.dateHeure.day == now.day &&
            l.dateHeure.month == now.month &&
            l.dateHeure.year == now.year).toList();
      case 'Cette semaine':
        final debutSemaine = now.subtract(Duration(days: now.weekday - 1));
        final debut = DateTime(debutSemaine.year, debutSemaine.month, debutSemaine.day);
        return lavages.where((l) => l.dateHeure.isAfter(debut)).toList();
      case 'Ce mois':
        return lavages.where((l) =>
            l.dateHeure.month == now.month &&
            l.dateHeure.year == now.year).toList();
      case 'Personnalisée':
        if (_dateDebut != null && _dateFin != null) {
          return lavages.where((l) =>
              l.dateHeure.isAfter(_dateDebut!.subtract(const Duration(seconds: 1))) &&
              l.dateHeure.isBefore(_dateFin!.add(const Duration(seconds: 1)))).toList();
        }
        return lavages;
      default:
        return lavages;
    }
  }

  Future<void> _choisirDate(bool estDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: estDebut ? (_dateDebut ?? DateTime.now()) : (_dateFin ?? DateTime.now()),
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (estDebut) {
          _dateDebut = DateTime(picked.year, picked.month, picked.day);
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
    if (confirm == true) {
      SuperviseurService.seDeconnecter();
      await FirebaseAuth.instance.signOut();
    }
  }

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: const Text('Tableau de bord',
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

          final tousLavages = snapshot.data!.docs
              .map((d) => Lavage.fromMap(d.id, d.data() as Map<String, dynamic>))
              .toList();

          final lavagesFiltres = _filtrerParPeriode(tousLavages);
          final termines = lavagesFiltres.where((l) => l.statut == 'Terminé').toList();
          final recettes = termines.fold(0, (sum, l) => sum + l.prix);
          final enAttente = lavagesFiltres.where((l) => l.statut == 'En attente').length;
          final enCours = lavagesFiltres.where((l) => l.statut == 'En cours').length;

          // Stats par service
          final Map<String, int> parService = {};
          final Map<String, int> recettesParService = {};
          for (final l in lavagesFiltres) {
            parService[l.service] = (parService[l.service] ?? 0) + 1;
            if (l.statut == 'Terminé') {
              recettesParService[l.service] =
                  (recettesParService[l.service] ?? 0) + l.prix;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                // Sélecteur de période
                SizedBox(
                  height: 38,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _periodes.length,
                    itemBuilder: (context, i) {
                      final selected = _periode == _periodes[i];
                      return GestureDetector(
                        onTap: () => setState(() => _periode = _periodes[i]),
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
                          child: Text(_periodes[i],
                              style: TextStyle(
                                fontSize: 12,
                                color: selected
                                    ? Colors.white
                                    : Colors.grey.shade700,
                                fontWeight: selected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                              )),
                        ),
                      );
                    },
                  ),
                ),

                // Sélecteur dates personnalisées
                if (_periode == 'Personnalisée') ...[
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _choisirDate(true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 14, color: Color(0xFF185FA5)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Du',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                  Text(
                                    _dateDebut != null
                                        ? '${_dateDebut!.day}/${_dateDebut!.month}/${_dateDebut!.year}'
                                        : 'Choisir',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _choisirDate(false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: Row(children: [
                              const Icon(Icons.calendar_today_outlined,
                                  size: 14, color: Color(0xFF185FA5)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text('Au',
                                      style: TextStyle(
                                          fontSize: 10, color: Colors.grey)),
                                  Text(
                                    _dateFin != null
                                        ? '${_dateFin!.day}/${_dateFin!.month}/${_dateFin!.year}'
                                        : 'Choisir',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

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
                      label: 'Total lavages',
                      value: '${lavagesFiltres.length}',
                      icon: Icons.local_car_wash,
                      color: const Color(0xFF185FA5),
                    ),
                    _MetricCard(
                      label: 'Recettes',
                      value: '$recettes F',
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
                      label: 'En cours',
                      value: '$enCours',
                      icon: Icons.autorenew,
                      color: const Color(0xFF3C3489),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // Graphique donut
                if (parService.isNotEmpty) ...[
                  const Text('Répartition par type de lavage',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        SizedBox(
                          height: 200,
                          child: Row(
                            children: [
                              // Donut
                              Expanded(
                                child: PieChart(
                                  PieChartData(
                                    sectionsSpace: 3,
                                    centerSpaceRadius: 50,
                                    sections: parService.entries.map((e) {
                                      final total = parService.values
                                          .fold(0, (a, b) => a + b);
                                      final pct = e.value / total * 100;
                                      return PieChartSectionData(
                                        value: e.value.toDouble(),
                                        color: _serviceColors[e.key] ??
                                            Colors.grey,
                                        radius: 45,
                                        title: '${pct.toStringAsFixed(0)}%',
                                        titleStyle: const TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // Légende
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: parService.entries.map((e) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 4),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 10, height: 10,
                                          decoration: BoxDecoration(
                                            color: _serviceColors[e.key] ??
                                                Colors.grey,
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          e.key.length > 16
                                              ? '${e.key.substring(0, 14)}…'
                                              : e.key,
                                          style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.grey),
                                        ),
                                        /// This class represents a screen for displaying a dashboard in a Flutter application.
                                        const SizedBox(width: 4),
                                        Text('(${e.value})',
                                            style: const TextStyle(
                                                fontSize: 11,
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Graphique barres
                  const Text('Recettes par type de lavage',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: SizedBox(
                      height: 200,
                      child: BarChart(
                        BarChartData(
                          alignment: BarChartAlignment.spaceAround,
                          maxY: recettesParService.values.isEmpty
                              ? 10000
                              : (recettesParService.values
                                          .reduce((a, b) => a > b ? a : b) *
                                      1.3)
                                  .toDouble(),
                          barTouchData: BarTouchData(
                            touchTooltipData: BarTouchTooltipData(
                              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                                final service = recettesParService.keys
                                    .toList()[groupIndex];
                                return BarTooltipItem(
                                  '$service\n${rod.toY.toInt()} F',
                                  const TextStyle(
                                      color: Colors.white, fontSize: 11),
                                );
                              },
                            ),
                          ),
                          titlesData: FlTitlesData(
                            leftTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                reservedSize: 46,
                                getTitlesWidget: (val, meta) => Text(
                                  '${(val / 1000).toStringAsFixed(0)}k',
                                  style: const TextStyle(
                                      fontSize: 10, color: Colors.grey),
                                ),
                              ),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (val, meta) {
                                  final keys =
                                      recettesParService.keys.toList();
                                  if (val.toInt() >= keys.length) {
                                    return const SizedBox.shrink();
                                  }
                                  final label = keys[val.toInt()];
                                  final short = label.contains('+')
                                      ? 'L+Int'
                                      : label.contains('Cire')
                                          ? 'Cire'
                                          : label.contains('complet')
                                              ? 'Complet'
                                              : 'Simple';
                                  return Text(short,
                                      style: const TextStyle(
                                          fontSize: 10, color: Colors.grey));
                                },
                              ),
                            ),
                            topTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                            rightTitles: const AxisTitles(
                                sideTitles: SideTitles(showTitles: false)),
                          ),
                          gridData: FlGridData(
                            drawVerticalLine: false,
                            getDrawingHorizontalLine: (val) => FlLine(
                              color: Colors.grey.shade200,
                              strokeWidth: 1,
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          barGroups: recettesParService.entries
                              .toList()
                              .asMap()
                              .entries
                              .map((entry) => BarChartGroupData(
                                    x: entry.key,
                                    barRods: [
                                      BarChartRodData(
                                        toY: entry.value.value.toDouble(),
                                        color: _serviceColors[
                                                entry.value.key] ??
                                            Colors.grey,
                                        width: 28,
                                        borderRadius:
                                            BorderRadius.circular(6),
                                      ),
                                    ],
                                  ))
                              .toList(),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tableau détaillé
                  const Text('Détail par type de lavage',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: Column(
                      children: [
                        // En-tête tableau
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(14)),
                            border: Border(
                                bottom:
                                    BorderSide(color: Colors.grey.shade200)),
                          ),
                          child: const Row(
                            children: [
                              Expanded(
                                  flex: 3,
                                  child: Text('Service',
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey))),
                              Expanded(
                                  child: Text('Nb',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey))),
                              Expanded(
                                  flex: 2,
                                  child: Text('Recettes',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey))),
                              Expanded(
                                  child: Text('%',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.grey))),
                            ],
                          ),
                        ),
                        // Lignes
                        ...parService.entries.map((e) {
                          final total = parService.values
                              .fold(0, (a, b) => a + b);
                          final pct = (e.value / total * 100)
                              .toStringAsFixed(1);
                          final rec =
                              recettesParService[e.key] ?? 0;
                          final color =
                              _serviceColors[e.key] ?? Colors.grey;
                          return Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Colors.grey.shade100)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: Row(
                                    children: [
                                      Container(
                                        width: 10, height: 10,
                                        decoration: BoxDecoration(
                                          color: color,
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(e.key,
                                            style: const TextStyle(
                                                fontSize: 12)),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  child: Text('${e.value}',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                          color: color)),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: Text(
                                      '${rec.toStringAsFixed(0)} F',
                                      textAlign: TextAlign.right,
                                      style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500)),
                                ),
                                Expanded(
                                  child: Text('$pct%',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: color,
                                          fontWeight: FontWeight.w500)),
                                ),
                              ],
                            ),
                          );
                        }),

                        // Total
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: const BorderRadius.vertical(
                                bottom: Radius.circular(14)),
                          ),
                          child: Row(
                            children: [
                              const Expanded(
                                flex: 3,
                                child: Text('TOTAL',
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ),
                              Expanded(
                                child: Text(
                                    '${lavagesFiltres.length}',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text('$recettes F',
                                    textAlign: TextAlign.right,
                                    style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF3B6D11))),
                              ),
                              const Expanded(
                                child: Text('100%',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                if (lavagesFiltres.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32),
                    margin: const EdgeInsets.only(top: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                    ),
                    child: const Column(
                      children: [
                        Icon(Icons.bar_chart_outlined,
                            size: 40, color: Colors.grey),
                        SizedBox(height: 10),
                        Text('Aucun lavage sur cette période',
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),

                const SizedBox(height: 20),

                // Liste des lavages de la période
                if (lavagesFiltres.isNotEmpty) ...[
                  const Text('Liste des lavages',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 12),
                  ...lavagesFiltres.map((l) => _LavageItem(
                    lavage: l,
                    service: _service,
                    onModifier: () async {
                      final ok = await _verifierSuperviseur();
                      if (ok && context.mounted) {
                        _showFormulaireLavage(context, lavage: l);
                      }
                    },
                    onSupprimer: () async {
                      final ok = await _verifierSuperviseur();
                      if (ok) _confirmerSuppression(l.id);
                    },
                  )),
                ],

                const SizedBox(height: 80),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showFormulaireLavage(BuildContext context, {Lavage? lavage}) async {
    final laveurs = await _service.getLaveurs().first;
    final nomsLaveurs = laveurs.map((l) => l.nomComplet).toList();
    if (nomsLaveurs.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Aucun employé enregistré.')),
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

    final Map<String, Map<String, int>> prix = {
      'Lavage simple': {'Voiture': 2500, 'Moto': 1000, 'SUV / Pickup': 3500},
      'Lavage complet': {'Voiture': 4000, 'Moto': 1500, 'SUV / Pickup': 6000},
      'Lavage + intérieur': {'Voiture': 6000, 'Moto': 2000, 'SUV / Pickup': 9000},
      'Cire & polish': {'Voiture': 10000, 'Moto': 0, 'SUV / Pickup': 15000},
    };

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final prixAuto = prix[service]?[typeVehicule] ?? 0;
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
                  const Text('Modifier le lavage',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: plaqueCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Plaque', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: clientCtrl,
                    decoration: const InputDecoration(
                        labelText: 'Client', border: OutlineInputBorder()),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: service,
                    decoration: const InputDecoration(
                        labelText: 'Service', border: OutlineInputBorder()),
                    items: prix.keys
                        .map((s) =>
                            DropdownMenuItem(value: s, child: Text(s)))
                        .toList(),
                    onChanged: (v) => setModalState(() => service = v!),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: typeVehicule,
                    decoration: const InputDecoration(
                        labelText: 'Type véhicule',
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
                      labelText: 'Laveur',
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
                        const Text('Prix',
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
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () async {
                        if (lavage != null) {
                          await _service.modifierLavage(lavage.id, {
                            'plaque':
                                plaqueCtrl.text.trim().toUpperCase(),
                            'client': clientCtrl.text.trim(),
                            'service': service,
                            'typeVehicule': typeVehicule,
                            'laveur': laveur,
                            'prix': prixAuto,
                          });
                        }
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Enregistrer les modifications',
                          style: TextStyle(fontSize: 15)),
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
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: color)),
              Text(label,
                  style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
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
                  color: _statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.directions_car,
                    color: _statusColor, size: 20),
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