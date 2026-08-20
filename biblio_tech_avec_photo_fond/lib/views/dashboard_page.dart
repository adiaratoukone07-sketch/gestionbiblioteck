import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/statistique_controller.dart';
import '../widgets/app_shell.dart';

/// Page "Tableau de bord" (cf. cahier des charges - module "Tableau de
/// bord") : vue synthétique de l'activité de la bibliothèque (nombre
/// d'adhérents, de livres, d'emprunts en cours, retards, livres les
/// plus empruntés).
///
/// Toutes les données proviennent de [StatistiqueController], qui
/// agrège les compteurs et la requête SQL des livres les plus
/// empruntés — cette page ne fait aucun calcul elle-même.
class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final StatistiqueController _statistiqueController = StatistiqueController();

  StatistiquesTableauDeBord? _statistiques;
  bool _enChargement = true;

  @override
  void initState() {
    super.initState();
    _chargerStatistiques();
  }

  Future<void> _chargerStatistiques() async {
    setState(() => _enChargement = true);
    final statistiques = await _statistiqueController.obtenirStatistiques();
    if (!mounted) return;
    setState(() {
      _statistiques = statistiques;
      _enChargement = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      moduleActif: ModuleSidebar.tableauDeBord,
      titre: 'Tableau de bord',
      enfant: _enChargement
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF5E4FA2)))
          : RefreshIndicator(
              onRefresh: _chargerStatistiques,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Vue d\'ensemble',
                            style: GoogleFonts.quicksand(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFF3B2470))),
                        IconButton(
                          tooltip: 'Actualiser',
                          icon: const Icon(Icons.refresh,
                              color: Color(0xFF5E4FA2)),
                          onPressed: _chargerStatistiques,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCartesIndicateurs(),
                    const SizedBox(height: 28),
                    Text('Livres les plus empruntés',
                        style: GoogleFonts.quicksand(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF3B2470))),
                    const SizedBox(height: 12),
                    _buildListeLivresPopulaires(),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildCartesIndicateurs() {
    final statistiques = _statistiques;
    if (statistiques == null) return const SizedBox.shrink();

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: [
        _CarteIndicateur(
          icone: Icons.people_alt_outlined,
          valeur: statistiques.nombreAdherents.toString(),
          label: 'Adhérents inscrits',
          couleur: const Color(0xFF5E4FA2),
        ),
        _CarteIndicateur(
          icone: Icons.menu_book_outlined,
          valeur: statistiques.nombreLivres.toString(),
          label: 'Livres au catalogue',
          couleur: const Color(0xFF4338CA),
        ),
        _CarteIndicateur(
          icone: Icons.fact_check_outlined,
          valeur: statistiques.nombreEmpruntsEnCours.toString(),
          label: 'Emprunts en cours',
          couleur: const Color(0xFF2E7D32),
        ),
        _CarteIndicateur(
          icone: Icons.warning_amber_rounded,
          valeur: statistiques.nombreEmpruntsEnRetard.toString(),
          label: 'Emprunts en retard',
          couleur: const Color(0xFFB91C1C),
        ),
      ],
    );
  }

  Widget _buildListeLivresPopulaires() {
    final livres = _statistiques?.livresLesPlusEmpruntes ?? const [];

    if (livres.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFFFAF8FD),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2DBF1)),
        ),
        child: Center(
          child: Text('Aucun emprunt enregistré pour le moment.',
              style: GoogleFonts.nunito(color: const Color(0xFF9C93B8))),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2DBF1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: livres.length,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFE9E3F6)),
        itemBuilder: (context, index) {
          final ligne = livres[index];
          final titre = ligne['titre'] as String? ?? 'Titre inconnu';
          final nombreEmprunts = ligne['nombre_emprunts'] as int? ?? 0;

          return ListTile(
            leading: CircleAvatar(
              backgroundColor: const Color(0xFFEDE9F7),
              foregroundColor: const Color(0xFF5E4FA2),
              child: Text('${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            title: Text(titre,
                style: GoogleFonts.quicksand(
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF3B2470))),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFFEDE9F7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$nombreEmprunts emprunt${nombreEmprunts > 1 ? 's' : ''}',
                style: GoogleFonts.quicksand(
                    color: const Color(0xFF7C6BC4),
                    fontWeight: FontWeight.w700,
                    fontSize: 12),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _CarteIndicateur extends StatelessWidget {
  final IconData icone;
  final String valeur;
  final String label;
  final Color couleur;

  const _CarteIndicateur({
    required this.icone,
    required this.valeur,
    required this.label,
    required this.couleur,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 220,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2DBF1)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: couleur.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icone, color: couleur, size: 22),
          ),
          const SizedBox(height: 14),
          Text(valeur,
              style: GoogleFonts.quicksand(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF3B2470))),
          const SizedBox(height: 2),
          Text(label,
              style:
                  GoogleFonts.nunito(color: const Color(0xFF9C93B8), fontSize: 13)),
        ],
      ),
    );
  }
}
