import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/auth_controller.dart';
import '../controllers/livre_controller.dart';

import '../models/livre.dart';
import '../widgets/app_shell.dart';

/// Les 3 états du formulaire bas de page (mêmes principes que sur
/// `adherents_page.dart`).
enum _ModeFormulaireLivre { masque, ajout, modification }

/// Largeur fixe de la colonne d'actions, partagée entre l'en-tête et
/// chaque ligne (cf. le correctif de débordement appliqué sur
/// `adherents_page.dart`).
const double _largeurColonneActionsLivre = 96;

/// Répartition des colonnes du tableau (Titre, Auteur, Genre, ISBN,
/// Disponibilité, actions).
Widget _construireLigneColonnesLivre({
  required Widget titre,
  required Widget auteur,
  required Widget genre,
  required Widget isbn,
  required Widget disponibilite,
  required Widget actions,
}) {
  return Row(
    children: [
      Expanded(flex: 3, child: titre),
      Expanded(flex: 2, child: auteur),
      Expanded(flex: 2, child: genre),
      Expanded(flex: 2, child: isbn),
      Expanded(flex: 2, child: disponibilite),
      SizedBox(
          width: _largeurColonneActionsLivre, child: Center(child: actions)),
    ],
  );
}

/// Page "Livres" (cf. cahier des charges - module "Gestion du
/// catalogue des livres") : ajout, modification, suppression,
/// recherche multicritère (titre, auteur, ISBN, genre), affichage de
/// la disponibilité des exemplaires.
///
/// Toute la logique métier passe par [LivreController], qui applique
/// RG-06 et génère automatiquement les exemplaires à la création.
/// Construite en suivant les mêmes patterns que `adherents_page.dart`
/// (survol sans clignotement via widget de ligne dédié, distinction
/// "recherche sans résultat" vs "catalogue vide", formulaire compact).
class LivresPage extends StatefulWidget {
  const LivresPage({super.key});

  @override
  State<LivresPage> createState() => _LivresPageState();
}

class _LivresPageState extends State<LivresPage> {
  final LivreController _livreController = LivreController();
  final AuthController _authController = AuthController();

  List<Livre> _livres = [];

  /// Pour chaque livre : (nombre d'exemplaires disponibles, total).
  Map<int, (int, int)> _disponibilites = {};

  bool _enChargement = true;
  bool _baseVide = true;

  int? _menuOuvertPourId;

  _ModeFormulaireLivre _modeFormulaire = _ModeFormulaireLivre.masque;
  int? _idEnEdition;

