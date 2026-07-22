import '../database/exemplaire_dao.dart';
import '../database/livre_dao.dart';
import '../models/exemplaire.dart';
import 'resultat_operation.dart';

/// Contrôleur dédié à l'entité EXEMPLAIRE.
///
/// Ce contrôleur n'apparaît pas explicitement dans l'arborescence
/// initiale du cahier des charges, mais découle logiquement de la
/// promotion d'EXEMPLAIRE en entité à part entière dans la révision du
/// MCD/MLD. Il complète `LivreController` (qui gère la création groupée
/// des exemplaires à l'ajout d'un livre) pour les opérations fines sur
/// des exemplaires individuels : ajout a posteriori, retrait d'un
/// exemplaire abîmé ou perdu, changement de statut.
class ExemplaireController {
  final ExemplaireDao _exemplaireDao = ExemplaireDao();
  final LivreDao _livreDao = LivreDao();

  /// Ajoute un exemplaire supplémentaire à un livre déjà existant et
  /// met à jour `Livre.nombreExemplaires` en conséquence.
  Future<ResultatOperationAvecDonnee<int>> ajouterExemplaire(
    Exemplaire exemplaire,
  ) async {
    final livre = await _livreDao.obtenirParId(exemplaire.idLivre);
    if (livre == null) {
      return const ResultatOperationAvecDonnee.echec(
          'Le livre associé à cet exemplaire est introuvable.');
    }

    final idExemplaire = await _exemplaireDao.ajouter(exemplaire);
    await _livreDao.modifier(
      livre.copyWith(nombreExemplaires: livre.nombreExemplaires + 1),
    );

    return ResultatOperationAvecDonnee.succes(idExemplaire);
  }

  /// Retrait définitif d'un exemplaire (perte, mise au rebut...).
  /// Applique RG-06 au niveau de l'exemplaire : impossible de retirer
  /// un exemplaire actuellement emprunté.
  Future<ResultatOperation> supprimerExemplaire(int idExemplaire) async {
    final exemplaire = await _exemplaireDao.obtenirParId(idExemplaire);
    if (exemplaire == null) {
      return const ResultatOperation.echec('Exemplaire introuvable.');
    }
    if (!exemplaire.estDisponible) {
      return const ResultatOperation.echec(
          'RG-06 : impossible de retirer un exemplaire actuellement emprunté.');
    }

    await _exemplaireDao.supprimer(idExemplaire);

    final livre = await _livreDao.obtenirParId(exemplaire.idLivre);
    if (livre != null && livre.nombreExemplaires > 0) {
      await _livreDao.modifier(
        livre.copyWith(nombreExemplaires: livre.nombreExemplaires - 1),
      );
    }

    return const ResultatOperation.succes();
  }

  /// Marque un exemplaire comme perdu, sans le supprimer de la base
  /// (conserve la traçabilité, contrairement à [supprimerExemplaire]).
  Future<ResultatOperation> declarerPerdu(int idExemplaire) async {
    final exemplaire = await _exemplaireDao.obtenirParId(idExemplaire);
    if (exemplaire == null) {
      return const ResultatOperation.echec('Exemplaire introuvable.');
    }
    if (!exemplaire.estDisponible) {
      return const ResultatOperation.echec(
          'Impossible de déclarer perdu un exemplaire actuellement emprunté ; enregistrez d\'abord son retour.');
    }

    await _exemplaireDao.mettreAJourStatut(
      idExemplaire,
      StatutExemplaire.perdu,
    );
    return const ResultatOperation.succes();
  }

  Future<List<Exemplaire>> obtenirParLivre(int idLivre) {
    return _exemplaireDao.obtenirParLivre(idLivre);
  }

  /// Utilisé par `PretController` pour vérifier RG-02 avant d'enregistrer
  /// un emprunt.
  Future<List<Exemplaire>> obtenirDisponibles(int idLivre) {
    return _exemplaireDao.obtenirDisponiblesParLivre(idLivre);
  }
}
