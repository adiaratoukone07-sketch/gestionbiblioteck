import '../database/adherent_dao.dart';
import '../database/exemplaire_dao.dart';
import '../database/pret_dao.dart';
import '../models/exemplaire.dart';
import '../models/pret.dart';
import 'resultat_operation.dart';

/// Contrôleur pour le module "Gestion des emprunts" du cahier des
/// charges, cœur fonctionnel du système : enregistrement d'un emprunt,
/// enregistrement d'un retour, consultation des emprunts en cours,
/// consultation des retards, historique par adhérent et par ouvrage.
///
/// Porte les règles de gestion RG-02 (disponibilité), RG-03 (max 3
/// emprunts simultanés) et RG-04 (durée max 14 jours, appliquée par le
/// modèle `Pret.nouveau()`).
class PretController {
  final PretDao _pretDao = PretDao();
  final ExemplaireDao _exemplaireDao = ExemplaireDao();
  final AdherentDao _adherentDao = AdherentDao();

  /// RG-03 : nombre maximal d'emprunts simultanés par adhérent.
  static const int maxEmpruntsSimultanes = 3;

  /// Enregistre un emprunt (cf. cahier des charges - "Enregistrement
  /// d'un emprunt (sélection de l'adhérent et du livre, date de début
  /// et date de retour prévue)"). Choisit automatiquement le premier
  /// exemplaire disponible du livre sélectionné.
  Future<ResultatOperationAvecDonnee<Pret>> emprunter({
    required int idAdherent,
    required int idLivre,
  }) async {
    final adherent = await _adherentDao.obtenirParId(idAdherent);
    if (adherent == null) {
      return const ResultatOperationAvecDonnee.echec('Adhérent introuvable.');
    }

    // RG-03 : maximum 3 emprunts simultanés par adhérent.
    final empruntsEnCours =
        await _pretDao.obtenirEnCoursParAdherent(idAdherent);
    if (empruntsEnCours.length >= maxEmpruntsSimultanes) {
      return ResultatOperationAvecDonnee.echec(
          'RG-03 : cet adhérent a déjà $maxEmpruntsSimultanes emprunts en cours.');
    }

    // RG-02 : un emprunt n'est possible que si au moins un exemplaire
    // du livre est disponible.
    final exemplairesDisponibles =
        await _exemplaireDao.obtenirDisponiblesParLivre(idLivre);
    if (exemplairesDisponibles.isEmpty) {
      return const ResultatOperationAvecDonnee.echec(
          'RG-02 : aucun exemplaire disponible pour ce livre.');
    }
    final exemplaireChoisi = exemplairesDisponibles.first;

    // RG-04 : durée maximale de 14 jours, calculée automatiquement par
    // le modèle via Pret.nouveau().
    final nouveauPret = Pret.nouveau(
      idAdherent: idAdherent,
      idExemplaire: exemplaireChoisi.idExemplaire!,
    );

    final idEmprunt = await _pretDao.ajouter(nouveauPret);
    await _exemplaireDao.mettreAJourStatut(
      exemplaireChoisi.idExemplaire!,
      StatutExemplaire.emprunte,
    );

    return ResultatOperationAvecDonnee.succes(
      nouveauPret.copyWith(idEmprunt: idEmprunt),
    );
  }

  /// Enregistre le retour effectif d'un ouvrage (cf. cahier des charges
  /// - "Enregistrement du retour effectif d'un ouvrage") et remet
  /// l'exemplaire concerné à disposition.
  Future<ResultatOperation> enregistrerRetour(int idEmprunt) async {
    final pret = await _pretDao.obtenirParId(idEmprunt);
    if (pret == null) {
      return const ResultatOperation.echec('Emprunt introuvable.');
    }
    if (!pret.estEnCours) {
      return const ResultatOperation.echec(
          'Cet emprunt a déjà fait l\'objet d\'un retour.');
    }

    await _pretDao.enregistrerRetour(idEmprunt);
    await _exemplaireDao.mettreAJourStatut(
      pret.idExemplaire,
      StatutExemplaire.disponible,
    );

    return const ResultatOperation.succes();
  }

  /// Emprunts en cours (cf. cas d'utilisation "Consulter les emprunts
  /// en cours").
  Future<List<Pret>> obtenirEnCours() => _pretDao.obtenirEnCours();

  /// Calcul et affichage automatique des retards (cf. cahier des
  /// charges - module Gestion des emprunts + Tableau de bord).
  Future<List<Pret>> obtenirEnRetard() => _pretDao.obtenirEnRetard();

  /// Historique des emprunts par adhérent.
  Future<List<Pret>> obtenirHistoriqueParAdherent(int idAdherent) {
    return _pretDao.obtenirHistoriqueParAdherent(idAdherent);
  }

  /// Historique des emprunts par ouvrage (via l'exemplaire concerné).
  Future<List<Pret>> obtenirHistoriqueParExemplaire(int idExemplaire) {
    return _pretDao.obtenirHistoriqueParExemplaire(idExemplaire);
  }

  /// Met à jour le statut des exemplaires dont l'emprunt a dépassé la
  /// date de retour prévue (statut `enRetard`). À appeler par exemple à
  /// l'ouverture du tableau de bord ou via une tâche périodique.
  Future<void> actualiserStatutsRetard() async {
    final empruntsEnRetard = await _pretDao.obtenirEnRetard();
    for (final pret in empruntsEnRetard) {
      await _exemplaireDao.mettreAJourStatut(
        pret.idExemplaire,
        StatutExemplaire.enRetard,
      );
    }
  }
}
