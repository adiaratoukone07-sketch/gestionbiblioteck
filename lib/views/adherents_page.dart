import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/adherent_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/pret_controller.dart';
import '../controllers/resultat_operation.dart';
import '../models/adherent.dart';
import '../models/pret.dart';
import 'accueil_page.dart';

/// Modules accessibles depuis la sidebar. `adherents` est le module de
/// cette page ; les autres ne sont pas encore construits (cf.
/// `dashboard_page.dart`, `livres_page.dart`, `prets_page.dart` à
/// venir), donc leur contenu est un simple espace réservé tant qu'ils
/// n'existent pas — la sidebar bascule dessus sans recharger l'appli
/// (`IndexedStack`-like), conformément au prompt de design.
enum _ModuleSidebar { home, adherents, livres, emprunts, tableauDeBord }

/// Les 3 états du formulaire bas de page (cf. prompt de design §5).
enum ModeFormulaire { masque, ajout, modification }

/// Statut d'emprunt affiché dans la colonne "Statut" (cf. prompt de
/// design §3), calculé à partir de l'historique réel des emprunts via
/// [PretController] — pas de donnée simulée.
enum _StatutAdherent { aucunEmprunt, enCours, enRetard }

/// Page "Adhérents" (cf. cahier des charges - module "Gestion des
/// adhérents"), reconstruite pour suivre précisément le design fourni :
/// sidebar avec onglet actif dynamique, tableau à colonnes fixes avec
/// statut cliquable, menu contextuel flottant (survol + flou), état
/// vide dédié, formulaire à deux colonnes en bas de page.
///
/// Toute la logique métier passe par [AdherentController] (RG-01,
/// RG-05) et [PretController] (pour le statut d'emprunt de chaque
/// adhérent) — cette page ne contient aucun accès direct aux DAO.
class AdherentsPage extends StatefulWidget {
  const AdherentsPage({super.key});

  @override
  State<AdherentsPage> createState() => _AdherentsPageState();
}

class _AdherentsPageState extends State<AdherentsPage> {
  final AdherentController _adherentController = AdherentController();
  final AuthController _authController = AuthController();
  final PretController _pretController = PretController();

  _ModuleSidebar _moduleActif = _ModuleSidebar.adherents;

  List<Adherent> _adherents = [];
  Map<int, _StatutAdherent> _statuts = {};
  bool _enChargement = true;

  /// Ligne actuellement survolée par la souris (glow léger).
  int? _hoveredId;

  /// Ligne dont le menu contextuel (crayon/poubelle) est ouvert : les
  /// autres lignes sont alors floutées et le défilement désactivé.
  int? _menuOuvertPourId;

  ModeFormulaire _modeFormulaire = ModeFormulaire.masque;
  int? _idEnEdition;

