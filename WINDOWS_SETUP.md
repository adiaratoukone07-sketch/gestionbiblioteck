# Configuration Windows pour la barre de titre personnalisée

`bitsdojo_window` a besoin d'une petite modification côté natif pour
rendre la fenêtre "frameless" (sans barre de titre Windows par
défaut). Cette modification se fait dans `windows/runner/main.cpp`,
un fichier généré par `flutter create` — il n'existe donc pas dans ce
livrable (nous n'avons ici que `lib/`), je ne peux pas l'éditer
directement. Voici comment l'appliquer toi-même, c'est rapide :

## Étapes

1. Assure-toi d'avoir lancé `flutter pub get` après avoir ajouté
   `bitsdojo_window` au `pubspec.yaml`.

2. Ouvre **`windows/runner/main.cpp`**.

3. Suis la section **"Windows Setup"** du README officiel du package :
   https://pub.dev/packages/bitsdojo_window

   Le principe : le fichier `main.cpp` généré par défaut crée la
   fenêtre via `Win32Window::Create(...)`. La doc du package te donne
   le code exact à coller à la place (il enveloppe la création de
   fenêtre avec `bitsdojo_window_configure(...)`), copié-collé prêt à
   l'emploi — la version exacte dépend de la version du package
   installée, d'où le renvoi vers leur doc plutôt qu'un extrait figé
   ici qui pourrait être obsolète.

4. Recompile : `flutter run -d windows`.

## Ce qui est déjà fait côté Dart

- `lib/main.dart` appelle `doWhenWindowReady()` et configure la taille
  de fenêtre (`appWindow.size`, `appWindow.minSize`, etc.).
- `lib/widgets/custom_title_bar.dart` fournit `BarreTitrePersonnalisee`,
  utilisée en haut de `login_page.dart` et `adherents_page.dart` à la
  place des icônes décoratives précédentes — avec de vrais boutons
  réduire / agrandir / fermer fonctionnels, stylés à la charte de
  l'application.

Si tu préfères ne pas toucher au natif tout de suite, l'app continuera
de fonctionner avec la barre de titre Windows par défaut au-dessus de
`BarreTitrePersonnalisee` (donc une double barre) jusqu'à ce que
l'étape 3 soit faite — ce n'est pas bloquant pour tester le reste.
