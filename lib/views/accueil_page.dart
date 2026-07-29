import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/auth_controller.dart';
import 'adherents_page.dart';
import 'login_page.dart';

/// Page d'accueil, affichée après une connexion réussie.
///
/// Sert de point d'entrée vers les 4 modules principaux du cahier des
/// charges : Adhérents, Livres, Emprunts, Tableau de bord (cf.
/// diagramme de cas d'utilisation). Seul le module Adhérents est
/// branché pour l'instant (`AdherentsPage` déjà construite) ; les
/// autres afficheront un message temporaire tant que leurs pages ne
/// sont pas prêtes.
class AccueilPage extends StatelessWidget {
  const AccueilPage({super.key});

  @override
  Widget build(BuildContext context) {
    final authController = AuthController();

    return Scaffold(
      backgroundColor: const Color(0xFFF5F2FB),
      body: Stack(
        children: [
          // Formes décoratives en fond (cf. maquette).
          Positioned(
            left: -140,
            bottom: -170,
            child: _tache(360, const Color(0xFFDCD3F0)),
          ),
          Positioned(
            left: -40,
            bottom: -230,
            child: _tache(300, const Color(0xFFC9BAE8)),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              child: Column(
                children: [
                  Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      tooltip: 'Se déconnecter',
                      icon: const Icon(Icons.logout, color: Color(0xFF4C3E87)),
                      onPressed: () {
                        // Ferme complètement la session (cf. cas
                        // d'utilisation "Se déconnecter").
                        authController.deconnecter();
                        Navigator.of(context).pushAndRemoveUntil(
                          MaterialPageRoute(builder: (_) => const LoginPage()),
                          (route) => false,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFC7BADE),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.menu_book,
                            color: Color(0xFF3B2470)),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Bibliotech',
                        style: GoogleFonts.quicksand(
                          fontSize: 36,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF3B2470),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 24,
                    runSpacing: 24,
                    children: [
                      _CarteModule(
                        icone: Icons.people_alt_outlined,
                        label: 'Adhérents',
                        onTap: () => Navigator.of(context).push(
                          MaterialPageRoute(
                              builder: (_) => const AdherentsPage()),
                        ),
                      ),
                      _CarteModule(
                        icone: Icons.menu_book_outlined,
                        label: 'Livres',
                        onTap: () => _bientotDisponible(context),
                      ),
                      _CarteModule(
                        icone: Icons.fact_check_outlined,
                        label: 'Emprunts',
                        onTap: () => _bientotDisponible(context),
                      ),
                      _CarteModule(
                        icone: Icons.bar_chart_rounded,
                        label: 'Tableau de bord',
                        onTap: () => _bientotDisponible(context),
                      ),
                    ],
                  ),
                  const Spacer(flex: 2),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _bientotDisponible(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Cette page sera bientôt disponible.',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)),
        backgroundColor: const Color(0xFF3B2470),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  Widget _tache(double taille, Color couleur) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(shape: BoxShape.circle, color: couleur),
    );
  }
}

/// Carte cliquable représentant un module (cf. maquette Accueil.png).
class _CarteModule extends StatelessWidget {
  final IconData icone;
  final String label;
  final VoidCallback onTap;

  const _CarteModule({
    required this.icone,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        width: 160,
        height: 140,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4C3E87), Color(0xFF2E2154)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icone, color: Colors.white, size: 28),
            const Spacer(),
            Text(
              label,
              style: GoogleFonts.quicksand(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
