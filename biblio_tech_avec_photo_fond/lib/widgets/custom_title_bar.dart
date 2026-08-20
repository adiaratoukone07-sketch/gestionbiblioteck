import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Barre de titre personnalisée, réutilisable sur toutes les pages.
///
/// Remplace la barre de titre Windows par défaut (celle qu'on voit sur
/// tes captures avec "bibliotheque_scolaire" en noir) par une barre à
/// notre charte graphique, avec nos propres boutons réduire / agrandir
/// / fermer. Repose sur le package `bitsdojo_window`, qui rend la
/// fenêtre "frameless" (sans bordure système) — cf. `windows/README.md`
/// pour la configuration native nécessaire côté `windows/runner/`.
///
/// [couleurFond] et [couleurTexte] permettent de l'adapter au thème de
/// chaque page (fond violet foncé sur la connexion, blanc sur les
/// pages internes). [titre] et [alignementTitre] permettent de
/// repositionner facilement le texte (cf. demande de repositionnement
/// du mot "Bibliotech").
class BarreTitrePersonnalisee extends StatelessWidget
    implements PreferredSizeWidget {
  final Color couleurFond;
  final Color couleurTexte;
  final Color couleurIcones;
  final String? titre;
  final Alignment alignementTitre;
  final double hauteur;

  const BarreTitrePersonnalisee({
    super.key,
    this.couleurFond = Colors.white,
    this.couleurTexte = const Color(0xFF3B2470),
    this.couleurIcones = const Color(0xFF7A6FA0),
    this.titre,
    this.alignementTitre = Alignment.center,
    this.hauteur = 44,
  });

  @override
  Size get preferredSize => Size.fromHeight(hauteur);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: hauteur,
      color: couleurFond,
      child: Row(
        children: [
          // MoveWindow rend toute cette zone "glissable" (cliquer-
          // glisser pour déplacer la fenêtre), comme une vraie barre
          // de titre.
          Expanded(
            child: MoveWindow(
              child: titre == null
                  ? const SizedBox.shrink()
                  : Align(
                      alignment: alignementTitre,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Text(
                          titre!,
                          style: GoogleFonts.inter(
                            color: couleurTexte,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          _BoutonsFenetre(couleurIcones: couleurIcones),
        ],
      ),
    );
  }
}

/// Boutons réduire / agrandir-restaurer / fermer, stylés avec les
/// couleurs de l'application plutôt que le style Windows par défaut.
class _BoutonsFenetre extends StatelessWidget {
  final Color couleurIcones;

  const _BoutonsFenetre({required this.couleurIcones});

  @override
  Widget build(BuildContext context) {
    final couleurs = WindowButtonColors(
      iconNormal: couleurIcones,
      mouseOver: const Color(0xFFEDE9F7),
      mouseDown: const Color(0xFFDCD3F0),
      iconMouseOver: const Color(0xFF3B2470),
      iconMouseDown: const Color(0xFF3B2470),
    );
    final couleursFermer = WindowButtonColors(
      iconNormal: couleurIcones,
      mouseOver: const Color.fromARGB(255, 236, 40, 40),
      mouseDown: const Color(0xFF8F1414),
      iconMouseOver: Colors.white,
      iconMouseDown: Colors.white,
    );

    return Row(
      children: [
        MinimizeWindowButton(colors: couleurs),
        MaximizeWindowButton(colors: couleurs),
        CloseWindowButton(colors: couleursFermer),
      ],
    );
  }
}
