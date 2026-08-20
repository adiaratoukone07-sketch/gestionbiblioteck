import '../database/utilisateur_dao.dart';
import '../models/utilisateur.dart';
import '../services/hash_service.dart';
import '../services/session_service.dart';
import 'resultat_operation.dart';

/// Contrôleur pour le module "Authentification" du cahier des charges :
/// - Page de connexion avec identifiant/mot de passe ;
/// - Protection des routes d'administration contre les accès non
///   authentifiés ;
/// - Gestion des sessions (connexion/déconnexion sécurisées) ;
/// - Verrouillage automatique par inactivité avec PIN (choix retenu :
///   le PIN de déverrouillage réutilise le mot de passe du compte, il
///   n'y a pas de champ PIN distinct dans UTILISATEUR).
class AuthController {
  final UtilisateurDao _utilisateurDao = UtilisateurDao();
  final SessionService _session = SessionService.instance;

  bool get estConnecte => _session.estConnecte;
  bool get estVerrouille => _session.estVerrouille;
  Utilisateur? get utilisateurCourant => _session.utilisateurCourant;

  /// Tentative de connexion. Vérifie l'identifiant puis le mot de passe
  /// via [HashService], et démarre la session en cas de succès.
  Future<ResultatOperationAvecDonnee<Utilisateur>> connecter(
    String identifiant,
    String motDePasse,
  ) async {
    final utilisateur =
        await _utilisateurDao.obtenirParIdentifiant(identifiant);
    if (utilisateur == null) {
      return const ResultatOperationAvecDonnee.echec(
          'Identifiant ou mot de passe incorrect.');
    }

    final motDePasseValide =
        HashService.verifier(motDePasse, utilisateur.motDePasseHash);
    if (!motDePasseValide) {
      return const ResultatOperationAvecDonnee.echec(
          'Identifiant ou mot de passe incorrect.');
    }

    _session.demarrerSession(utilisateur);
    return ResultatOperationAvecDonnee.succes(utilisateur);
  }

  /// Déconnexion explicite ("Terminer la session" dans le diagramme de
  /// cas d'utilisation) : ferme complètement la session.
  void deconnecter() {
    _session.terminerSession();
  }

  /// À appeler à intervalle régulier par la vue principale (ex. via un
  /// Timer) pour déclencher le verrouillage après le délai d'inactivité
  /// défini dans [SessionService.seuilInactivite].
  bool verifierEtVerrouillerSiInactif() {
    if (_session.doitEtreVerrouille()) {
      _session.verrouiller();
      return true;
    }
    return false;
  }

  /// Verrouillage manuel (ex. bouton "Verrouiller" dans l'interface).
  void verrouillerManuellement() {
    _session.verrouiller();
  }

  /// À appeler sur chaque interaction utilisateur pour repousser le
  /// déclenchement du verrouillage par inactivité.
  void signalerActivite() {
    _session.enregistrerActivite();
  }

  /// Déverrouille la session après re-saisie du mot de passe (PIN).
  /// La session reste celle de l'utilisateur déjà connecté ; aucune
  /// reconnexion complète n'est demandée (cf. note du diagramme de cas
  /// d'utilisation : "Aucune reconnexion n'est demandée pour les
  /// opérations critiques").
  Future<ResultatOperationAvecDonnee<Utilisateur>> deverrouiller(
    String motDePasse,
  ) async {
    final utilisateur = _session.utilisateurCourant;
    if (utilisateur == null) {
      return const ResultatOperationAvecDonnee.echec(
          'Aucune session active à déverrouiller.');
    }

    final motDePasseValide =
        HashService.verifier(motDePasse, utilisateur.motDePasseHash);
    if (!motDePasseValide) {
      return const ResultatOperationAvecDonnee.echec(
          'Mot de passe incorrect.');
    }

    _session.deverrouillerSansVerification();
    return ResultatOperationAvecDonnee.succes(utilisateur);
  }

  /// Création d'un compte bibliothécaire. Ne correspond pas à une
  /// fonctionnalité exposée dans l'interface (le cahier des charges ne
  /// prévoit pas d'auto-inscription), mais est utile pour un script
  /// d'initialisation de la base ou une future gestion multi-comptes.
  Future<int> creerCompte(
    String identifiant,
    String motDePasseClair, {
    String role = 'bibliothecaire',
  }) async {
    final hash = HashService.hacher(motDePasseClair);
    final utilisateur = Utilisateur(
      identifiant: identifiant,
      motDePasseHash: hash,
      role: role,
    );
    return await _utilisateurDao.ajouter(utilisateur);
  }
}