  final TextEditingController _titreCtrl = TextEditingController();
  final TextEditingController _auteurCtrl = TextEditingController();
  final TextEditingController _isbnCtrl = TextEditingController();
  final TextEditingController _genreCtrl = TextEditingController();
  final TextEditingController _nombreExemplairesCtrl = TextEditingController();
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _chargerLivres();
  }

  @override
  void dispose() {
    _titreCtrl.dispose();
    _auteurCtrl.dispose();
    _isbnCtrl.dispose();
    _genreCtrl.dispose();
    _nombreExemplairesCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // --- CHARGEMENT ---

  Future<void> _chargerLivres({String? motCle}) async {
    setState(() => _enChargement = true);
    final filtre = motCle != null && motCle.isNotEmpty;
    final resultats = filtre
        ? await _livreController.rechercher(motCle)
        : await _livreController.obtenirTous();
    if (!mounted) return;
    setState(() {
      _livres = resultats;
      _enChargement = false;
      if (!filtre) _baseVide = resultats.isEmpty;
    });
    await _chargerDisponibilites();
  }

  Future<void> _chargerDisponibilites() async {
    final Map<int, (int, int)> disponibilites = {};
    for (final livre in _livres) {
      final id = livre.idLivre;
      if (id == null) continue;
      final exemplaires = await _livreController.obtenirExemplaires(id);
      final disponibles =
          exemplaires.where((exemplaire) => exemplaire.estDisponible).length;
      disponibilites[id] = (disponibles, exemplaires.length);
    }
    if (!mounted) return;
    setState(() => _disponibilites = disponibilites);
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

  // --- FORMULAIRE ---

  void _ouvrirFormulaireAjout() {
    setState(() {
      _modeFormulaire = _ModeFormulaireLivre.ajout;
      _idEnEdition = null;
      _menuOuvertPourId = null;
      _titreCtrl.clear();
      _auteurCtrl.clear();
      _isbnCtrl.clear();
      _genreCtrl.clear();
      _nombreExemplairesCtrl.text = '1';
    });
  }

  void _ouvrirFormulaireEdition(Livre livre) {
    setState(() {
      _modeFormulaire = _ModeFormulaireLivre.modification;
      _idEnEdition = livre.idLivre;
      _menuOuvertPourId = null;
      _titreCtrl.text = livre.titre;
      _auteurCtrl.text = livre.auteur;
      _isbnCtrl.text = livre.isbn;
      _genreCtrl.text = livre.genre;
      _nombreExemplairesCtrl.text = livre.nombreExemplaires.toString();
    });
  }

  void _fermerFormulaire() {
    setState(() {
      _modeFormulaire = _ModeFormulaireLivre.masque;
      _idEnEdition = null;
    });
  }

  Future<void> _validerFormulaire() async {
    final titre = _titreCtrl.text.trim();
    final auteur = _auteurCtrl.text.trim();
    final isbn = _isbnCtrl.text.trim();
    final genre = _genreCtrl.text.trim();

    if (titre.isEmpty || auteur.isEmpty || isbn.isEmpty) {
      _showToast('Veuillez remplir Titre, Auteur et ISBN.', isError: true);
      return;
    }

    final idUtilisateur = _authController.utilisateurCourant?.idUtilisateur;
    if (idUtilisateur == null) {
      _showToast('Session expirée, veuillez vous reconnecter.', isError: true);
      return;
    }

    if (_modeFormulaire == _ModeFormulaireLivre.modification &&
        _idEnEdition != null) {
      // La modification ne touche pas au nombre d'exemplaires (cf.
      // LivreController.modifier) : uniquement les informations
      // descriptives de l'ouvrage.
      final livreExistant =
          _livres.firstWhere((l) => l.idLivre == _idEnEdition);
      final livre = livreExistant.copyWith(
        titre: titre,
        auteur: auteur,
        isbn: isbn,
        genre: genre,
      );
      final resultat = await _livreController.modifier(livre);
      if (!resultat.succes) {
        _showToast(resultat.messageErreur ?? 'Une erreur est survenue.',
            isError: true);
        return;
      }
      _showToast('Livre modifié');
    } else {
      final nombreExemplaires =
          int.tryParse(_nombreExemplairesCtrl.text.trim()) ?? 0;
      final livre = Livre(
        titre: titre,
        auteur: auteur,
        isbn: isbn,
        genre: genre,
        nombreExemplaires: nombreExemplaires,
        idUtilisateur: idUtilisateur,
      );
      final resultat = await _livreController.ajouter(livre, idUtilisateur);
      if (!resultat.succes) {
        _showToast(resultat.messageErreur ?? 'Une erreur est survenue.',
            isError: true);
        return;
      }
      _showToast('Livre ajouté');
    }

    _fermerFormulaire();
    await _chargerLivres(motCle: _searchCtrl.text.trim());
  }

  Future<void> _confirmerSuppression(Livre livre) async {
    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text('Supprimer ce livre ?',
            style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
        content: Text('Cette action est définitive pour « ${livre.titre} ».',
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
    final id = livre.idLivre;
    if (id == null) return;

    // RG-06 est vérifiée par le contrôleur : suppression refusée si un
    // exemplaire du livre est actuellement emprunté.
    final resultat = await _livreController.supprimer(id);
    setState(() => _menuOuvertPourId = null);

    if (!resultat.succes) {
      _showToast(resultat.messageErreur ?? 'Suppression impossible.',
          isError: true);
      return;
    }

    await _chargerLivres(motCle: _searchCtrl.text.trim());
    _showToast('Livre supprimé');
  }

  // --- BARRE D'OUTILS ---

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
              onChanged: (motCle) => _chargerLivres(motCle: motCle.trim()),
              style: GoogleFonts.nunito(color: const Color(0xFF3B2470)),
              decoration: InputDecoration(
                hintText: 'Rechercher un livre (titre, auteur, ISBN, genre)...',
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

  Widget _buildEnTeteColonnes() {
    final style = GoogleFonts.quicksand(
        fontWeight: FontWeight.w700,
        color: const Color(0xFF3B2470),
        fontSize: 14);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: const BoxDecoration(
        border:
            Border(bottom: BorderSide(color: Color(0xFFE2DBF1), width: 1.5)),
      ),
      child: _construireLigneColonnesLivre(
        titre: Text('Titre', style: style),
        auteur: Text('Auteur', style: style),
        genre: Text('Genre', style: style),
        isbn: Text('ISBN', style: style),
        disponibilite: Text('Disponibilité', style: style),
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
          if (_livres.isNotEmpty) _buildEnTeteColonnes(),
          Expanded(
            child: _livres.isEmpty ? _buildEmptyState() : _buildListeLivres(),
          ),
        ],
      ),
    );
  }

  /// Mêmes 3 cas que sur `adherents_page.dart` : formulaire déjà
  /// ouvert / recherche sans résultat / catalogue réellement vide.
  Widget _buildEmptyState() {
    final rechercheActive = _searchCtrl.text.trim().isNotEmpty;
    final formulaireOuvert = _modeFormulaire != _ModeFormulaireLivre.masque;

    if (formulaireOuvert) {
      return Center(
        child: Text(
          rechercheActive
              ? 'Aucun résultat pour cette recherche.'
              : 'Aucun livre au catalogue pour le moment.',
          style: GoogleFonts.nunito(color: const Color(0xFF9C93B8)),
          textAlign: TextAlign.center,
        ),
      );
    }

    if (rechercheActive && !_baseVide) {
      return Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.search_off, size: 44, color: Color(0xFFB9AEDD)),
              const SizedBox(height: 12),
              Text('Aucun résultat pour « ${_searchCtrl.text.trim()} »',
                  style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3B2470)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                'Il existe des livres au catalogue, mais aucun ne correspond à cette recherche.',
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(color: const Color(0xFF9C93B8)),
              ),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: () {
                  _searchCtrl.clear();
                  _chargerLivres();
                },
                icon: const Icon(Icons.close, size: 18),
                label: const Text('Réinitialiser la recherche'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.menu_book_outlined,
                size: 48, color: Color(0xFFB9AEDD)),
            const SizedBox(height: 12),
            Text('Aucun livre au catalogue',
                style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3B2470))),
            const SizedBox(height: 6),
            Text(
              'Ajoutez votre premier ouvrage pour commencer à gérer le catalogue.',
              textAlign: TextAlign.center,
              style: GoogleFonts.nunito(color: const Color(0xFF9C93B8)),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _ouvrirFormulaireAjout,
              icon: const Icon(Icons.add, size: 20),
              label: Text('Ajouter un livre',
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E4FA2),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListeLivres() {
    return GestureDetector(
      onTap: () => setState(() => _menuOuvertPourId = null),
      child: ListView.separated(
        physics: _menuOuvertPourId != null
            ? const NeverScrollableScrollPhysics()
            : null,
        itemCount: _livres.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFE9E3F6),
          indent: 12,
          endIndent: 12,
        ),
        itemBuilder: (context, index) {
          final livre = _livres[index];
          final id = livre.idLivre;
          final menuOuvert = id != null && _menuOuvertPourId == id;
          final autreMenuOuvert = _menuOuvertPourId != null && !menuOuvert;

          return _LigneLivreWidget(
            key: ValueKey(id ?? livre.isbn),
            livre: livre,
            disponibilite: id != null ? _disponibilites[id] : null,
            menuOuvert: menuOuvert,
            autreMenuOuvert: autreMenuOuvert,
            onToggleMenu: id == null
                ? null
                : () =>
                    setState(() => _menuOuvertPourId = menuOuvert ? null : id),
            onEdit: () => _ouvrirFormulaireEdition(livre),
            onDelete: () => _confirmerSuppression(livre),
          );
        },
      ),
    );
  }

  // --- FORMULAIRE ---

  Widget _buildFormulaire() {
    if (_modeFormulaire == _ModeFormulaireLivre.masque) {
      return const SizedBox.shrink();
    }
    final estEdition = _modeFormulaire == _ModeFormulaireLivre.modification;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(top: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2DBF1), width: 1.5),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(estEdition ? 'Modifier le livre' : 'Nouveau livre',
                  style: GoogleFonts.quicksand(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3B2470))),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
                onPressed: _fermerFormulaire,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildChamp('Titre', _titreCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _buildChamp('Auteur', _auteurCtrl)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildChamp('ISBN', _isbnCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _buildChamp('Genre', _genreCtrl)),
            ],
          ),
          if (!estEdition) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: 160,
              child: _buildChamp(
                "Nombre d'exemplaires",
                _nombreExemplairesCtrl,
                clavierNumerique: true,
              ),
            ),
          ] else ...[
            const SizedBox(height: 10),
            Text(
              '${_nombreExemplairesCtrl.text} exemplaire(s) au catalogue — la modification ne change pas ce nombre.',
              style: GoogleFonts.nunito(
                  fontSize: 12, color: const Color(0xFF9C93B8)),
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: _validerFormulaire,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E4FA2),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: Text(estEdition ? 'Modifier' : 'Ajouter',
                  style: GoogleFonts.quicksand(
                      fontWeight: FontWeight.w700, fontSize: 14)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChamp(String label, TextEditingController controller,
      {bool clavierNumerique = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.quicksand(
                color: const Color(0xFF3B2470),
                fontWeight: FontWeight.w700,
                fontSize: 13)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          keyboardType:
              clavierNumerique ? TextInputType.number : TextInputType.text,
          style: GoogleFonts.nunito(fontSize: 14),
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFFCFC6E8), width: 1.2),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFFCFC6E8), width: 1.2),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide:
                  const BorderSide(color: Color(0xFF7C3AED), width: 1.6),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      moduleActif: ModuleSidebar.livres,
      titre: 'Livres',
      enfant: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildBarreOutils(),
            const SizedBox(height: 16),
            Expanded(child: _buildTableCard()),
            _buildFormulaire(),
          ],
        ),
      ),
    );
  }
}

