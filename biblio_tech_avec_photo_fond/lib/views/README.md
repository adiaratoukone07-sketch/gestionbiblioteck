# Views — Système de Gestion de Bibliothèque Scolaire

Ce dossier correspond au répertoire `lib/views/` de l'arborescence MVC
du cahier des charges (§3.2). Les vues affichent l'interface et
capturent les actions, mais ne contiennent **aucune logique métier ni
accès direct aux DAO** : tout passe par les `controllers/`.

| Fichier              | Statut | Rôle |
|------------------------|--------|------|
| `login_page.dart`     | ✅ fait | Authentification (identifiant + mot de passe), branchée sur `AuthController.connecter()` |
| `accueil_page.dart`   | ✅ fait | Point d'entrée après connexion : 4 cartes vers Adhérents / Livres / Emprunts / Tableau de bord |
| `adherents_page.dart` | ✅ fait | Gestion des adhérents (sidebar dynamique, tableau à colonnes fixes, statuts cliquables, menu contextuel flottant, état vide, formulaire 2 colonnes) |
| `livres_page.dart`    | ✅ fait | Catalogue des livres + exemplaires (RG-06), même patterns que `adherents_page.dart` |
| `prets_page.dart`     | ✅ fait | Emprunts / retours (RG-02, RG-03, RG-04), liste de cartes + filtres En cours/En retard/Tous |
| `dashboard_page.dart` | ✅ fait | Tableau de bord : indicateurs + livres les plus empruntés, via `StatistiqueController` |

Les 6 pages du cahier des charges sont maintenant construites. Toute
la navigation entre modules passe par `Navigator.pushReplacement` (une
page remplace l'autre, pas d'empilement de retours en arrière).

## `livres_page.dart`, `prets_page.dart`, `dashboard_page.dart`

Construites en suivant les mêmes principes que la version finale de
`adherents_page.dart` (formulaire compact, distinction recherche vide
≠ base vide, widgets de ligne à état local pour éviter le clignotement
au survol), mais avec une nouveauté :

- **`lib/widgets/app_shell.dart`** — la sidebar + barre de titre de
  `adherents_page.dart` ont été extraites dans un widget partagé
  (`AppShell`) pour ces 3 nouvelles pages, plutôt que de recopier
  ~150 lignes de sidebar dans chaque fichier. Il reproduit fidèlement
  ton style personnalisé (police Inter, logo `assets/icons/mon_logo.png`,
  couleurs de survol, `withValues(alpha:)`).
- `adherents_page.dart` garde sa propre sidebar interne (déjà écrite et
  personnalisée avant la création d'`AppShell`) plutôt que d'être
  migrée vers le widget partagé, pour ne pas risquer de casser tes
  ajustements — mais sa méthode `_naviguerVersModule` a été mise à jour
  pour naviguer réellement vers `LivresPage`, `PretsPage` et
  `DashboardPage` maintenant qu'elles existent (elle affichait un
  message "bientôt disponible" auparavant). La méthode
  `_buildPlaceholderModule`, devenue inutile, a été supprimée.
- **`prets_page.dart`** utilise une liste de cartes plutôt qu'un
  tableau à colonnes fixes : un emprunt combine des infos de deux
  entités (adhérent + livre/exemplaire), plus lisible empilé qu'aligné
  en colonnes étroites. Le formulaire "Nouvel emprunt" est une boîte
  de dialogue à 2 menus déroulants (adhérent, livre — filtré pour
  n'afficher que les livres ayant au moins un exemplaire disponible),
  plutôt qu'un panneau bas de page.
- **Deux petites méthodes ajoutées aux contrôleurs** pour ces pages :
  `PretController.obtenirTous()` (filtre "Tous" de `prets_page.dart`)
  et `ExemplaireController.obtenirParId()` (retrouver le livre associé
  à un emprunt).

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

### Image de fond de la connexion (`login_page.dart`)

Remplace les formes décoratives précédentes par une vraie image
(`DecorationImage` + `BoxFit.cover`), responsive à toute taille de
fenêtre.

**Dimensions recommandées** :
- **Minimum : 1920 × 1080 px** (Full HD, ratio 16:9) — suffisant pour
  la taille de fenêtre par défaut (`1280×800`, cf. `main.dart`).
- **Conseillé : 2560 × 1440 px** (ratio 16:9) — reste net si
  l'utilisateur agrandit la fenêtre ou est sur un écran haute
  définition. Au-delà (ex. 3840×2160/4K), le gain visuel est marginal
  pour un gain de poids de fichier important.
- Format `.jpg` (photo) recommandé pour le poids ; `.png` si
  transparence nécessaire.

**Mise en place :**
1. Place le fichier dans `assets/images/login_background.jpg`.
2. Déclare-le dans `pubspec.yaml` :
   ```yaml
   flutter:
     assets:
       - assets/images/
   ```
3. `lib/views/login_page.dart` pointe déjà vers ce chemin via la
   constante `_cheminImageFond` — change juste cette constante si le
   nom de fichier diffère.

Tant que l'image n'est pas fournie, un dégradé violet de secours
s'affiche à la place (pas d'écran cassé pendant le développement).

### Cartes jumelées (image livres + formulaire)

