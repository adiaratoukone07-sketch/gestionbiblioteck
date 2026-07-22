import '../database/exemplaire_dao.dart';
import '../database/livre_dao.dart';
import '../models/exemplaire.dart';
import '../models/livre.dart';
import 'resultat_operation.dart';

/// Contrôleur pour le module "Gestion du catalogue des livres" du
/// cahier des charges : ajout, modification, suppression, recherche
/// multicritère, affichage de la disponibilité des exemplaires.
///
/// Porte la règle de gestion RG-06 (interdiction de suppression si des
/// exemplaires sont en cours d'emprunt).
class LivreController {
  final LivreDao _livreDao = LivreDao();
  final ExemplaireDao _exemplaireDao = ExemplaireDao();

  /// Ajoute un livre au catalogue et génère automatiquement ses
  /// exemplaires physiques individualisés (cf. cahier des charges -
  /// "Ajout d'un nouvel ouvrage (titre, auteur, ISBN, genre, nombre
  /// d'exemplaires)" + révision MCD/MLD introduisant l'entité EXEMPLAIRE).
  ///
  /// [idUtilisateur] est l'utilisateur gestionnaire courant (RG-07),
  /// à fournir par le contrôleur appelant (session en cours).
  Future<ResultatOperationAvecDonnee<int>> ajouter(
    Livre livre,
    int idUtilisateur,
  ) async {
    if (livre.nombreExemplaires < 0) {
      return const ResultatOperationAvecDonnee.echec(
          'Le nombre d\'exemplaires ne peut pas être négatif.');
    }

    final idLivre = await _livreDao.ajouter(livre);

    for (var i = 1; i <= livre.nombreExemplaires; i++) {
      final codeExemplaire = '${livre.isbn}-${i.toString().padLeft(2, '0')}';
      await _exemplaireDao.ajouter(
        Exemplaire(
          codeExemplaire: codeExemplaire,
          idLivre: idLivre,
          idUtilisateur: idUtilisateur,
        ),
      );
    }

    return ResultatOperationAvecDonnee.succes(idLivre);
  }

  /// Modification des informations d'un ouvrage. Ne modifie pas le
  /// nombre d'exemplaires existants : utiliser `ExemplaireController`
  /// pour ajouter/retirer des exemplaires individuellement.
  Future<ResultatOperation> modifier(Livre livre) async {
    await _livreDao.modifier(livre);
    return const ResultatOperation.succes();
  }

  /// Suppression d'un ouvrage du catalogue, applique RG-06 : aucun
  /// exemplaire du livre ne doit être actuellement emprunté.
  Future<ResultatOperation> supprimer(int idLivre) async {
    final exemplaires = await _exemplaireDao.obtenirParLivre(idLivre);
    final indisponibles =
        exemplaires.where((exemplaire) => !exemplaire.estDisponible).toList();

    if (indisponibles.isNotEmpty) {
      return ResultatOperation.echec(
          'RG-06 : impossible de supprimer, ${indisponibles.length} exemplaire(s) sont actuellement empruntés.');
    }

    for (final exemplaire in exemplaires) {
      await _exemplaireDao.supprimer(exemplaire.idExemplaire!);
    }
    await _livreDao.supprimer(idLivre);
    return const ResultatOperation.succes();
  }

  /// Recherche multicritère (titre, auteur, ISBN ou genre).
  Future<List<Livre>> rechercher(String motCle) {
    return _livreDao.rechercher(motCle);
  }

  Future<List<Livre>> obtenirTous() => _livreDao.obtenirTous();

  Future<Livre?> obtenirParId(int idLivre) => _livreDao.obtenirParId(idLivre);

  /// Affichage du statut de disponibilité de chaque exemplaire (cf.
  /// cahier des charges, module Gestion du catalogue).
  Future<List<Exemplaire>> obtenirExemplaires(int idLivre) {
    return _exemplaireDao.obtenirParLivre(idLivre);
  }
}
