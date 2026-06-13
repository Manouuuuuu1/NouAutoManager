import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  final Function(int) onNavigate;
  const HomeScreen({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A2342),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            children: [
              // Logo
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 24),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 70, height: 70,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.1),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.25),
                          width: 1.5,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('AZ Washing Management',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: 1.2,
                            )),
                        Container(
                          width: 30, height: 2,
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFD700),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Text(
                          'Station de lavage auto',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Titre
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Accès rapide',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.5),
                    letterSpacing: 1.2,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Grille sections
              Flexible(
  child: GridView.count(
  crossAxisCount: 2,
  crossAxisSpacing: 10,
  mainAxisSpacing: 10,
  childAspectRatio: 1.1,
  shrinkWrap: true,
  physics: const ScrollPhysics(),
  children: [
    _SectionBubble(
  titre: 'Enregistrement',
  sousTitre: 'Nouveaux lavages',
  icon: Icons.add_circle_outline_rounded,
  couleur: const Color(0xFF06b6d4),
  onTap: () => onNavigate(1),
),
_SectionBubble(
  titre: 'Tableau de bord',
  sousTitre: 'Stats & historique',
  icon: Icons.dashboard_rounded,
  couleur: const Color(0xFF34d399),
  onTap: () => onNavigate(2),
),
_SectionBubble(
  titre: 'Laveur',
  sousTitre: 'Gestion des laveurs',
  icon: Icons.people_rounded,
  couleur: const Color(0xFFfbbf24),
  onTap: () => onNavigate(3),
),
_SectionBubble(
  titre: 'À propos',
  sousTitre: 'Informations & version',
  icon: Icons.info_outline_rounded,
  couleur: const Color(0xFFa78bfa),
  onTap: () => _showAPropos(context),
),
  ],
),
              ),
              const SizedBox(height: 12),
              
              // Horloge
              _HorlogeWidget(),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  void _showAPropos(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('À propos'),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.local_car_wash, size: 40, color: Color(0xFF185FA5)),
            SizedBox(height: 12),
            Text('AZ Washing Management',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
            SizedBox(height: 4),
            Text('Version 1.0.0', style: TextStyle(color: Colors.grey)),
            SizedBox(height: 12),
            Text(
              'Logiciel de gestion de station de lavage automobile.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Fermer')),
        ],
      ),
    );
  }
}

class _SectionBubble extends StatefulWidget {
  final String titre;
  final String sousTitre;
  final IconData icon;
  final Color couleur;
  final VoidCallback onTap;

  const _SectionBubble({
    required this.titre,
    required this.sousTitre,
    required this.icon,
    required this.couleur,
    required this.onTap,
  });

  @override
  State<_SectionBubble> createState() => _SectionBubbleState();
}

class _SectionBubbleState extends State<_SectionBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController _pressController;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _pressController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.94).animate(
        CurvedAnimation(parent: _pressController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _pressController.forward(),
      onTapUp: (_) {
        _pressController.reverse();
        widget.onTap();
      },
      onTapCancel: () => _pressController.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnim,
        builder: (context, child) => Transform.scale(
          scale: _scaleAnim.value,
          child: child,
        ),
        child: Container(
  decoration: BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        widget.couleur.withValues(alpha: 0.85),
        widget.couleur.withValues(alpha: 0.55),
      ],
    ),
    borderRadius: BorderRadius.circular(18),
    border: Border.all(
      color: widget.couleur.withValues(alpha: 0.4),
      width: 1.5,
    ),
  ),
  child: ClipRRect(
    borderRadius: BorderRadius.circular(18),
    child: Stack(
      children: [
        // Grand cercle décoratif en haut à droite
        Positioned(
          top: -20, right: -20,
          child: Container(
            width: 110, height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ),
        // Petit cercle en bas à gauche
        Positioned(
          bottom: -10, left: -10,
          child: Container(
            width: 60, height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),
        ),
        // Contenu
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icône
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon,
                    color: Colors.white, size: 22),
              ),
              // Texte
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.titre,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      )),
                  const SizedBox(height: 2),
                  Text(widget.sousTitre,
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.white.withValues(alpha: 0.75),
                      )),
                ],
              ),
            ],
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

class _HorlogeWidget extends StatefulWidget {
  @override
  State<_HorlogeWidget> createState() => _HorlogeWidgetState();
}


class _HorlogeWidgetState extends State<_HorlogeWidget> {
  late DateTime _now;

  @override
  void initState() {
    super.initState();
    _now = DateTime.now();
    _tick();
  }

  void _tick() async {
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      setState(() => _now = DateTime.now());
      _tick();
    }
  }

  String get _heure =>
      '${_now.hour.toString().padLeft(2, '0')}:${_now.minute.toString().padLeft(2, '0')}';

  String get _date {
    const jours = [
      'Lundi', 'Mardi', 'Mercredi', 'Jeudi',
      'Vendredi', 'Samedi', 'Dimanche'
    ];
    const mois = [
      'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
      'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre'
    ];
    return '${jours[_now.weekday - 1]} ${_now.day} ${mois[_now.month - 1]} ${_now.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.access_time_rounded,
              color: Colors.white.withValues(alpha: 0.5), size: 16),
          const SizedBox(width: 8),
          Text(_heure,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: 2,
              )),
          const SizedBox(width: 10),
          Container(
              width: 1, height: 20,
              color: Colors.white.withValues(alpha: 0.2)),
          const SizedBox(width: 10),
          Text(_date,
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withValues(alpha: 0.55),
              )),
        ],
      ),
    );
  }
}