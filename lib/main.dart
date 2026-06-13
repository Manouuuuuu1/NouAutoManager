import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'screens/home_screen.dart';
import 'screens/historique_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/laveurs_screen.dart';
import 'services/cache_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const AutoWashApp());
}

class AutoWashApp extends StatelessWidget {
  const AutoWashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Select Car Wash',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF185FA5)),
        useMaterial3: true,
      ),
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }
          if (snapshot.hasData) {
  CacheService().init();
  return const MainScreen();
}
CacheService().dispose();
return const SplashScreen();
        },
      ),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  void changerOnglet(int index) {
    setState(() => _currentIndex = index);
  }

  List<Widget> get _screens => [
    HomeScreen(onNavigate: changerOnglet),
    HistoriqueScreen(onHome: () => changerOnglet(0)),
    DashboardScreen(onHome: () => changerOnglet(0)),
    LaveursScreen(onHome: () => changerOnglet(0)),
  ];

  @override
Widget build(BuildContext context) {
  return Scaffold(
    // IndexedStack garde toutes les pages en mémoire
    // au lieu de les détruire/recréer à chaque navigation
    body: IndexedStack(
      index: _currentIndex,
      children: [
        HomeScreen(onNavigate: changerOnglet),
        HistoriqueScreen(onHome: () => changerOnglet(0)),
        DashboardScreen(onHome: () => changerOnglet(0)),
        LaveursScreen(onHome: () => changerOnglet(0)),
      ],
    ),
    bottomNavigationBar: _currentIndex == 0
        ? null
        : BottomNavigationBar(
            currentIndex: _currentIndex,
            onTap: (i) => setState(() => _currentIndex = i),
            selectedItemColor: const Color(0xFF185FA5),
            unselectedItemColor: Colors.grey,
            type: BottomNavigationBarType.fixed,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.home_outlined),
                activeIcon: Icon(Icons.home),
                label: 'Accueil',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.add_circle_outline),
                activeIcon: Icon(Icons.add_circle),
                label: 'Enregistrement',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.dashboard_outlined),
                activeIcon: Icon(Icons.dashboard),
                label: 'Tableau de bord',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.people_outline),
                activeIcon: Icon(Icons.people),
                label: 'Laveurs',
              ),
            ],
          ),
  );
}   }