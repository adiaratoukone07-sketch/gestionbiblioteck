# Controllers — Système de Gestion de Bibliothèque Scolaire

Ce dossier correspond au répertoire `lib/controllers/` de
l'arborescence MVC du cahier des charges (§3.2) : couche métier, entre
les vues (`views/`) et l'accès aux données (`database/`).

| Fichier                     | Rôle |
|-------------------------------|------|
| `resultat_operation.dart`    | Type de retour générique (`ResultatOperation` / `ResultatOperationAvecDonnee<T>`) partagé par tous les contrôleurs, pour renvoyer succès/échec + message d'erreur clair à l'IHM |
| `auth_controller.dart`       | Connexion, déconnexion, **verrouillage par inactivité avec PIN** (le PIN réutilise le mot de passe du compte) |
| `adherent_controller.dart`   | Inscription, modification, suppression, recherche — RG-01, RG-05 |
| `livre_controller.dart`      | Ajout (génère les exemplaires), modification, suppression, recherche — RG-06 |
| `exemplaire_controller.dart` | Gestion fine des exemplaires individuels (ajout a posteriori, retrait, déclaration de perte) — contrôleur ajouté suite à la promotion d'EXEMPLAIRE en entité |
| `pret_controller.dart`       | Emprunt, retour, consultation des retards, historique — RG-02, RG-03, RG-04 |
| `statistique_controller.dart`| Agrégation des indicateurs du tableau de bord |

## Modèle de session retenu

Conformément au choix fait pour ce projet : **connexion/déconnexion +
verrouillage automatique par inactivité**, géré par
`services/session_service.dart` et orchestré par `AuthController` :

- `AuthController.connecter()` : vérifie identifiant + mot de passe (bcrypt), démarre la session.
- `AuthController.signalerActivite()` : à appeler à chaque interaction utilisateur (ex. sur les événements de la vue principale) pour repousser le verrouillage.
- `AuthController.verifierEtVerrouillerSiInactif()` : à appeler périodiquement (ex. `Timer.periodic` toutes les 30 secondes) ; verrouille la session si le délai d'inactivité (`SessionService.seuilInactivite`, 5 minutes par défaut) est dépassé.
- `AuthController.deverrouiller(motDePasse)` : re-vérifie le mot de passe pour déverrouiller **sans fermer la session** (l'utilisateur ne perd pas son contexte de travail).
- `AuthController.deconnecter()` : ferme complètement la session (bouton "Se déconnecter").

## Règles de gestion et contrôleur responsable

| Règle | Contrôleur | Méthode |
|---|---|---|
| RG-01 (unicité num_carte) | `AdherentController` | `inscrire()`, `modifier()` |
| RG-02 (disponibilité exemplaire) | `PretController` | `emprunter()` |
| RG-03 (max 3 emprunts simultanés) | `PretController` | `emprunter()` |
| RG-04 (durée max 14 jours) | `Pret.nouveau()` (modèle) | appelé depuis `emprunter()` |
| RG-05 (pas de suppression si emprunt en cours) | `AdherentController` | `supprimer()` |
| RG-06 (pas de suppression si exemplaire emprunté) | `LivreController` / `ExemplaireController` | `supprimer()` / `supprimerExemplaire()` |
| RG-07 (rattachement à un utilisateur gestionnaire) | Contrainte SQL (déclarative, voir `database/`) | — |
