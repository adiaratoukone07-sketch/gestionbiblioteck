import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';

import 'controllers/auth_controller.dart';
import 'database/utilisateur_dao.dart';
import 'views/login_page.dart';

void main() async {
  // Nécessaire car on fait un appel asynchrone (accès SQLite) avant runApp().
  WidgetsFlutterBinding.ensureInitialized();
  await _creerCompteTestSiBesoin();
  runApp(const BibliothequeApp());

  // Configure la fenêtre "frameless" (sans barre de titre Windows par
  // défaut) : cf. `lib/widgets/custom_title_bar.dart` pour la barre
  // personnalisée affichée à la place sur chaque page.
  doWhenWindowReady(() {
    const tailleInitiale = Size(1280, 720);
    appWindow.minSize = const Size(1000, 650);
    appWindow.size = tailleInitiale;
    appWindow.alignment = Alignment.center;
    appWindow.title = 'Bibliotech';
    appWindow.show();
  });
}

/// Crée un compte bibliothécaire de test au tout premier lancement, si
/// la table UTILISATEUR est vide.
///
/// ⚠️ Purement temporaire : le cahier des charges ne prévoit pas
/// d'auto-inscription (un seul compte administrateur), donc il n'y a
/// pas encore d'écran dédié à la création de compte. Ce bloc permet de
/// tester l'application dès maintenant ; à retirer une fois qu'un
/// véritable mécanisme d'initialisation du compte sera en place.
Future<void> _creerCompteTestSiBesoin() async {
  final utilisateurDao = UtilisateurDao();
  final utilisateursExistants = await utilisateurDao.obtenirTous();

  if (utilisateursExistants.isEmpty) {
    final authController = AuthController();
    await authController.creerCompte('admin', 'admin123');
    debugPrint(
        'Compte de test créé → identifiant : admin | mot de passe : admin123');
  }
}

/// Point d'entrée (cf. arborescence `lib/main.dart` du cahier des
/// charges §3.2). Démarre systématiquement sur [LoginPage] :
/// l'accès à l'interface d'administration est protégé par
/// l'authentification, conformément au module "Authentification" du
/// cahier des charges.
class BibliothequeApp extends StatelessWidget {
  const BibliothequeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Bibliotech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF5E4FA2)),
        useMaterial3: true,
      ),
      home: const LoginPage(),
    );
  }
}