Les deux cartes de `login_page.dart` sont maintenant collées (plus
d'espace entre elles) : la carte image n'a d'arrondi qu'à gauche
(`topLeft`/`bottomLeft`), la carte formulaire qu'à droite
(`topRight`/`bottomRight`) — elles se comportent visuellement comme un
seul bloc coupé en deux, conformément à la dernière maquette. Sur un
écran étroit (largeur < 760px), seule la carte formulaire s'affiche,
avec un arrondi complet cette fois (`arrondiComplet: true`).

## Barre de titre personnalisée (toutes les pages)

`login_page.dart`, `accueil_page.dart` et `adherents_page.dart`
utilisent désormais `BarreTitrePersonnalisee`
(`lib/widgets/custom_title_bar.dart`) à la place des icônes
décoratives précédentes : vrais boutons réduire / agrandir / fermer,
stylés à la charte, plus la barre Windows par défaut. Nécessite une
petite configuration native — voir `WINDOWS_SETUP.md` à la racine.

## `adherents_page.dart` — corrections suite aux retours

- **Sidebar dynamique** : onglet actif = capsule violet clair
  (`Color(0xFFEDE9F7)`), les autres restent discrets. "Home" navigue
  réellement vers `AccueilPage` (déjà construite) ; "Livres",
  "Emprunts" et "Tableau de bord" basculent sur un espace réservé
  interne (pas de rechargement de l'app) tant que ces pages n'existent
  pas — à remplacer par leurs vraies pages une fois prêtes.
- **Tableau à colonnes fixes** : Nom, Prénom, Nom Complet, Matricule
  (= `numCarte`), Classe, Statut, actions — alignement garanti par
  `construireLigneColonnes()` (fonction de fichier, plus une méthode
  d'instance, pour être réutilisable par le nouveau widget de ligne).
- **Lignes de séparation** : `ListView.separated` avec un `Divider`
  fin entre chaque ligne, pour que la liste ne "nage" plus visuellement.
- **Statut calculé dynamiquement**, pas simulé : `_chargerStatuts()`
  interroge `PretController.obtenirHistoriqueParAdherent()` pour
  chaque adhérent affiché et déduit "Aucun emprunt" / "En cours" / "En
  retard" à partir des vrais emprunts en cours (`Pret.estEnCours`,
  `Pret.estEnRetard`). Cliquer sur un badge affiche pour l'instant un
  message temporaire — à remplacer par une vraie navigation vers le
  module Emprunts/Livres une fois ces pages construites.
- **Titre "Bibliotech" repositionnable** : constante
  `positionTitreAdherents` en haut du fichier (idem
  `positionTitreAccueil` dans `accueil_page.dart`), passée à
  `alignementTitre` de `BarreTitrePersonnalisee`.
- **Formulaire allégé** : champs et bouton "Ajouter"/"Modifier"
  nettement plus compacts (padding réduit, `isDense: true` sur les
  champs, bouton non étiré sur toute la largeur).
- **Menu contextuel qui ne déborde plus** : la colonne d'actions est
  passée de 56px à `_largeurColonneActions = 96`px, et les boutons
  crayon/poubelle du menu flottant utilisent des `constraints`
  compactes — corrige le "RIGHT OVERFLOWED BY 36 PIXELS".
- **Recherche sans résultat ≠ base vide** : `_baseVide` distingue "il
  n'y a aucun adhérent en base" de "cette recherche ne donne rien" ;
  le second cas affiche un message dédié avec un bouton "Réinitialiser
  la recherche", au lieu du message "Aucun adhérent enregistré" qui
  était trompeur.
- **Overflow en bas corrigé quand le formulaire s'ouvre depuis la
  liste vide** : l'état vide était affiché en plus du formulaire dans
  l'espace restant très réduit, ce qui provoquait un "BOTTOM
  OVERFLOWED BY 16 PIXELS". Désormais, dès que le formulaire est
  ouvert, l'état vide n'affiche plus qu'un texte compact (le bouton "+
  Ajouter" fait doublon avec le formulaire déjà visible, donc il
  disparaît) — et tout est enveloppé dans un `SingleChildScrollView`
  par sécurité, pour ne plus jamais déborder même si l'espace devient
  minuscule.
- **Clignotement au survol corrigé** : chaque ligne est maintenant un
  widget à état séparé (`_LigneAdherentWidget`), avec une clé stable
  (`ValueKey`) et une marge fixe qui ne change jamais avec l'état.
  Avant, le survol déclenchait un `setState` sur toute la page, qui
  reconstruisait la liste entière (donc recréait chaque ligne sans
  identité stable), provoquant le clignotement. Seule la ligne
  survolée se reconstruit désormais.
- **Suppression confirmée** : un `AlertDialog` de confirmation a été
  ajouté avant `AdherentController.supprimer()` (non demandé
  explicitement, mais évite une suppression accidentelle vu que RG-05
  n'empêche que les adhérents avec emprunts en cours).
- **Formulaire à 2 colonnes** (Nom/Prénom puis Matricule/Classe),
  conforme à l'Image 2 de la maquette, avec `ModeFormulaire` (`masque`
  / `ajout` / `modification`) pilotant le texte du bouton et le
  pré-remplissage des champs.
- **Simplification assumée, inchangée** : l'effet "carrousel" où la
  ligne sélectionnée se déplace visuellement (cf. captures) n'est
  toujours pas reproduit à l'identique, remplacé par surbrillance +
  ombre + opacité réduite sur les autres lignes. Dis-le si tu veux
  qu'on pousse plus loin sur ce point précis.

## Dépendances requises (`pubspec.yaml`)

```yaml
dependencies:
  google_fonts: ^6.2.1
  bitsdojo_window: ^0.1.6

flutter:
  assets:
    - assets/images/
```
