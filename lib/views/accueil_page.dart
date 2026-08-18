import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/auth_controller.dart';
import '../widgets/custom_title_bar.dart';
import 'adherents_page.dart';
import 'login_page.dart';
import 'livres_page.dart';
import 'dashboard_page.dart';
import 'prets_page.dart';

/// Position du bloc logo + "Bibliotech" sur cette page. Change cette
/// constante pour le repositionner facilement (ex. `Alignment.centerLeft`
/// pour le coller à gauche, `Alignment(-0.6, 0)` pour un décalage
/// personnalisé).
const Alignment positionTitreAccueil = Alignment.center;

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
      body: Column(
        children: [
          const BarreTitrePersonnalisee(
            couleurFond: Colors.white,
            couleurTexte: Color(0xFF3B2470),
            couleurIcones: Color(0xFF7A6FA0),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/fond_bibliotech.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: SafeArea(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.topRight,
                        child: IconButton(
                          tooltip: 'Se déconnecter',
                          icon: const Icon(Icons.logout,
                              color: Color(0xFF4C3E87)),
                          onPressed: () {
                            authController.deconnecter();
                            Navigator.of(context).pushAndRemoveUntil(
                              MaterialPageRoute(
                                  builder: (_) => const LoginPage()),
                              (route) => false,
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Align(
                        alignment: positionTitreAccueil,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 48,
                              height: 48,
                              decoration: const BoxDecoration(
                                color: Color(0xFFC7BADE),
                                shape: BoxShape.circle,
                              ),
                              child: Image.asset(
                                'assets/icons/mon_logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                            const SizedBox(width: 12),
                            ShaderMask(
                              shaderCallback: (Rect bounds) {
                                return const LinearGradient(
                                  begin: Alignment.centerLeft,
                                  end: Alignment.centerRight,
                                  colors: [
                                    Color.fromARGB(255, 59, 36, 112),
                                    Color.fromARGB(255, 139, 118, 196)
                                  ],
                                ).createShader(bounds);
                              },
                              blendMode: BlendMode.srcIn,
                              child: Text(
                                'Bibliotech',
                                style: GoogleFonts.inter(
                                  fontSize: 48,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
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
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const LivresPage()),
                            ),
                          ),
                          _CarteModule(
                            icone: Icons.fact_check_outlined,
                            label: 'Emprunts',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const PretsPage()),
                            ),
                          ),
                          _CarteModule(
                            icone: Icons.bar_chart_rounded,
                            label: 'Tableau de bord',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                  builder: (_) => const DashboardPage()),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(flex: 2),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Carte cliquable représentant un module (cf. maquette Accueil.png).
class _CarteModule extends StatefulWidget {
  final IconData icone;
  final String label;
  final VoidCallback onTap;

  const _CarteModule({
    required this.icone,
    required this.label,
    required this.onTap,
  });

  @override
  State<_CarteModule> createState() => _CarteModuleState();
}

class _CarteModuleState extends State<_CarteModule> {
  bool _survole = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _survole = true),
      onExit: (_) => setState(() => _survole = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
          width: 180,
          height: 180,
          padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.centerRight,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 102, 87, 161),
                Color.fromARGB(255, 58, 45, 101)
              ],
            ),
            borderRadius: BorderRadius.circular(32),
            border: Border.all(
              color: _survole
                  ? const Color.fromARGB(255, 70, 41, 212)
                  : Colors.white.withValues(alpha: 0.08),
              width: _survole ? 1.5 : 1,
            ),
            boxShadow: _survole
                ? [
                    BoxShadow(
                      color: const Color(0xFF8B7BD8).withValues(alpha: 0.55),
                      blurRadius: 20,
                      spreadRadius: 1,
                    ),
                  ]
                : [],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                widget.icone,
                size: 40,
                color: const Color.fromARGB(255, 139, 118, 196),
              ),
              const SizedBox(height: 16),
              Text(
                widget.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
