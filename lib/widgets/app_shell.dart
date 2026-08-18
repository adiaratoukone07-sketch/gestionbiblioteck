import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../views/accueil_page.dart';
import '../views/adherents_page.dart';
import '../views/dashboard_page.dart';
import '../views/livres_page.dart';
import '../views/prets_page.dart';
import 'custom_title_bar.dart';

/// Modules accessibles depuis la sidebar (version publique, réutilisée
/// par `livres_page.dart`, `prets_page.dart` et `dashboard_page.dart`).
///
/// `adherents_page.dart` définit son propre `_ModuleSidebar` privé (page
/// déjà construite et personnalisée avant que ce widget partagé
/// n'existe) — pour ne pas risquer de casser ses personnalisations, on
/// ne l'a pas migré vers cet enum. Les deux valeurs `home`/`adherents`/
/// `livres`/`emprunts`/`tableauDeBord` sont identiques, seul le nom du
/// type diffère.
enum ModuleSidebar { home, adherents, livres, emprunts, tableauDeBord }

/// Coquille commune (sidebar + barre de titre personnalisée) pour les
/// pages `livres_page.dart`, `prets_page.dart` et `dashboard_page.dart`,
/// reproduisant fidèlement le style déjà mis au point sur
/// `adherents_page.dart` (police Inter, logo `assets/icons/mon_logo.png`,
/// couleurs de survol) pour que l'application reste cohérente sans
/// dupliquer ~150 lignes de sidebar dans chaque nouveau fichier.
///
/// Navigation : cliquer sur un module de la sidebar remplace la page
/// courante (`pushReplacement`) par la page correspondante — chaque
/// module est une page indépendante, pas un onglet interne.
class AppShell extends StatelessWidget {
  final ModuleSidebar moduleActif;
  final String titre;
  final Widget enfant;

  const AppShell({
    super.key,
    required this.moduleActif,
    required this.titre,
    required this.enfant,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _Sidebar(moduleActif: moduleActif),
          Expanded(
            child: Column(
              children: [
                BarreTitrePersonnalisee(titre: titre),
                Expanded(child: enfant),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Sidebar extends StatelessWidget {
  final ModuleSidebar moduleActif;

  const _Sidebar({required this.moduleActif});

  void _naviguer(BuildContext context, ModuleSidebar module) {
    if (module == moduleActif) return; // déjà sur cette page

    late final Widget page;
    switch (module) {
      case ModuleSidebar.home:
        page = const AccueilPage();
        break;
      case ModuleSidebar.adherents:
        page = const AdherentsPage();
        break;
      case ModuleSidebar.livres:
        page = const LivresPage();
        break;
      case ModuleSidebar.emprunts:
        page = const PretsPage();
        break;
      case ModuleSidebar.tableauDeBord:
        page = const DashboardPage();
        break;
    }
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4C3E87), Color(0xFF241A3E)],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            left: -70,
            bottom: -90,
            child: _tache(200, Colors.white.withValues(alpha: 0.05)),
          ),
          Positioned(
            left: 10,
            bottom: -50,
            child: _tache(140, Colors.deepPurple.withValues(alpha: 0.3)),
          ),
          Column(
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset('assets/icons/mon_logo.png',
                      fit: BoxFit.cover, width: 26, height: 26),
                  const SizedBox(width: 10),
                  Text('Bibliotech',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(
                  color: Color.fromARGB(155, 253, 252, 252), height: 1),
              const SizedBox(height: 12),
              _buildNavItem(context, ModuleSidebar.home, Icons.home_outlined, 'Home'),
              _buildNavItem(context, ModuleSidebar.adherents,
                  Icons.people_alt_outlined, 'Adherents'),
              _buildNavItem(
                  context, ModuleSidebar.livres, Icons.menu_book_rounded, 'Livres'),
              _buildNavItem(context, ModuleSidebar.emprunts,
                  Icons.fact_check_outlined, 'Emprunts'),
              _buildNavItem(context, ModuleSidebar.tableauDeBord,
                  Icons.bar_chart_rounded, 'Tableau de bord'),
            ],
          ),
        ],
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

  Widget _buildNavItem(
      BuildContext context, ModuleSidebar module, IconData icon, String label) {
    final estActif = module == moduleActif;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          hoverColor: const Color.fromARGB(147, 233, 231, 238),
          onTap: () => _naviguer(context, module),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: estActif ? const Color(0xFFEDE9F7) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: estActif ? const Color(0xFF3B2470) : Colors.white70,
                    size: 22),
                const SizedBox(width: 12),
                Text(label,
                    style: GoogleFonts.inter(
                        color:
                            estActif ? const Color(0xFF3B2470) : Colors.white70,
                        fontWeight:
                            estActif ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
