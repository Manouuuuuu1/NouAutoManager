import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/lavage.dart';
import '../models/laveur.dart';
import '../services/firestore_service.dart';
import '../services/superviseur_service.dart';

class LaveursScreen extends StatefulWidget {
  final VoidCallback? onHome;
  const LaveursScreen({super.key, this.onHome});

  @override
  State<LaveursScreen> createState() => _LaveursScreenState();
}

class _LaveursScreenState extends State<LaveursScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirestoreService _service = FirestoreService();

  final Map<String, double> _commissions = {
    'Lavage simple': 0.30,
    'Lavage complet': 0.35,
    'Lavage + intérieur': 0.35,
    'Cire & polish': 0.40,
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: GestureDetector(
          onTap: () => widget.onHome?.call(),
          child: Image.asset('assets/images/logo.png', height: 32),
        ),
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
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Employés'),
            Tab(text: 'Bulletin de paie'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _EmployesTab(service: _service),
          _BulletinTab(
              service: _service, commissions: _commissions),
        ],
      ),
    );
  }
}

// ── ONGLET EMPLOYÉS ───────────────────────────────────────────────────────

class _EmployesTab extends StatelessWidget {
  final FirestoreService service;
  const _EmployesTab({required this.service});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showFormulaireEmploye(context),
        backgroundColor: const Color(0xFF185FA5),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text('Nouvel employé'),
      ),
      body: StreamBuilder<List<Laveur>>(
        stream: service.getLaveurs(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final laveurs = snapshot.data ?? [];
          if (laveurs.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.people_outline,
                      size: 48, color: Colors.grey),
                  SizedBox(height: 12),
                  Text('Aucun employé enregistré',
                      style: TextStyle(color: Colors.grey)),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: laveurs.length,
            itemBuilder: (context, i) => _EmployeCard(
              laveur: laveurs[i],
              service: service,
              onModifier: () =>
                  _showFormulaireEmploye(context, laveur: laveurs[i]),
            ),
          );
        },
      ),
    );
  }

  void _showFormulaireEmploye(BuildContext context,
      {Laveur? laveur}) {
    final nomCtrl =
        TextEditingController(text: laveur?.nom ?? '');
    final prenomCtrl =
        TextEditingController(text: laveur?.prenom ?? '');
    final telCtrl =
        TextEditingController(text: laveur?.telephone ?? '');
    final adresseCtrl =
        TextEditingController(text: laveur?.adresse ?? '');
    final cniCtrl =
        TextEditingController(text: laveur?.numeroCNI ?? '');
    DateTime dateNaissance =
        laveur?.dateNaissance ?? DateTime(1990, 1, 1);
    final bool estModification = laveur != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom:
                MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  estModification
                      ? 'Modifier l\'employé'
                      : 'Nouvel employé',
                  style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 16),
                Row(children: [
                  Expanded(
                    child: TextField(
                      controller: prenomCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Prénom',
                          border: OutlineInputBorder()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: nomCtrl,
                      decoration: const InputDecoration(
                          labelText: 'Nom',
                          border: OutlineInputBorder()),
                    ),
                  ),
                ]),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: dateNaissance,
                      firstDate: DateTime(1950),
                      lastDate: DateTime.now(),
                    );
                    if (picked != null) {
                      setModalState(
                          () => dateNaissance = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 14),
                    decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.grey.shade400),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.cake_outlined,
                            size: 18, color: Colors.grey),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text('Date de naissance',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey)),
                            Text(
                              '${dateNaissance.day}/${dateNaissance.month}/${dateNaissance.year}',
                              style: const TextStyle(
                                  fontSize: 14),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: telCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Téléphone',
                    prefixIcon:
                        Icon(Icons.phone_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: adresseCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Adresse',
                    prefixIcon:
                        Icon(Icons.location_on_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: cniCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Numéro CNI / Pièce d\'identité',
                    prefixIcon: Icon(Icons.badge_outlined),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          const Color(0xFF185FA5),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14),
                      shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(10)),
                    ),
                    onPressed: () async {
                      if (nomCtrl.text.isEmpty ||
                          prenomCtrl.text.isEmpty) {
                        ScaffoldMessenger.of(context)
                            .showSnackBar(
                          const SnackBar(
                              content: Text(
                                  'Nom et prénom requis')),
                        );
                        return;
                      }
                      if (estModification) {
                        await service.modifierLaveur(
                            laveur.id, {
                          'nom': nomCtrl.text.trim(),
                          'prenom': prenomCtrl.text.trim(),
                          'dateNaissance':
                              dateNaissance.toIso8601String(),
                          'telephone': telCtrl.text.trim(),
                          'adresse': adresseCtrl.text.trim(),
                          'numeroCNI': cniCtrl.text.trim(),
                        });
                      } else {
                        await service.ajouterLaveur(Laveur(
                          id: '',
                          nom: nomCtrl.text.trim(),
                          prenom: prenomCtrl.text.trim(),
                          dateNaissance: dateNaissance,
                          telephone: telCtrl.text.trim(),
                          adresse: adresseCtrl.text.trim(),
                          numeroCNI: cniCtrl.text.trim(),
                          dateEmbauche: DateTime.now(),
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
                      style: const TextStyle(fontSize: 15),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmployeCard extends StatelessWidget {
  final Laveur laveur;
  final FirestoreService service;
  final VoidCallback onModifier;

  const _EmployeCard({
    required this.laveur,
    required this.service,
    required this.onModifier,
  });

  void _confirmerSuppression(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer cet employé ?'),
        content:
            const Text('Cette action est irréversible.'),
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
    if (confirm == true)
      await service.supprimerLaveur(laveur.id);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFE6F1FB),
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Center(
                  child: Text(
                    '${laveur.prenom[0]}${laveur.nom[0]}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF185FA5),
                        fontSize: 16),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(laveur.nomComplet,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 15)),
                    Text('CNI : ${laveur.numeroCNI}',
                        style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1),
          const SizedBox(height: 10),
          Row(
            children: [
              const Icon(Icons.phone_outlined,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(laveur.telephone,
                  style: const TextStyle(
                      fontSize: 13, color: Colors.grey)),
              const SizedBox(width: 16),
              const Icon(Icons.location_on_outlined,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Expanded(
                child: Text(laveur.adresse,
                    style: const TextStyle(
                        fontSize: 13, color: Colors.grey),
                    overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(Icons.cake_outlined,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Né(e) le ${laveur.dateNaissance.day}/${laveur.dateNaissance.month}/${laveur.dateNaissance.year}',
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey),
              ),
              const SizedBox(width: 16),
              const Icon(Icons.work_outline,
                  size: 14, color: Colors.grey),
              const SizedBox(width: 6),
              Text(
                'Depuis ${laveur.dateEmbauche.day}/${laveur.dateEmbauche.month}/${laveur.dateEmbauche.year}',
                style: const TextStyle(
                    fontSize: 13, color: Colors.grey),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: onModifier,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6F1FB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Modifier',
                      style: TextStyle(
                          color: Color(0xFF185FA5),
                          fontSize: 12)),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () =>
                    _confirmerSuppression(context),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEBEB),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text('Supprimer',
                      style: TextStyle(
                          color: Color(0xFFA32D2D),
                          fontSize: 12)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── ONGLET BULLETIN DE PAIE ───────────────────────────────────────────────

class _BulletinTab extends StatefulWidget {
  final FirestoreService service;
  final Map<String, double> commissions;
  const _BulletinTab(
      {required this.service, required this.commissions});

  @override
  State<_BulletinTab> createState() => _BulletinTabState();
}

class _BulletinTabState extends State<_BulletinTab> {
  String? _laveurSelectionne;
  DateTime _dateDebut = DateTime(
      DateTime.now().year, DateTime.now().month, 1);
  DateTime _dateFin = DateTime.now();

  double _calculerCommission(Lavage l) {
    final taux = widget.commissions[l.service] ?? 0.30;
    return l.prix * taux;
  }

  Future<void> _choisirDate(bool estDebut) async {
    final picked = await showDatePicker(
      context: context,
      initialDate:
          estDebut ? _dateDebut : _dateFin,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        if (estDebut) {
          _dateDebut = DateTime(
              picked.year, picked.month, picked.day);
        } else {
          _dateFin = DateTime(picked.year, picked.month,
              picked.day, 23, 59, 59);
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Laveur>>(
      stream: widget.service.getLaveurs(),
      builder: (context, snapLaveurs) {
        final laveurs = snapLaveurs.data ?? [];
        if (laveurs.isNotEmpty &&
            _laveurSelectionne == null) {
          _laveurSelectionne = laveurs.first.nomComplet;
        }

        return StreamBuilder<List<Lavage>>(
          stream: widget.service.getLavages(),
          builder: (context, snapLavages) {
            if (snapLavages.connectionState ==
                ConnectionState.waiting) {
              return const Center(
                  child: CircularProgressIndicator());
            }

            final tousLavages = snapLavages.data ?? [];
            final lavagesFiltres = tousLavages
                .where((l) =>
                    l.laveur == _laveurSelectionne &&
                    l.statut == 'Terminé' &&
                    l.dateHeure.isAfter(_dateDebut.subtract(
                        const Duration(seconds: 1))) &&
                    l.dateHeure.isBefore(_dateFin
                        .add(const Duration(seconds: 1))))
                .toList();

            final totalLavages = lavagesFiltres.length;
            final chiffreAffaires = lavagesFiltres
                .fold(0, (sum, l) => sum + l.prix);
            final totalCommission = lavagesFiltres.fold(
                0.0,
                (sum, l) =>
                    sum + _calculerCommission(l));

            // Temps moyen par laveur
            final lavagesAvecDuree = lavagesFiltres
                .where(
                    (l) => l.dureeLavageMinutes != null)
                .toList();
            final tempsMoyen = lavagesAvecDuree.isEmpty
                ? '—'
                : '${(lavagesAvecDuree.fold(0, (sum, l) => sum + l.dureeLavageMinutes!) / lavagesAvecDuree.length).toStringAsFixed(0)} min';

            final Map<String, int> parService = {};
            final Map<String, double>
                commissionParService = {};
            for (final l in lavagesFiltres) {
              parService[l.service] =
                  (parService[l.service] ?? 0) + 1;
              commissionParService[l.service] =
                  (commissionParService[l.service] ??
                          0) +
                      _calculerCommission(l);
            }

            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  // Sélection laveur
                  const Text('Sélectionner un employé',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  if (laveurs.isEmpty)
                    const Text('Aucun employé enregistré',
                        style:
                            TextStyle(color: Colors.grey))
                  else
                    SizedBox(
                      height: 44,
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: laveurs.length,
                        itemBuilder: (context, i) {
                          final selected =
                              _laveurSelectionne ==
                                  laveurs[i].nomComplet;
                          return GestureDetector(
                            onTap: () => setState(() =>
                                _laveurSelectionne =
                                    laveurs[i].nomComplet),
                            child: Container(
                              margin: const EdgeInsets
                                  .only(right: 8),
                              padding:
                                  const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 10),
                              decoration: BoxDecoration(
                                color: selected
                                    ? const Color(
                                        0xFF185FA5)
                                    : Colors.white,
                                borderRadius:
                                    BorderRadius.circular(
                                        99),
                                border: Border.all(
                                  color: selected
                                      ? const Color(
                                          0xFF185FA5)
                                      : Colors
                                          .grey.shade300,
                                ),
                              ),
                              child: Text(
                                laveurs[i].nomComplet,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: selected
                                      ? FontWeight.w600
                                      : FontWeight.normal,
                                  color: selected
                                      ? Colors.white
                                      : Colors
                                          .grey.shade700,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Période
                  const Text('Période',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _choisirDate(true),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                      10),
                              border: Border.all(
                                  color: Colors
                                      .grey.shade300),
                            ),
                            child: Row(children: [
                              const Icon(
                                  Icons
                                      .calendar_today_outlined,
                                  size: 16,
                                  color:
                                      Color(0xFF185FA5)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  const Text('Du',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              Colors.grey)),
                                  Text(
                                    '${_dateDebut.day}/${_dateDebut.month}/${_dateDebut.year}',
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ]),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              _choisirDate(false),
                          child: Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 14,
                                    vertical: 12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(
                                      10),
                              border: Border.all(
                                  color: Colors
                                      .grey.shade300),
                            ),
                            child: Row(children: [
                              const Icon(
                                  Icons
                                      .calendar_today_outlined,
                                  size: 16,
                                  color:
                                      Color(0xFF185FA5)),
                              const SizedBox(width: 8),
                              Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment
                                        .start,
                                children: [
                                  const Text('Au',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color:
                                              Colors.grey)),
                                  Text(
                                    '${_dateFin.day}/${_dateFin.month}/${_dateFin.year}',
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                        fontSize: 13),
                                  ),
                                ],
                              ),
                            ]),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Métriques
                  const Text('Résumé',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(),
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
                        value:
                            '${chiffreAffaires.toStringAsFixed(0)} F',
                        icon: Icons.payments_outlined,
                        color: const Color(0xFF3B6D11),
                      ),
                      _MetricCard(
                        label: 'Commission totale',
                        value:
                            '${totalCommission.toStringAsFixed(0)} F',
                        icon: Icons
                            .account_balance_wallet_outlined,
                        color: const Color(0xFF854F0B),
                      ),
                      _MetricCard(
                        label: 'Temps moyen',
                        value: tempsMoyen,
                        icon: Icons.timer_outlined,
                        color: const Color(0xFF0891b2),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Répartition par service
                  if (parService.isNotEmpty) ...[
                    const Text('Répartition par service',
                        style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius:
                            BorderRadius.circular(12),
                        border: Border.all(
                            color: Colors.grey.shade200),
                      ),
                      child: Column(
                        children: widget.commissions.keys
                            .map((service) {
                          final nb =
                              parService[service] ?? 0;
                          final comm =
                              commissionParService[
                                      service] ??
                                  0;
                          final taux = ((widget.commissions[
                                          service] ??
                                      0) *
                                  100)
                              .toInt();
                          if (nb == 0)
                            return const SizedBox
                                .shrink();
                          return Container(
                            padding:
                                const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12),
                            decoration: BoxDecoration(
                              border: Border(
                                  bottom: BorderSide(
                                      color: Colors
                                          .grey.shade100)),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment
                                            .start,
                                    children: [
                                      Text(service,
                                          style: const TextStyle(
                                              fontWeight:
                                                  FontWeight
                                                      .w500,
                                              fontSize:
                                                  13)),
                                      Text(
                                          '$nb lavage${nb > 1 ? 's' : ''} · $taux%',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: Colors
                                                  .grey)),
                                    ],
                                  ),
                                ),
                                Text(
                                    '${comm.toStringAsFixed(0)} F',
                                    style: const TextStyle(
                                        fontWeight:
                                            FontWeight.w600,
                                        fontSize: 13)),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Bulletin de paie
                  const Text('Bulletin de paie',
                      style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius:
                          BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.grey.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            const Text('AZ Washing Management',
                                style: TextStyle(
                                    fontWeight:
                                        FontWeight.w700,
                                    fontSize: 16,
                                    color: Color(
                                        0xFF185FA5))),
                            Text(
                              '${_dateDebut.day}/${_dateDebut.month}/${_dateDebut.year} → ${_dateFin.day}/${_dateFin.month}/${_dateFin.year}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey),
                            ),
                          ],
                        ),
                        const Divider(height: 24),
                        _BulletinRow(
                            label: 'Employé',
                            value:
                                _laveurSelectionne ?? '—'),
                        _BulletinRow(
                            label: 'Lavages effectués',
                            value:
                                '$totalLavages lavages'),
                        _BulletinRow(
                            label:
                                'Chiffre d\'affaires généré',
                            value:
                                '${chiffreAffaires.toStringAsFixed(0)} F CFA'),
                        _BulletinRow(
                            label: 'Temps moyen par lavage',
                            value: tempsMoyen),
                        const Divider(height: 24),
                        ...commissionParService.entries
                            .map((e) => _BulletinRow(
                                  label:
                                      '${e.key} (${((widget.commissions[e.key] ?? 0) * 100).toInt()}%)',
                                  value:
                                      '${e.value.toStringAsFixed(0)} F CFA',
                                )),
                        const Divider(height: 24),
                        Row(
                          mainAxisAlignment:
                              MainAxisAlignment
                                  .spaceBetween,
                          children: [
                            const Text('TOTAL À PAYER',
                                style: TextStyle(
                                    fontWeight:
                                        FontWeight.w700,
                                    fontSize: 15)),
                            Text(
                              '${totalCommission.toStringAsFixed(0)} F CFA',
                              style: const TextStyle(
                                  fontWeight:
                                      FontWeight.w700,
                                  fontSize: 18,
                                  color:
                                      Color(0xFF185FA5)),
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
        );
      },
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
                  style: const TextStyle(
                      fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }
}

class _BulletinRow extends StatelessWidget {
  final String label;
  final String value;
  const _BulletinRow(
      {required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 13, color: Colors.grey)),
          Text(value,
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}