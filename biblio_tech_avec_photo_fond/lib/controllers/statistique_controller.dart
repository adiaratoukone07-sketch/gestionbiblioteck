import '../database/adherent_dao.dart';
import '../database/livre_dao.dart';
import '../database/pret_dao.dart';

/// Regroupe les indicateurs affichés sur le tableau de bord (cf. cahier
/// des charges - module "Tableau de bord").
class StatistiquesTableauDeBord {
  final int nombreAdherents;
  final int nombreLivres;
  final int nombreEmpruntsEnCours;
  final int nombreEmpruntsEnRetard;

  /// Classement des livres les plus empruntés, sous forme de lignes
  /// brutes `{id_livre, titre, nombre_emprunts}` (issues d'une requête
  /// agrégée SQL, cf. `PretDao.obtenirLivresLesPlusEmpruntes`).
  final List<Map<String, Object?>> livresLesPlusEmpruntes;

  StatistiquesTableauDeBord({
    required this.nombreAdherents,
    required this.nombreLivres,
    required this.nombreEmpruntsEnCours,
    required this.nombreEmpruntsEnRetard,
    required this.livresLesPlusEmpruntes,
  });
}

/// Contrôleur pour le module "Tableau de bord" du cahier des charges :
/// vue synthétique de l'activité de la bibliothèque (nombre
/// d'adhérents, de livres, d'emprunts en cours, retards, indicateurs
/// visuels, livres les plus empruntés).
class StatistiqueController {
  final AdherentDao _adherentDao = AdherentDao();
  final LivreDao _livreDao = LivreDao();
  final PretDao _pretDao = PretDao();

  /// Regroupe en un seul appel toutes les données nécessaires à
  /// l'affichage du tableau de bord.
  Future<StatistiquesTableauDeBord> obtenirStatistiques() async {
    final nombreAdherents = await _adherentDao.compterTous();
    final nombreLivres = await _livreDao.compterTous();
    final nombreEmpruntsEnCours = await _pretDao.compterEnCours();
    final empruntsEnRetard = await _pretDao.obtenirEnRetard();
    final livresLesPlusEmpruntes =
        await _pretDao.obtenirLivresLesPlusEmpruntes();

    return StatistiquesTableauDeBord(
      nombreAdherents: nombreAdherents,
      nombreLivres: nombreLivres,
      nombreEmpruntsEnCours: nombreEmpruntsEnCours,
      nombreEmpruntsEnRetard: empruntsEnRetard.length,
      livresLesPlusEmpruntes: livresLesPlusEmpruntes,
    );
  }
}
