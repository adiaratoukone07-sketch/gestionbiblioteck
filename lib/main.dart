import 'package:flutter/material.dart';

import 'views/login_page.dart';

void main() {
  runApp(const BibliothequeApp());
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
