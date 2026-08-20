import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../views/accueil_page.dart';
import '../views/adherents_page.dart';
import '../views/dashboard_page.dart';
import '../views/livres_page.dart';
import '../views/prets_page.dart';

/// Modules accessibles depuis la sidebar de navigation, partagés par
/// toutes les pages internes (Adhérents, Livres, Emprunts, Tableau de
/// bord) pour qu'elles puissent naviguer les unes vers les autres de
/// façon cohérente.
///
/// Remarque : `adherents_page.dart` conserve pour l'instant sa propre
/// énumération privée `_ModuleSidebar` (héritée de sa construction
/// initiale) plutôt que celle-ci, pour limiter les changements sur une
/// page déjà stabilisée — les deux énumérations restent alignées.
enum ModuleBibliotheque { home, adherents, livres, emprunts, tableauDeBord }

/// Sidebar de navigation commune aux nouvelles pages internes de
/// l'application (mêmes couleurs et disposition que la sidebar
/// d'origine de `adherents_page.dart`, cf. `_buildSidebar()`).
///
/// [moduleActif] détermine quel onglet est mis en évidence ;
/// [onNaviguer] est appelé avec le module choisi — voir
/// [naviguerDepuisSidebar] pour l'implémentation standard (navigation
/// par `pushReplacement` vers la page correspondante).
class SidebarNavigation extends StatelessWidget {
  final ModuleBibliotheque moduleActif;
  final ValueChanged<ModuleBibliotheque> onNaviguer;

  const SidebarNavigation({
    super.key,
    required this.moduleActif,
    required this.onNaviguer,
  });

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
            child: _tacheDecorative(200, Colors.white.withOpacity(0.05)),
          ),
          Positioned(
            left: 10,
            bottom: -50,
            child: _tacheDecorative(140, Colors.deepPurple.withOpacity(0.3)),
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
              _buildNavItem(
                  ModuleBibliotheque.home, Icons.home_outlined, 'Home'),
              _buildNavItem(ModuleBibliotheque.adherents,
                  Icons.people_alt_outlined, 'Adherents'),
              _buildNavItem(
                  ModuleBibliotheque.livres, Icons.menu_book_rounded, 'Livres'),
              _buildNavItem(ModuleBibliotheque.emprunts,
                  Icons.fact_check_outlined, 'Emprunts'),
              _buildNavItem(ModuleBibliotheque.tableauDeBord,
                  Icons.bar_chart_rounded, 'Tableau de bord'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tacheDecorative(double taille, Color couleur) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(shape: BoxShape.circle, color: couleur),
    );
  }

  Widget _buildNavItem(ModuleBibliotheque module, IconData icon, String label) {
    final estActif = module == moduleActif;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          hoverColor: const Color.fromARGB(147, 233, 231, 238),
          onTap: () => onNaviguer(module),
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

/// Navigue vers la page correspondant à [module] par un
/// `pushReplacement`, pour que les changements d'onglet dans la
/// sidebar ne s'empilent pas dans l'historique de navigation (même
/// principe que le bouton "Home" de `adherents_page.dart`). Ne fait
/// rien si [module] est déjà celui de la page actuelle.
void naviguerDepuisSidebar(
  BuildContext context,
  ModuleBibliotheque module,
  ModuleBibliotheque moduleActuel,
) {
  if (module == moduleActuel) return;

  final Widget page = switch (module) {
    ModuleBibliotheque.home => const AccueilPage(),
    ModuleBibliotheque.adherents => const AdherentsPage(),
    ModuleBibliotheque.livres => const LivresPage(),
    ModuleBibliotheque.emprunts => const PretsPage(),
    ModuleBibliotheque.tableauDeBord => const DashboardPage(),
  };

  Navigator.of(context).pushReplacement(
    MaterialPageRoute(builder: (_) => page),
  );
}