/// Une ligne du tableau, extraite en widget à état propre — même
/// correctif que `_LigneAdherentWidget` sur `adherents_page.dart` pour
/// éviter le clignotement au survol (état local, clé stable, marge
/// fixe).
class _LigneLivreWidget extends StatefulWidget {
  final Livre livre;
  final (int, int)? disponibilite;
  final bool menuOuvert;
  final bool autreMenuOuvert;
  final VoidCallback? onToggleMenu;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _LigneLivreWidget({
    super.key,
    required this.livre,
    required this.disponibilite,
    required this.menuOuvert,
    required this.autreMenuOuvert,
    required this.onToggleMenu,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  State<_LigneLivreWidget> createState() => _LigneLivreWidgetState();
}

class _LigneLivreWidgetState extends State<_LigneLivreWidget> {
  bool _survolee = false;

  @override
  Widget build(BuildContext context) {
    final style =
        GoogleFonts.nunito(color: const Color(0xFF3B2470), fontSize: 15);
    final livre = widget.livre;

    Widget ligne = MouseRegion(
      onEnter: (_) => setState(() => _survolee = true),
      onExit: (_) => setState(() => _survolee = false),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: widget.menuOuvert
              ? const Color(0xFFDCD3F0)
              : (_survolee ? const Color(0xFFF1EDFA) : Colors.transparent),
          borderRadius: BorderRadius.circular(14),
          boxShadow: widget.menuOuvert
              ? [
                  BoxShadow(
                    color: Colors.purple.withValues(alpha: 0.35),
                    blurRadius: 15,
                    spreadRadius: 1,
                    offset: const Offset(0, 6),
                  ),
                ]
              : (_survolee
                  ? [
                      BoxShadow(
                        color: Colors.purple.withValues(alpha: 0.12),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ]
                  : const []),
        ),
        child: _construireLigneColonnesLivre(
          titre: Text(livre.titre,
              style: style.copyWith(fontWeight: FontWeight.w700)),
          auteur: Text(livre.auteur, style: style),
          genre: Text(livre.genre, style: style),
          isbn: Text(livre.isbn, style: style),
          disponibilite: _buildBadgeDisponibilite(),
          actions: widget.menuOuvert
              ? _buildMenuFlottant()
              : IconButton(
                  icon: const Icon(Icons.more_horiz, color: Color(0xFF6B5FA8)),
                  onPressed: widget.onToggleMenu,
                ),
        ),
      ),
    );

    if (widget.autreMenuOuvert) {
      ligne = Opacity(opacity: 0.55, child: ligne);
    }

    return ligne;
  }

  Widget _buildMenuFlottant() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.12),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.edit, color: Color(0xFF3B2470), size: 17),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            splashRadius: 18,
            onPressed: widget.onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Color(0xFFB91C1C), size: 17),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            splashRadius: 18,
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeDisponibilite() {
    final disponibilite = widget.disponibilite;
    if (disponibilite == null) {
      return Text('—',
          style: GoogleFonts.nunito(color: const Color(0xFF9C93B8)));
    }
    final (disponibles, total) = disponibilite;

    final Color fond;
    final Color texte;
    if (total == 0) {
      fond = const Color(0xFFF3F1FA);
      texte = const Color(0xFF9C93B8);
    } else if (disponibles == 0) {
      fond = const Color(0xFFFCE8E8);
      texte = const Color(0xFFB91C1C);
    } else {
      fond = const Color(0xFFEDE9F7);
      texte = const Color(0xFF7C6BC4);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: fond, borderRadius: BorderRadius.circular(20)),
      child: Text(
        total == 0 ? 'Aucun exemplaire' : '$disponibles / $total disponibles',
        style: GoogleFonts.quicksand(
            color: texte, fontWeight: FontWeight.w700, fontSize: 12),
      ),
    );
  }
}
