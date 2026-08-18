import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/auth_controller.dart';
import '../widgets/custom_title_bar.dart';
import 'accueil_page.dart';

/// Page de connexion (cf. cahier des charges - module "Authentification" :
/// "Page de connexion avec saisie d'identifiant et de mot de passe").
///
/// Repose sur [AuthController.connecter], qui vérifie les identifiants
/// via `UtilisateurDao` + `HashService` (bcrypt) et démarre la session
/// (`SessionService`) en cas de succès. Le champ affiché "Nom" saisit
/// en réalité `Utilisateur.identifiant` — c'est un choix d'intitulé
/// pour l'utilisateur final, pas un renommage du modèle.
///
/// Conformément au choix retenu pour ce projet, il n'y a que 2 champs
/// (pas de "code" séparé) : le mot de passe sert aussi de PIN pour le
/// déverrouillage après inactivité (cf. `AuthController.deverrouiller`).
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthController _authController = AuthController();

  final TextEditingController _identifiantCtrl = TextEditingController();
  final TextEditingController _motDePasseCtrl = TextEditingController();

  bool _motDePasseVisible = false;
  bool _enConnexion = false;
  String? _messageErreur;

  /// Chemin de l'image de fond. Place le fichier dans
  /// `assets/images/login_background.jpg` et déclare-le dans le
  /// `pubspec.yaml` (section `flutter: assets:`) — cf.
  /// `lib/views/README.md` pour les dimensions recommandées et un
  /// exemple de déclaration.
  static const String _cheminImageFond = 'assets/images/login_background2.png';

  @override
  void dispose() {
    _identifiantCtrl.dispose();
    _motDePasseCtrl.dispose();
    super.dispose();
  }

  Future<void> _seConnecter() async {
    final identifiant = _identifiantCtrl.text.trim();
    final motDePasse = _motDePasseCtrl.text;

    if (identifiant.isEmpty || motDePasse.isEmpty) {
      setState(() {
        _messageErreur = 'Veuillez renseigner votre nom et votre mot de passe.';
      });
      return;
    }

    setState(() {
      _enConnexion = true;
      _messageErreur = null;
    });

    final resultat = await _authController.connecter(identifiant, motDePasse);

    if (!mounted) return;
    setState(() => _enConnexion = false);

    if (!resultat.succes) {
      setState(() => _messageErreur = resultat.messageErreur);
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AccueilPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // Barre de titre personnalisée (cf. lib/widgets/custom_title_bar.dart) :
          // remplace la barre Windows par défaut visible sur les captures.
          const BarreTitrePersonnalisee(
            couleurFond: Color(0xFF241A3E),
            couleurTexte: Colors.white,
            couleurIcones: Colors.white70,
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                // Image de fond à la place des formes décoratives
                // précédentes. `BoxFit.cover` remplit toute la fenêtre
                // quelle que soit sa taille (responsive) en rognant si
                // besoin ; voir README pour les dimensions conseillées.
                image: DecorationImage(
                  image: AssetImage(_cheminImageFond),
                  fit: BoxFit.cover,
                ),
                // Dégradé de secours tant que l'image n'est pas
                // fournie, pour ne pas avoir un écran cassé si
                // l'asset est manquant pendant le développement.
                color: Color(0xFF2E2154),
              ),
              child: Stack(
                children: [
                  Positioned(
                    top: 24,
                    left: 24,
                    child: _buildLogo(),
                  ),
                  Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: _buildCartesJumelees(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 56,
      height: 56,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFC7BADE),
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/icons/mon_logo.png', // ton image perso
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  /// Les deux cartes (photo de livres + formulaire) collées l'une à
  /// l'autre, sans espace entre elles, avec un arrondi uniquement sur
  /// les coins extérieurs — pour donner l'impression d'une seule pièce
  /// coupée en deux (cf. Image 3 / dernière maquette).
  Widget _buildCartesJumelees() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final estLarge = constraints.maxWidth > 760;
        if (!estLarge) {
          // Écran étroit : les cartes ne peuvent plus être côte à
          // côte, on garde uniquement le formulaire, avec un arrondi
          // complet cette fois.
          return _buildCarteFormulaire(arrondiComplet: true);
        }
        return IntrinsicHeight(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageLivres(),
              _buildCarteFormulaire(arrondiComplet: false),
            ],
          ),
        );
      },
    );
  }

  Widget _buildImageLivres() {
    return ClipRRect(
      borderRadius: const BorderRadius.only(
        topLeft: Radius.circular(24),
        bottomLeft: Radius.circular(24),
      ),
      child: Container(
        width: 220,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.35),
              const Color(0xFF241A3E)
            ],
          ),
        ),
        // CORRECTIF : le `Center` qui entourait l'Image donnait des
        // contraintes non-bornées à l'enfant, donc l'image se
        // dessinait à sa taille intrinsèque au lieu de remplir le
        // Container — `BoxFit.cover` n'avait alors aucun effet, et
        // l'image ne suivait pas les variations de hauteur du
        // Container (ex. quand le message d'erreur agrandit la carte
        // voisine via `IntrinsicHeight` + `stretch`). En la mettant
        // en enfant direct du Container (contraintes strictes /
        // "tight" transmises telles quelles car il n'y a pas
        // d'`alignment` sur ce Container), l'image remplit tout
        // l'espace disponible et `BoxFit.cover` peut correctement la
        // recadrer, quelle que soit la hauteur de la carte.
        child: Image.asset(
          'assets/images/pile_livres.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  Widget _buildCarteFormulaire({required bool arrondiComplet}) {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color.fromARGB(157, 255, 255, 255),
        borderRadius: arrondiComplet
            ? BorderRadius.circular(32)
            : const BorderRadius.only(
                topRight: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEAF7),
              borderRadius: BorderRadius.circular(50),
            ),
            child: const Icon(Icons.person, size: 35, color: Color(0xFF5E4FA2)),
          ),
          const SizedBox(height: 28),
          _buildChamp(
            controleur: _identifiantCtrl,
            hint: 'Nom',
            icone: Icons.person_outline,
          ),
          const SizedBox(height: 16),
          _buildChamp(
            controleur: _motDePasseCtrl,
            hint: 'Mot de passe',
            icone: Icons.lock_outline,
            masque: !_motDePasseVisible,
            actionFin: IconButton(
              icon: Icon(
                _motDePasseVisible ? Icons.visibility_off : Icons.visibility,
                color: const Color.fromARGB(155, 4, 0, 20),
              ),
              onPressed: () =>
                  setState(() => _motDePasseVisible = !_motDePasseVisible),
            ),
            onSubmitted: (_) => _seConnecter(),
          ),
          if (_messageErreur != null) ...[
            const SizedBox(height: 14),
            Text(
              _messageErreur!,
              style: GoogleFonts.nunito(
                  color: const Color(0xFFFFD7D7), fontWeight: FontWeight.w600),
              textAlign: TextAlign.center,
            ),
          ],
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _enConnexion ? null : _seConnecter,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4C3E87),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                // FORME DU BOUTON "Connexion" : change ce
                // `circular(28)` pour ajuster l'arrondi du bouton
                // (ex. `circular(12)` pour un rectangle à coins
                // légèrement arrondis, `circular(0)` pour un
                // rectangle net).
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28)),
                elevation: 0,
              ),
              child: _enConnexion
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4,
                          color: Color.fromARGB(255, 212, 166, 226)),
                    )
                  : Text('Connexion',
                      style: GoogleFonts.inter(
                          fontSize: 18, fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChamp({
    required TextEditingController controleur,
    required String hint,
    required IconData icone,
    bool masque = false,
    Widget? actionFin,
    void Function(String)? onSubmitted,
  }) {
    return TextField(
      controller: controleur,
      obscureText: masque,
      onSubmitted: onSubmitted,
      style: GoogleFonts.inter(
        color: const Color.fromARGB(255, 64, 26, 139),
        fontSize: 13,
      ),
      decoration: InputDecoration(
        filled: true,
        fillColor: const Color(0xFFF3F1FA),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          color: const Color.fromARGB(193, 4, 0, 14),
        ),
        prefixIcon: Icon(
          icone,
          color: const Color.fromARGB(160, 1, 0, 7),
        ),
        suffixIcon: actionFin,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 248, 247, 252),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: const BorderSide(
            color: Color.fromARGB(255, 142, 117, 250),
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          vertical: 10,
          horizontal: 8,
        ),
      ),
    );
  }
}
