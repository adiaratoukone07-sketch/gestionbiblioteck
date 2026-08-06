# Views — Système de Gestion de Bibliothèque Scolaire

Ce dossier correspond au répertoire `lib/views/` de l'arborescence MVC
du cahier des charges (§3.2). Les vues affichent l'interface et
capturent les actions, mais ne contiennent **aucune logique métier ni
accès direct aux DAO** : tout passe par les `controllers/`.

| Fichier              | Statut | Rôle |
|------------------------|--------|------|
| `login_page.dart`     | ✅ fait | Authentification (identifiant + mot de passe), branchée sur `AuthController.connecter()` |
| `accueil_page.dart`   | ✅ fait | Point d'entrée après connexion : 4 cartes vers Adhérents / Livres / Emprunts / Tableau de bord |
| `adherents_page.dart` | ✅ refait | Reconstruite selon le design fourni (sidebar dynamique, tableau à colonnes fixes, statuts cliquables, menu contextuel flottant, état vide, formulaire 2 colonnes) |
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

## `adherents_page.dart` — reconstruite selon le design fourni

- **Sidebar dynamique** : onglet actif = capsule violet clair
  (`Color(0xFFEDE9F7)`), les autres restent discrets. "Home" navigue
  réellement vers `AccueilPage` (déjà construite) ; "Livres",
  "Emprunts" et "Tableau de bord" basculent sur un espace réservé
  interne (pas de rechargement de l'app) tant que ces pages n'existent
  pas — à remplacer par leurs vraies pages une fois prêtes.
- **Tableau à colonnes fixes** : Nom, Prénom, Nom Complet, Matricule
  (= `numCarte`), Classe, Statut, actions — alignement garanti par
  `_ligneColonnes()`, réutilisée à l'identique par l'en-tête et chaque
  ligne.
- **Statut calculé dynamiquement**, pas simulé : `_chargerStatuts()`
  interroge `PretController.obtenirHistoriqueParAdherent()` pour
  chaque adhérent affiché et déduit "Aucun emprunt" / "En cours" / "En
  retard" à partir des vrais emprunts en cours (`Pret.estEnCours`,
  `Pret.estEnRetard`). Cliquer sur un badge affiche pour l'instant un
  message temporaire — à remplacer par une vraie navigation vers le
  module Emprunts/Livres une fois ces pages construites.
- **Menu contextuel flottant** : au clic sur les trois points, un
  conteneur blanc arrondi avec crayon/poubelle apparaît sur la ligne ;
  les autres lignes sont floutées (`ImageFiltered` + opacité réduite)
  et le défilement de la liste est désactivé
  (`NeverScrollableScrollPhysics`) tant que le menu est ouvert. Un clic
  en dehors d'une ligne referme le menu.
- **Suppression confirmée** : un `AlertDialog` de confirmation a été
  ajouté avant `AdherentController.supprimer()` (non demandé
  explicitement, mais évite une suppression accidentelle vu que RG-05
  n'empêche que les adhérents avec emprunts en cours).
- **État vide dédié** : icône, titre "Aucun adhérent enregistré",
  sous-titre, bouton "+ Ajouter un adhérent" qui ouvre directement le
  formulaire en mode ajout.
- **Formulaire à 2 colonnes** (Nom/Prénom puis Matricule/Classe),
  conforme à l'Image 2 de la maquette, avec `ModeFormulaire` (`masque`
  / `ajout` / `modification`) pilotant le texte du bouton et le
  pré-remplissage des champs.
- **Simplification assumée** : le prompt de design décrit un effet où
  la ligne sélectionnée "se déplace visuellement à la première ligne
  disponible" façon carrousel (cf. Image 1). Cet effet n'a pas été
  reproduit tel quel — trop coûteux à maintenir sur une liste
  connectée à une vraie base de données qui peut se réordonner (tri,
  recherche...). À la place : mise en surbrillance + ombre portée sur
  la ligne sélectionnée, flou uniforme sur les autres. Dis-le si tu
  veux qu'on pousse plus loin sur cet effet précis.

## Dépendance requise (`pubspec.yaml`)

```yaml
dependencies:
  google_fonts: ^6.2.1
```
