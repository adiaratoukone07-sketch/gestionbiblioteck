import '../database/adherent_dao.dart';
import '../database/pret_dao.dart';
import '../models/adherent.dart';
import '../models/pret.dart';
import 'resultat_operation.dart';

/// Contrôleur pour le module "Gestion des adhérents" du cahier des
/// charges : inscription, modification, suppression, recherche.
///
/// Porte les règles de gestion RG-01 (unicité du numéro de carte) et
/// RG-05 (interdiction de suppression si emprunts en cours).
class AdherentController {
  final AdherentDao _adherentDao = AdherentDao();
  final PretDao _pretDao = PretDao();

  /// Inscription d'un nouvel adhérent (cf. cahier des charges -
  /// "Inscription d'un nouvel adhérent avec saisie des informations
  /// obligatoires").
  Future<ResultatOperationAvecDonnee<int>> inscrire(Adherent adherent) async {
    // RG-01 : unicité de l'adhérent par numéro de carte. La contrainte
    // UNIQUE en base protège l'intégrité, mais on vérifie ici en amont
    // pour renvoyer un message clair à l'IHM plutôt qu'une erreur SQL brute.
    final existant = await _adherentDao.obtenirParNumCarte(adherent.numCarte);
    if (existant != null) {
      return const ResultatOperationAvecDonnee.echec(
          'RG-01 : ce numéro de carte est déjà utilisé par un autre adhérent.');
    }

    final id = await _adherentDao.ajouter(adherent);
    return ResultatOperationAvecDonnee.succes(id);
  }

  /// Modification des informations d'un adhérent existant.
  Future<ResultatOperation> modifier(Adherent adherent) async {
    final existant = await _adherentDao.obtenirParNumCarte(adherent.numCarte);
    if (existant != null && existant.idAdherent != adherent.idAdherent) {
      return const ResultatOperation.echec(
          'RG-01 : ce numéro de carte est déjà utilisé par un autre adhérent.');
    }

    await _adherentDao.modifier(adherent);
    return const ResultatOperation.succes();
  }

  /// Suppression d'un adhérent (cf. cahier des charges - "sous réserve
  /// qu'il n'ait pas d'emprunt en cours"), applique RG-05.
  Future<ResultatOperation> supprimer(int idAdherent) async {
    final empruntsEnCours =
        await _pretDao.obtenirEnCoursParAdherent(idAdherent);
    if (empruntsEnCours.isNotEmpty) {
      return ResultatOperation.echec(
          'RG-05 : impossible de supprimer, cet adhérent a ${empruntsEnCours.length} emprunt(s) en cours.');
    }

    await _adherentDao.supprimer(idAdherent);
    return const ResultatOperation.succes();
  }

  /// Recherche et affichage avec filtrage par nom ou classe.
  Future<List<Adherent>> rechercher({String? nom, String? classe}) {
    return _adherentDao.rechercher(nom: nom, classe: classe);
  }

  Future<List<Adherent>> obtenirTous() => _adherentDao.obtenirTous();

  Future<Adherent?> obtenirParId(int idAdherent) {
    return _adherentDao.obtenirParId(idAdherent);
  }

  /// "Consulter les emprunts d'un adhérent" (cf. diagramme de cas
  /// d'utilisation, module Gestion des adhérents).
  Future<List<Pret>> obtenirHistoriqueEmprunts(int idAdherent) {
    return _pretDao.obtenirHistoriqueParAdherent(idAdherent);
  }
}