  final TextEditingController _nomCtrl = TextEditingController();
  final TextEditingController _prenomCtrl = TextEditingController();
  final TextEditingController _numCarteCtrl = TextEditingController();
  final TextEditingController _classeCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerAdherents();
  }

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _numCarteCtrl.dispose();
    _classeCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // --- CHARGEMENT DES DONNÉES ---

  Future<void> _chargerAdherents({String? motCle}) async {
    setState(() => _enChargement = true);
    final resultats = (motCle != null && motCle.isNotEmpty)
        ? await _adherentController.rechercher(nom: motCle)
        : await _adherentController.obtenirTous();
    if (!mounted) return;
    setState(() {
      _adherents = resultats;
      _enChargement = false;
    });
    await _chargerStatuts();
  }

  /// Calcule le statut d'emprunt de chaque adhérent affiché, à partir
  /// de son historique réel (`PretController.obtenirHistoriqueParAdherent`),
  /// pas d'une donnée figée : "En retard" prime sur "En cours", qui
  /// prime sur "Aucun emprunt".
  Future<void> _chargerStatuts() async {
    final Map<int, _StatutAdherent> statuts = {};
    for (final adherent in _adherents) {
      final id = adherent.idAdherent;
      if (id == null) continue;
      final historique = await _pretController.obtenirHistoriqueParAdherent(id);
      final List<Pret> enCours = historique.where((p) => p.estEnCours).toList();
      if (enCours.isEmpty) {
        statuts[id] = _StatutAdherent.aucunEmprunt;
      } else if (enCours.any((p) => p.estEnRetard)) {
        statuts[id] = _StatutAdherent.enRetard;
      } else {
        statuts[id] = _StatutAdherent.enCours;
      }
    }
    if (!mounted) return;
    setState(() => _statuts = statuts);
  }

  void _showToast(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message,
            style: GoogleFonts.quicksand(fontWeight: FontWeight.w600)),
        backgroundColor:
            isError ? const Color(0xFFB91C1C) : const Color(0xFF3B2470),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  // --- NAVIGATION SIDEBAR ---

  void _naviguerVersModule(_ModuleSidebar module) {
    if (module == _ModuleSidebar.home) {
      // "Home" est déjà une page à part entière et aboutie : on y
      // navigue réellement plutôt que d'afficher un espace réservé.
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const AccueilPage()),
      );
      return;
    }
    setState(() {
      _moduleActif = module;
      _menuOuvertPourId = null;
    });
  }

  // --- FORMULAIRE ---

  void _ouvrirFormulaireAjout() {
    setState(() {
      _modeFormulaire = ModeFormulaire.ajout;
      _idEnEdition = null;
      _menuOuvertPourId = null;
      _nomCtrl.clear();
      _prenomCtrl.clear();
      _numCarteCtrl.clear();
      _classeCtrl.clear();
    });
  }

  void _ouvrirFormulaireEdition(Adherent adherent) {
    setState(() {
      _modeFormulaire = ModeFormulaire.modification;
      _idEnEdition = adherent.idAdherent;
      _menuOuvertPourId = null;
      _nomCtrl.text = adherent.nom;
      _prenomCtrl.text = adherent.prenom;
      _numCarteCtrl.text = adherent.numCarte;
      _classeCtrl.text = adherent.classe;
    });
  }

  void _fermerFormulaire() {
    setState(() {
      _modeFormulaire = ModeFormulaire.masque;
      _idEnEdition = null;
    });
  }

  Future<void> _validerFormulaire() async {
    final nom = _nomCtrl.text.trim();
    final prenom = _prenomCtrl.text.trim();
    final numCarte = _numCarteCtrl.text.trim();
    final classe = _classeCtrl.text.trim();

    if (nom.isEmpty || prenom.isEmpty || numCarte.isEmpty) {
      _showToast('Veuillez remplir Nom, Prénom et Matricule.', isError: true);
      return;
    }

    // Rattachement obligatoire à l'utilisateur connecté (RG-07). Tant
    // que login_page.dart n'a pas démarré de session, ce garde-fou
    // s'active normalement.
    final idUtilisateur = _authController.utilisateurCourant?.idUtilisateur;
    if (idUtilisateur == null) {
      _showToast('Session expirée, veuillez vous reconnecter.', isError: true);
      return;
    }

    ResultatOperation resultat;
    if (_modeFormulaire == ModeFormulaire.modification &&
        _idEnEdition != null) {
      final adherent = Adherent(
        idAdherent: _idEnEdition,
        numCarte: numCarte,
        nom: nom,
        prenom: prenom,
        classe: classe,
        idUtilisateur: idUtilisateur,
      );
      resultat = await _adherentController.modifier(adherent);
    } else {
      final adherent = Adherent(
        numCarte: numCarte,
        nom: nom,
        prenom: prenom,
        classe: classe,
        idUtilisateur: idUtilisateur,
      );
      final resultatAvecId = await _adherentController.inscrire(adherent);
      resultat = resultatAvecId.succes
          ? const ResultatOperation.succes()
          : ResultatOperation.echec(resultatAvecId.messageErreur);
    }

    if (!resultat.succes) {
      // Affiche directement le message de règle de gestion (ex. RG-01)
      // renvoyé par le contrôleur.
      _showToast(resultat.messageErreur ?? 'Une erreur est survenue.',
          isError: true);
      return;
    }

    _showToast(_modeFormulaire == ModeFormulaire.modification
        ? 'Adhérent modifié'
        : 'Adhérent ajouté');
    _fermerFormulaire();
    await _chargerAdherents(motCle: _searchCtrl.text.trim());
  }

  Future<void> _confirmerSuppression(Adherent adherent) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Supprimer cet adhérent ?',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        content: Text(
            'Cette action est définitive pour ${adherent.nomComplet}.',
            style: GoogleFonts.nunito()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer',
                style: TextStyle(color: Color(0xFFB91C1C))),
          ),
        ],
      ),
    );

    if (confirme != true) return;
    final id = adherent.idAdherent;
    if (id == null) return;
    await _supprimerAdherent(id);
  }

  Future<void> _supprimerAdherent(int id) async {
    // RG-05 est vérifiée par le contrôleur : suppression refusée si
    // l'adhérent a des emprunts en cours.
    final resultat = await _adherentController.supprimer(id);
    setState(() => _menuOuvertPourId = null);

    if (!resultat.succes) {
      _showToast(resultat.messageErreur ?? 'Suppression impossible.',
          isError: true);
      return;
    }

    await _chargerAdherents(motCle: _searchCtrl.text.trim());
    _showToast('Adhérent supprimé');
  }

  /// Clic sur un badge de statut (cf. prompt de design §3) : redirige
  /// vers le module Emprunts (ou Livres pour un retard). Ces modules
  /// n'étant pas encore construits, on affiche pour l'instant un
  /// message temporaire — à remplacer par un vrai
  /// `Navigator.pushNamed('/emprunts', arguments: adherent)` une fois
  /// `prets_page.dart` prêt.
  void _onStatutTap(Adherent adherent, _StatutAdherent? statut) {
    switch (statut) {
      case _StatutAdherent.enRetard:
        _showToast(
            'Redirection vers le livre en retard de ${adherent.nomComplet} (à venir).');
        break;
      case _StatutAdherent.enCours:
        _showToast(
            'Emprunts en cours de ${adherent.nomComplet} (module Emprunts à venir).');
        break;
      case _StatutAdherent.aucunEmprunt:
      default:
        _showToast(
            'Nouvel emprunt pour ${adherent.nomComplet} (module Emprunts à venir).');
    }
  }

  // --- SIDEBAR ---

  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4C3E87), Color(0xFF241A3E)],
        ),
      ),
      child: Stack(
        children: [
          // Motif/texture décoratif en bas de la sidebar (cf. prompt
          // de design §1). Remplacer par une image dédiée si besoin
          // (Image.asset('assets/sidebar_texture.png')).
          Positioned(
            left: -70,
            bottom: -90,
            child: _tacheDecorative(200, Colors.white.withOpacity(0.05)),
          ),
          Positioned(
            left: 10,
            bottom: -50,
            child: _tacheDecorative(140, Colors.deepPurple.withOpacity(0.3)),
          ),
          Column(
            children: [
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Remplacer par Image.asset('assets/logo.png') pour
                  // reproduire fidèlement le logo de la charte.
                  Icon(Icons.menu_book_rounded,
                      color: Colors.white.withOpacity(0.85), size: 26),
                  const SizedBox(width: 10),
                  Text('Bibliotech',
                      style: GoogleFonts.quicksand(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(color: Colors.white24, height: 1),
              const SizedBox(height: 12),
              _buildNavItem(_ModuleSidebar.home, Icons.home_outlined, 'Home'),
              _buildNavItem(_ModuleSidebar.adherents, Icons.people_alt_outlined,
                  'Adherents'),
              _buildNavItem(
                  _ModuleSidebar.livres, Icons.menu_book_rounded, 'Livres'),
              _buildNavItem(_ModuleSidebar.emprunts, Icons.fact_check_outlined,
                  'Emprunts'),
              _buildNavItem(_ModuleSidebar.tableauDeBord,
                  Icons.bar_chart_rounded, 'Tableau de bord'),
            ],
          ),
        ],
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

  /// Onglet de sidebar : capsule violet clair pour l'onglet actif (cf.
  /// prompt de design §1), texte/icône discrets sinon.
  Widget _buildNavItem(_ModuleSidebar module, IconData icon, String label) {
    final estActif = module == _moduleActif;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _naviguerVersModule(module),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: estActif ? const Color(0xFFEDE9F7) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Icon(icon,
                    color: estActif ? const Color(0xFF3B2470) : Colors.white70,
                    size: 22),
                const SizedBox(width: 12),
                Text(label,
                    style: GoogleFonts.quicksand(
                        color:
                            estActif ? const Color(0xFF3B2470) : Colors.white70,
                        fontWeight:
                            estActif ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 15)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderModule(_ModuleSidebar module) {
    final label = switch (module) {
      _ModuleSidebar.livres => 'Livres',
      _ModuleSidebar.emprunts => 'Emprunts',
      _ModuleSidebar.tableauDeBord => 'Tableau de bord',
      _ => '',
    };
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.hourglass_empty, size: 48, color: Color(0xFFB9AEDD)),
          const SizedBox(height: 16),
          Text('Module "$label" bientôt disponible',
              style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3B2470))),
        ],
      ),
    );
  }

  // --- BARRE DE TITRE ET BARRE D'OUTILS ---

  Widget _buildBarreTitre() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
      color: Colors.white,
      child: Row(
        children: [
          const Spacer(),
          Text('Bibliotech',
              style: GoogleFonts.quicksand(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3B2470))),
          const Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              // Icônes décoratives ; le contrôle réel de la fenêtre
              // nécessite un package dédié (ex. `bitsdojo_window`),
              // hors périmètre de cette page.
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.minimize, color: Color(0xFF7A6FA0), size: 18),
                  SizedBox(width: 18),
                  Icon(Icons.crop_square, color: Color(0xFF7A6FA0), size: 16),
                  SizedBox(width: 18),
                  Icon(Icons.close, color: Color(0xFF7A6FA0), size: 18),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBarreOutils() {
    return Row(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF3F1FA),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFDCD3F0)),
            ),
            child: TextField(
              controller: _searchCtrl,
              // Recherche par nom ou matricule (cf. cahier des charges).
              onChanged: (motCle) => _chargerAdherents(motCle: motCle.trim()),
              style: GoogleFonts.nunito(color: const Color(0xFF3B2470)),
              decoration: InputDecoration(
                hintText: 'Rechercher adhérent...',
                hintStyle: GoogleFonts.nunito(color: const Color(0xFF9C93B8)),
                prefixIcon: const Icon(Icons.search, color: Color(0xFF7C6BC4)),
                border: InputBorder.none,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        ElevatedButton.icon(
          onPressed: _ouvrirFormulaireAjout,
          icon: const Icon(Icons.add, size: 20),
          label: Text('Nouveau',
              style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5E4FA2),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  // --- TABLEAU ---

  /// Répartition des colonnes, partagée entre l'en-tête et chaque
  /// ligne pour garantir un alignement parfait (cf. prompt de design
  /// §3 : Nom, Prénom, Nom Complet, Matricule, Classe, Statut, "...").
  Widget _ligneColonnes({
    required Widget nom,
    required Widget prenom,
    required Widget nomComplet,
    required Widget matricule,
    required Widget classe,
    required Widget statut,
    required Widget actions,
  }) {
    return Row(
      children: [
        Expanded(flex: 2, child: nom),
        Expanded(flex: 2, child: prenom),
        Expanded(flex: 3, child: nomComplet),
        Expanded(flex: 2, child: matricule),
        Expanded(flex: 1, child: classe),
        Expanded(flex: 2, child: statut),
        SizedBox(width: 56, child: Center(child: actions)),
      ],
    );
  }

  Widget _buildEnTeteColonnes() {
    TextStyle style = GoogleFonts.quicksand(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF3B2470),
        fontSize: 14);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Color(0xFFE2DBF1), width: 1.5)),
      ),
      child: _ligneColonnes(
        nom: Text('Nom', style: style),
        prenom: Text('Prénom', style: style),
        nomComplet: Text('Nom Complet', style: style),
        matricule: Text('Matricule', style: style),
        classe: Text('Classe', style: style),
        statut: Text('Statut', style: style),
        actions: const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildTableCard() {
    if (_enChargement) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF5E4FA2)));
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2DBF1)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          if (_adherents.isNotEmpty) _buildEnTeteColonnes(),
          Expanded(
            child: _adherents.isEmpty
                ? _buildEmptyState()
                : _buildListeAdherents(),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 56, color: Color(0xFFB9AEDD)),
          const SizedBox(height: 16),
          Text('Aucun adhérent enregistré',
              style: GoogleFonts.quicksand(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF3B2470))),
          const SizedBox(height: 6),
          Text(
            'Ajoutez votre premier adhérent pour commencer à gérer les emprunts.',
            textAlign: TextAlign.center,
            style: GoogleFonts.nunito(color: const Color(0xFF9C93B8)),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: _ouvrirFormulaireAjout,
            icon: const Icon(Icons.add, size: 20),
            label: Text('Ajouter un adhérent',
                style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E4FA2),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeAdherents() {
    return GestureDetector(
      // Clic en dehors d'une ligne : referme le menu contextuel ouvert.
      onTap: () => setState(() => _menuOuvertPourId = null),
      child: ListView.builder(
        physics: _menuOuvertPourId != null
            ? const NeverScrollableScrollPhysics()
            : null,
        itemCount: _adherents.length,
        itemBuilder: (context, index) => _buildLigneAdherent(_adherents[index]),
      ),
    );
  }

  Widget _buildLigneAdherent(Adherent adherent) {
    final id = adherent.idAdherent;
    final estSurvolee = id != null && _hoveredId == id;
    final estMenuOuvert = id != null && _menuOuvertPourId == id;
    final autreMenuOuvert = _menuOuvertPourId != null && !estMenuOuvert;

    final style =
        GoogleFonts.nunito(color: const Color(0xFF3B2470), fontSize: 15);

    Widget ligne = MouseRegion(
      onEnter: id == null ? null : (_) => setState(() => _hoveredId = id),
      onExit: id == null ? null : (_) => setState(() => _hoveredId = null),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: estMenuOuvert
              ? const Color(0xFFDCD3F0)
              : (estSurvolee ? const Color(0xFFF1EDFA) : Colors.transparent),
          borderRadius: BorderRadius.circular(14),
          boxShadow: estMenuOuvert
              ? [
                  BoxShadow(
                    color: Colors.purple.withOpacity(0.35),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ]
              : (estSurvolee
                  ? [
                      BoxShadow(
                        color: Colors.purple.withOpacity(0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : const []),
        ),
        child: _ligneColonnes(
          nom: Text(adherent.nom, style: style),
          prenom: Text(adherent.prenom, style: style),
          nomComplet: Text(adherent.nomComplet,
              style: style.copyWith(fontWeight: FontWeight.w700)),
          matricule: Text(adherent.numCarte, style: style),
          classe: Text(adherent.classe, style: style),
          statut: _buildBadgeStatut(adherent),
          actions: estMenuOuvert
              ? _buildMenuFlottant(adherent)
              : IconButton(
                  icon: const Icon(Icons.more_horiz, color: Color(0xFF6B5FA8)),
                  onPressed: id == null
                      ? null
                      : () => setState(() => _menuOuvertPourId = id),
                ),
        ),
      ),
    );

    if (autreMenuOuvert) {
      ligne = Opacity(
        opacity: 0.55,
        child: ImageFiltered(
          imageFilter: ui.ImageFilter.blur(sigmaX: 3, sigmaY: 3),
          child: ligne,
        ),
      );
    }

    return ligne;
  }

  /// Conteneur blanc flottant aux coins très arrondis avec ombre douce
  /// (cf. prompt de design §1 - "Menu Contextuel").
  Widget _buildMenuFlottant(Adherent adherent) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF3B2470), size: 19),
            splashRadius: 20,
            onPressed: () => _ouvrirFormulaireEdition(adherent),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Color(0xFFB91C1C), size: 19),
            splashRadius: 20,
            onPressed: () => _confirmerSuppression(adherent),
          ),
        ],
      ),
    );
  }

  /// Badge de statut cliquable (cf. prompt de design §3) : 3 états
  /// calculés dynamiquement à partir des emprunts réels de l'adhérent.
  Widget _buildBadgeStatut(Adherent adherent) {
    final id = adherent.idAdherent;
    final statut = id != null ? _statuts[id] : null;

    late final Color fond;
    late final Color texte;
    late final String label;

    switch (statut) {
      case _StatutAdherent.enRetard:
        fond = const Color(0xFFFCE8E8);
        texte = const Color(0xFFB91C1C);
        label = 'En retard';
        break;
      case _StatutAdherent.enCours:
        fond = const Color(0xFFE3E0FB);
        texte = const Color(0xFF4338CA);
        label = 'En cours';
        break;
      case _StatutAdherent.aucunEmprunt:
      default:
        fond = const Color(0xFFEDE9F7);
        texte = const Color(0xFF7C6BC4);
        label = 'Aucun emprunt';
    }

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => _onStatutTap(adherent, statut),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration:
            BoxDecoration(color: fond, borderRadius: BorderRadius.circular(20)),
        child: Text(
          label,
          style: GoogleFonts.quicksand(
              color: texte, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }

  // --- FORMULAIRE (2 COLONNES, cf. prompt de design §5) ---

  Widget _buildFormulaire() {
    if (_modeFormulaire == ModeFormulaire.masque)
      return const SizedBox.shrink();
    final estEdition = _modeFormulaire == ModeFormulaire.modification;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2DBF1), width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(estEdition ? "Modifier l'adhérent" : 'Nouvel adhérent',
                  style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3B2470))),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: _fermerFormulaire,
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _buildChamp('Nom', _nomCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _buildChamp('Prénom', _prenomCtrl)),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _buildChamp('Matricule', _numCarteCtrl)),
              const SizedBox(width: 16),
              Expanded(child: _buildChamp('Classe', _classeCtrl)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _validerFormulaire,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E4FA2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(estEdition ? 'Modifier' : 'Ajouter',
                  style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChamp(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.quicksand(
                color: const Color(0xFF3B2470), fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          style: GoogleFonts.nunito(fontSize: 16),
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFFCFC6E8), width: 1.5),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFFCFC6E8), width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          ),
        ),
      ],
    );
  }

  // --- ASSEMBLAGE ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                _buildBarreTitre(),
                Expanded(
                  child: _moduleActif == _ModuleSidebar.adherents
                      ? Padding(
                          padding: const EdgeInsets.all(28),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildBarreOutils(),
                              const SizedBox(height: 18),
                              Expanded(child: _buildTableCard()),
                              _buildFormulaire(),
                            ],
                          ),
                        )
                      : _buildPlaceholderModule(_moduleActif),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
