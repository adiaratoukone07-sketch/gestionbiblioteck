# Widgets — Système de Gestion de Bibliothèque Scolaire

Ce dossier contient des composants d'interface réutilisés sur
plusieurs pages (pas prévu dans l'arborescence initiale du cahier des
charges, mais nécessaire pour éviter de dupliquer du code entre
`views/`).

| Fichier                  | Rôle |
|----------------------------|------|
| `custom_title_bar.dart`  | Barre de titre personnalisée (`BarreTitrePersonnalisee`), avec boutons réduire/agrandir/fermer stylés à la charte, à la place de la barre Windows par défaut |

## `custom_title_bar.dart`

Repose sur le package `bitsdojo_window`. Utilisée en haut de
`login_page.dart`, `accueil_page.dart` et `adherents_page.dart`.

⚠️ Nécessite une petite configuration côté natif Windows
(`windows/runner/main.cpp`) pour fonctionner pleinement — ce fichier
n'existe pas dans ce livrable (généré par `flutter create`). Voir
**`WINDOWS_SETUP.md`** à la racine du projet pour la marche à suivre.

Sans cette étape, l'app fonctionne quand même, mais avec une double
barre de titre (celle de Windows par défaut au-dessus de la nôtre) —
pas bloquant pour tester le reste.

### Repositionner le titre "Bibliotech"

Chaque page qui affiche le mot "Bibliotech" expose une constante
dédiée à sa position, à modifier directement dans le fichier concerné :

- `lib/views/adherents_page.dart` → `positionTitreAdherents`
- `lib/views/accueil_page.dart` → `positionTitreAccueil`

Exemples de valeurs : `Alignment.center` (actuel), `Alignment.centerLeft`,
`Alignment.centerRight`, ou un alignement personnalisé comme
`Alignment(-0.5, 0)`.
