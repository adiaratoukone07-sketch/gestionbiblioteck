import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/auth_controller.dart';
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF6E5AAE), Color(0xFF241A3E)],
          ),
        ),
        child: Stack(
          children: [
            // Formes décoratives en fond (cf. maquette).
            Positioned(
              left: -120,
              bottom: -150,
              child: _tacheDecorative(340, Colors.deepPurple.withOpacity(0.35)),
            ),
            Positioned(
              right: -110,
              top: -130,
              child: _tacheDecorative(280, Colors.black.withOpacity(0.25)),
            ),
            Positioned(
              top: 32,
              left: 32,
              child: _buildLogo(),
            ),
            Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final estLarge = constraints.maxWidth > 760;
                    final formulaire = _buildCarteFormulaire();
                    if (!estLarge) return formulaire;
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        _buildImageLivres(),
                        const SizedBox(width: 32),
                        formulaire,
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tacheDecorative(double taille, Color couleur) {
    return Container(
      width: taille,
      height: taille,
      decoration: BoxDecoration(shape: BoxShape.circle, color: couleur),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.black,
        border: Border.all(color: const Color(0xFFC9A34D), width: 2),
      ),
      child: const Icon(Icons.menu_book_rounded, color: Color(0xFFC9A34D)),
    );
  }

  Widget _buildImageLivres() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Container(
        width: 220,
        height: 380,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withOpacity(0.35), const Color(0xFF241A3E)],
          ),
        ),
        // Remplacer par Image.asset('assets/pile_livres.jpg') pour
        // reproduire fidèlement la photo de la maquette.
        child: const Icon(Icons.menu_book, size: 64, color: Colors.white24),
      ),
    );
  }

  Widget _buildCarteFormulaire() {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: const Color(0xFF7A6BB5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: BoxDecoration(
              color: const Color(0xFFEDEAF7),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.person, size: 48, color: Color(0xFF5E4FA2)),
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
                color: const Color(0xFF7C6BC4),
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
                shape:
                    RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
                elevation: 0,
              ),
              child: _enConnexion
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.4, color: Colors.white),
                    )
                  : Text('Connexion',
                      style: GoogleFonts.quicksand(
                          fontSize: 16, fontWeight: FontWeight.w700)),
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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1FA),
        borderRadius: BorderRadius.circular(30),
      ),
      child: TextField(
        controller: controleur,
        obscureText: masque,
        onSubmitted: onSubmitted,
        style: GoogleFonts.nunito(color: const Color(0xFF3B2470), fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: GoogleFonts.nunito(color: const Color(0xFF9C93B8)),
          prefixIcon: Icon(icone, color: const Color(0xFF7C6BC4)),
          suffixIcon: actionFin,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        ),
      ),
    );
  }
}
