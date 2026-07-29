# Views — Système de Gestion de Bibliothèque Scolaire

Ce dossier correspond au répertoire `lib/views/` de l'arborescence MVC
du cahier des charges (§3.2). Les vues affichent l'interface et
capturent les actions, mais ne contiennent **aucune logique métier ni
accès direct aux DAO** : tout passe par les `controllers/`.

| Fichier              | Statut | Rôle |
|------------------------|--------|------|
| `login_page.dart`     | ✅ fait | Authentification (identifiant + mot de passe), branchée sur `AuthController.connecter()` |
| `accueil_page.dart`   | ✅ fait | Point d'entrée après connexion : 4 cartes vers Adhérents / Livres / Emprunts / Tableau de bord |
| `adherents_page.dart` | ✅ fait | Module "Gestion des adhérents" : liste, recherche par nom, ajout, modification, suppression |
| `dashboard_page.dart` | à venir | Tableau de bord (statistiques) |
| `livres_page.dart`    | à venir | Catalogue des livres + exemplaires |
| `prets_page.dart`     | à venir | Emprunts / retours |

## `login_page.dart` et `accueil_page.dart`

- **2 champs seulement** sur la connexion (identifiant affiché "Nom" +
  mot de passe) : pas de champ "code" séparé — conformément au choix
  retenu, le mot de passe sert aussi de PIN pour le déverrouillage par
  inactivité (`AuthController.deverrouiller`).
- `LoginPage` appelle `AuthController.connecter()` ; en cas de succès,
  navigation (`pushReplacement`) vers `AccueilPage` pour empêcher un
  retour arrière vers l'écran de connexion.
- `AccueilPage` affiche les 4 modules sous forme de cartes. Seule la
  carte "Adhérents" navigue réellement vers `AdherentsPage` ; les
  autres affichent un message temporaire ("bientôt disponible") tant
  que leurs pages ne sont pas construites.
- Le bouton de déconnexion sur `AccueilPage` appelle
  `AuthController.deconnecter()` puis revient à `LoginPage` en vidant
  la pile de navigation (`pushAndRemoveUntil`), pour empêcher un retour
  arrière vers les pages protégées.
- `lib/main.dart` a été ajouté (absent jusqu'ici) : point d'entrée qui
  démarre systématiquement sur `LoginPage`.

## `adherents_page.dart` — ce qui a changé par rapport à la maquette d'origine

- **Données réelles** : la liste `List<Adherent> adherents` en dur a été
  remplacée par un chargement asynchrone via `AdherentController.obtenirTous()`
  / `.rechercher()`, avec un état de chargement (`_enChargement`) et un
  état "liste vide".
- **Champs alignés sur le modèle** : `matricule` → `numCarte` partout
  (contrôleurs, formulaire, affichage), pour correspondre exactement à
  `Adherent` (`lib/models/adherent.dart`) et à la table `ADHERENT` du
  MLD.
- **Écriture via le contrôleur** : `_saveAdherent()` et `_deleteAdherent()`
  n'écrivent plus dans une liste locale ; ils appellent
  `AdherentController.inscrire()` / `.modifier()` / `.supprimer()`, qui
  appliquent RG-01 (unicité du numéro de carte) et RG-05 (pas de
  suppression si emprunt en cours) et renvoient un `ResultatOperation`
  affiché tel quel dans le SnackBar en cas d'erreur.
- **`id_utilisateur` obligatoire (RG-07)** : chaque adhérent créé est
  rattaché à `AuthController.utilisateurCourant`. Tant que
  `login_page.dart` n'est pas branchée, cette valeur est `null` et
  l'ajout/la modification échoue proprement avec un message clair —
  c'est le comportement attendu, pas un bug.
- **Correctifs Dart** : l'import `dart:ui` (nécessaire pour l'effet de
  flou) a été déplacé en haut du fichier (un import en fin de fichier
  ne compile pas) ; le `ImageFiltered` n'est plus construit inutilement
  quand `blur == 0`.

## Dépendance requise (`pubspec.yaml`)

```yaml
dependencies:
  google_fonts: ^6.2.1
```
