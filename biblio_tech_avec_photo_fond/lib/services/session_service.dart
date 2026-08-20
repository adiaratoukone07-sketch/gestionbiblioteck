import '../models/utilisateur.dart';

/// Service transverse de gestion de la session utilisateur (singleton).
///
/// Fichier `services/session_service.dart` selon l'arborescence MVC du
/// cahier des charges §3.2 ("Gestion utilisateur connecté").
///
/// Couvre deux besoins du cahier des charges :
/// - "Gestion des sessions utilisateur (connexion et déconnexion
///   sécurisées)" ;
/// - le verrouillage automatique par inactivité (choix retenu pour
///   `AuthController`), qui suspend l'accès à l'interface sans fermer
///   la session, jusqu'à re-saisie du mot de passe (PIN).
///
/// Ce service ne contient aucune logique métier (pas d'accès DAO) : il
/// se contente de garder l'état de la session en mémoire. La logique
/// (vérification des identifiants, etc.) reste dans `AuthController`.
class SessionService {
  SessionService._interne();

  static final SessionService instance = SessionService._interne();

  Utilisateur? _utilisateurCourant;
  DateTime? _derniereActivite;
  bool _verrouille = false;

  /// Durée d'inactivité au-delà de laquelle la session doit être
  /// verrouillée. Ajustable selon les besoins de l'établissement.
  static const Duration seuilInactivite = Duration(minutes: 5);

  Utilisateur? get utilisateurCourant => _utilisateurCourant;

  bool get estConnecte => _utilisateurCourant != null;

  bool get estVerrouille => _verrouille;

  /// Démarre une nouvelle session après une connexion réussie.
  void demarrerSession(Utilisateur utilisateur) {
    _utilisateurCourant = utilisateur;
    _verrouille = false;
    enregistrerActivite();
  }

  /// Termine complètement la session (déconnexion explicite).
  void terminerSession() {
    _utilisateurCourant = null;
    _verrouille = false;
    _derniereActivite = null;
  }

  /// À appeler à chaque interaction utilisateur (clic, saisie...) pour
  /// repousser le déclenchement du verrouillage par inactivité.
  void enregistrerActivite() {
    if (estConnecte && !_verrouille) {
      _derniereActivite = DateTime.now();
    }
  }

  /// Verrouille la session sans la fermer : l'utilisateur reste
  /// connecté mais doit re-saisir son mot de passe pour continuer.
  void verrouiller() {
    if (estConnecte) {
      _verrouille = true;
    }
  }

  /// Déverrouille la session. La vérification du mot de passe doit
  /// avoir été faite en amont par `AuthController.deverrouiller()`.
  void deverrouillerSansVerification() {
    _verrouille = false;
    enregistrerActivite();
  }

  /// Indique si la session devrait être verrouillée maintenant, en
  /// fonction du délai d'inactivité écoulé. À appeler périodiquement
  /// (ex. Timer toutes les 30s dans la vue principale).
  bool doitEtreVerrouille() {
    if (!estConnecte || _verrouille) return false;
    final derniere = _derniereActivite;
    if (derniere == null) return false;
    return DateTime.now().difference(derniere) >= seuilInactivite;
  }
}
