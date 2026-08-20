import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/adherent_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/pret_controller.dart';
import '../controllers/resultat_operation.dart';
import '../models/adherent.dart';
import '../models/pret.dart';
import '../widgets/custom_title_bar.dart';
import 'accueil_page.dart';
import 'dashboard_page.dart';
import 'livres_page.dart';
import 'prets_page.dart';

/// Modules accessibles depuis la sidebar. `adherents` est le module de
/// cette page ; les autres ne sont pas encore construits (cf.
/// `dashboard_page.dart`, `livres_page.dart`, `prets_page.dart` à
/// venir), donc leur contenu est un simple espace réservé tant qu'ils
/// n'existent pas — la sidebar bascule dessus sans recharger l'appli.
enum _ModuleSidebar { home, adherents, livres, emprunts, tableauDeBord }

/// Les 3 états du formulaire bas de page.
enum ModeFormulaire { masque, ajout, modification }

/// Statut d'emprunt affiché dans la colonne "Statut", calculé à partir
/// de l'historique réel des emprunts via [PretController].
enum _StatutAdherent { aucunEmprunt, enCours, enRetard }

/// Position du mot "Bibliotech" dans la barre de titre de cette page.
/// Change cette constante pour le repositionner (ex. `Alignment.centerLeft`).
const Alignment positionTitreAdherents = Alignment.center;

/// Largeur fixe de la colonne d'actions (bouton "..." ou menu
/// crayon/poubelle), partagée entre l'en-tête et chaque ligne. Assez
/// large pour contenir les 2 icônes du menu flottant sans déborder
/// (l'ancienne largeur de 56px provoquait un "RIGHT OVERFLOWED").
const double _largeurColonneActions = 96;

/// Répartition des colonnes du tableau (Nom, Prénom, Nom Complet,
/// Matricule, Classe, Statut, actions), partagée entre l'en-tête et
/// chaque ligne pour garantir un alignement parfait.
Widget construireLigneColonnes({
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
      SizedBox(width: _largeurColonneActions, child: Center(child: actions)),
    ],
  );
}

/// Page "Adhérents" (cf. cahier des charges - module "Gestion des
/// adhérents").
///
/// Toute la logique métier passe par [AdherentController] (RG-01,
/// RG-05) et [PretController] (statut d'emprunt de chaque adhérent).
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

  /// `true` si la base ne contient réellement aucun adhérent (calculé
  /// uniquement lors des chargements sans filtre de recherche) — sert
  /// à distinguer "base vide" de "recherche sans résultat", qui ne
  /// doivent pas afficher le même message.
  bool _baseVide = true;

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
    final filtre = motCle != null && motCle.isNotEmpty;
    final resultats = filtre
        ? await _adherentController.rechercher(nom: motCle)
        : await _adherentController.obtenirTous();
    if (!mounted) return;
    setState(() {
      _adherents = resultats;
      _enChargement = false;
      // Ne recalculer "base vide" que lors d'un chargement sans
      // filtre, pour ne pas confondre "aucun résultat pour cette
      // recherche" avec "aucun adhérent en base" (cf. bug signalé).
      if (!filtre) _baseVide = resultats.isEmpty;
    });
    await _chargerStatuts();
  }

  /// Calcule le statut d'emprunt de chaque adhérent affiché, à partir
  /// de son historique réel : "En retard" prime sur "En cours", qui
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

  /// Titre de la barre affiché en haut de la zone de contenu, déduit
  /// automatiquement du module actif (corrige le titre figé sur
  /// "Adhérents" quel que soit le module sélectionné).
  String get _titreModuleActif {
    switch (_moduleActif) {
      case _ModuleSidebar.adherents:
        return 'Adhérents';
      case _ModuleSidebar.livres:
        return 'Livres';
      case _ModuleSidebar.emprunts:
        return 'Emprunts';
      case _ModuleSidebar.tableauDeBord:
        return 'Tableau de bord';
      case _ModuleSidebar.home:
        return '';
    }
  }
  // --- NAVIGATION SIDEBAR ---

  void _naviguerVersModule(_ModuleSidebar module) {
    switch (module) {
      case _ModuleSidebar.home:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AccueilPage()),
        );
        break;
      case _ModuleSidebar.adherents:
        // Déjà sur cette page.
        break;
      case _ModuleSidebar.livres:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LivresPage()),
        );
        break;
      case _ModuleSidebar.emprunts:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const PretsPage()),
        );
        break;
      case _ModuleSidebar.tableauDeBord:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const DashboardPage()),
        );
        break;
    }
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
            style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Text(
            'Cette action est définitive pour ${adherent.nomComplet}.',
            style: GoogleFonts.roboto()),
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
                  Image.asset('assets/icons/mon_logo.png',
                      fit: BoxFit.cover, width: 26, height: 26),
                  const SizedBox(width: 10),
                  Text('Bibliotech',
                      style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(
                  color: Color.fromARGB(155, 253, 252, 252), height: 1),
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

  Widget _buildNavItem(_ModuleSidebar module, IconData icon, String label) {
    final estActif = module == _moduleActif;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          hoverColor: const Color.fromARGB(147, 233, 231, 238),
          onTap: () => _naviguerVersModule(module),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 12,
            ),
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
                    style: GoogleFonts.inter(
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
              onChanged: (motCle) => _chargerAdherents(motCle: motCle.trim()),
              style: GoogleFonts.roboto(color: const Color(0xFF3B2470)),
              decoration: InputDecoration(
                hintText: 'Rechercher un adhérent...',
                hintStyle: GoogleFonts.inter(color: const Color(0xFF9C93B8)),
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
      child: construireLigneColonnes(
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

  /// État vide, avec 3 cas distincts :
  /// 1. Le formulaire est déjà ouvert (ajout/modification) : on
  ///    n'affiche plus le gros bouton "+ Ajouter" (il ferait doublon
  ///    avec le formulaire déjà visible) — juste un texte compact,
  ///    dans un `SingleChildScrollView` pour ne jamais déborder même
  ///    si la carte est très réduite (corrige le "BOTTOM OVERFLOWED").
  /// 2. Une recherche est active et ne donne aucun résultat, alors
  ///    qu'il existe bien des adhérents en base : message dédié, pas
  ///    "aucun adhérent enregistré" qui est trompeur.
  /// 3. La base est réellement vide : état vide complet avec bouton
  ///    d'action rapide.
  Widget _buildEmptyState() {
    final rechercheActive = _searchCtrl.text.trim().isNotEmpty;
    final formulaireOuvert = _modeFormulaire != ModeFormulaire.masque;

    if (formulaireOuvert) {
      return Center(
        child: Text(
          rechercheActive
              ? 'Aucun résultat pour cette recherche.'
              : 'Aucun adhérent enregistré pour le moment.',
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
                  style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3B2470)),
                  textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text(
                'Il existe des adhérents enregistrés, mais aucun ne correspond à cette recherche.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: const Color(0xFF9C93B8)),
              ),
              const SizedBox(height: 14),
              TextButton.icon(
                onPressed: () {
                  _searchCtrl.clear();
                  _chargerAdherents();
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
            const Icon(Icons.people_outline,
                size: 48, color: Color(0xFFB9AEDD)),
            const SizedBox(height: 12),
            Text('Aucun adhérent enregistré',
                style: GoogleFonts.quicksand(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3B2470))),
            const SizedBox(height: 6),
            Text(
              'Ajoutez votre premier adhérent pour commencer à gérer les emprunts.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: const Color(0xFF9C93B8)),
            ),
            const SizedBox(height: 14),
            ElevatedButton.icon(
              onPressed: _ouvrirFormulaireAjout,
              icon: const Icon(Icons.add, size: 20),
              label: Text('Ajouter un adhérent',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
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

  /// Liste avec lignes de séparation (cf. retour "ça semble nager"
  /// sans séparateur) et défilement désactivé tant qu'un menu
  /// contextuel est ouvert.
  Widget _buildListeAdherents() {
    return GestureDetector(
      onTap: () => setState(() => _menuOuvertPourId = null),
      child: ListView.separated(
        physics: _menuOuvertPourId != null
            ? const NeverScrollableScrollPhysics()
            : null,
        itemCount: _adherents.length,
        separatorBuilder: (context, index) => const Divider(
          height: 1,
          thickness: 1,
          color: Color(0xFFE9E3F6),
          indent: 12,
          endIndent: 12,
        ),
        itemBuilder: (context, index) {
          final adherent = _adherents[index];
          final id = adherent.idAdherent;
          final menuOuvert = id != null && _menuOuvertPourId == id;
          final autreMenuOuvert = _menuOuvertPourId != null && !menuOuvert;

          return _LigneAdherentWidget(
            // Clé stable : évite que Flutter recrée le widget (et son
            // MouseRegion) à chaque reconstruction de la liste, ce qui
            // provoquait le clignotement au survol.
            key: ValueKey(id ?? adherent.numCarte),
            adherent: adherent,
            statut: id != null ? _statuts[id] : null,
            menuOuvert: menuOuvert,
            autreMenuOuvert: autreMenuOuvert,
            onToggleMenu: id == null
                ? null
                : () =>
                    setState(() => _menuOuvertPourId = menuOuvert ? null : id),
            onEdit: () => _ouvrirFormulaireEdition(adherent),
            onDelete: () => _confirmerSuppression(adherent),
            onStatutTap: (statut) => _onStatutTap(adherent, statut),
          );
        },
      ),
    );
  }

  // --- FORMULAIRE (allégé : champs et bouton plus compacts) ---

  Widget _buildFormulaire() {
    if (_modeFormulaire == ModeFormulaire.masque) {
      return const SizedBox.shrink();
    }
    final estEdition = _modeFormulaire == ModeFormulaire.modification;

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
              Text(estEdition ? "Modifier l'adhérent" : 'Nouvel adhérent',
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
              Expanded(child: _buildChamp('Nom', _nomCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _buildChamp('Prénom', _prenomCtrl)),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(child: _buildChamp('Matricule', _numCarteCtrl)),
              const SizedBox(width: 12),
              Expanded(child: _buildChamp('Classe', _classeCtrl)),
            ],
          ),
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

  Widget _buildChamp(String label, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: GoogleFonts.inter(
                color: const Color(0xFF3B2470),
                fontWeight: FontWeight.w700,
                fontSize: 13)),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(fontSize: 14),
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
                // Barre de titre personnalisée (cf.
                // lib/widgets/custom_title_bar.dart) à la place de la
                // barre Windows par défaut.
                BarreTitrePersonnalisee(
                  titre: _titreModuleActif,
                  alignementTitre: positionTitreAdherents,
                ),
                Expanded(
                  child: Padding(
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Une ligne du tableau, extraite en widget à état propre : son survol
/// (`MouseRegion`) est géré localement plutôt que remonté dans
/// `_AdherentsPageState`. C'est ce qui corrige le clignotement signalé
/// au survol — avant, chaque mouvement de souris déclenchait un
/// `setState` sur toute la page, qui reconstruisait `ListView.builder`
/// (donc recréait chaque ligne), ce qui pouvait réinitialiser la zone
/// de détection du survol en boucle. Ici, seule la ligne survolée se
/// reconstruit, et sa marge ne change jamais (seule la couleur/l'ombre
/// changent), ce qui stabilise la zone de détection.
class _LigneAdherentWidget extends StatefulWidget {
  final Adherent adherent;
  final _StatutAdherent? statut;
  final bool menuOuvert;
  final bool autreMenuOuvert;
  final VoidCallback? onToggleMenu;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final void Function(_StatutAdherent?) onStatutTap;

  const _LigneAdherentWidget({
    super.key,
    required this.adherent,
    required this.statut,
    required this.menuOuvert,
    required this.autreMenuOuvert,
    required this.onToggleMenu,
    required this.onEdit,
    required this.onDelete,
    required this.onStatutTap,
  });

  @override
  State<_LigneAdherentWidget> createState() => _LigneAdherentWidgetState();
}

class _LigneAdherentWidgetState extends State<_LigneAdherentWidget> {
  bool _survolee = false;

  @override
  Widget build(BuildContext context) {
    final style =
        GoogleFonts.inter(color: const Color(0xFF3B2470), fontSize: 15);
    final adherent = widget.adherent;

    Widget ligne = MouseRegion(
      onEnter: (_) => setState(() => _survolee = true),
      onExit: (_) => setState(() => _survolee = false),
      child: Container(
        // Marge et padding FIXES, qui ne changent jamais avec l'état :
        // c'est ce qui évite que la zone de détection du survol se
        // déplace (et donc le clignotement).
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
        child: construireLigneColonnes(
          nom: Text(adherent.nom, style: style),
          prenom: Text(adherent.prenom, style: style),
          nomComplet: Text(adherent.nomComplet,
              style: style.copyWith(fontWeight: FontWeight.w700)),
          matricule: Text(adherent.numCarte, style: style),
          classe: Text(adherent.classe, style: style),
          statut: _buildBadgeStatut(),
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
      // Le flou du reste de la liste reste au niveau de la page (pas
      // ici) pour rester léger ; ici on se contente d'estomper visuellement.
      ligne = Opacity(opacity: 0.55, child: ligne);
    }

    return ligne;
  }

  /// Conteneur blanc flottant aux coins très arrondis avec ombre douce.
  /// Icônes compactes (taille + contraintes réduites) pour tenir dans
  /// la largeur de colonne sans déborder (corrige le "RIGHT OVERFLOWED
  /// BY 36 PIXELS").
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
            icon: const Icon(Icons.edit,
                color: Color.fromARGB(255, 93, 56, 179), size: 17),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            splashRadius: 18,
            onPressed: widget.onEdit,
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline,
                color: Color.fromARGB(255, 240, 42, 42), size: 17),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            splashRadius: 18,
            onPressed: widget.onDelete,
          ),
        ],
      ),
    );
  }

  Widget _buildBadgeStatut() {
    late final Color fond;
    late final Color texte;
    late final String label;

    switch (widget.statut) {
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
      onTap: () => widget.onStatutTap(widget.statut),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration:
            BoxDecoration(color: fond, borderRadius: BorderRadius.circular(20)),
        child: Text(
          label,
          style: GoogleFonts.inter(
              color: texte, fontWeight: FontWeight.w700, fontSize: 12),
        ),
      ),
    );
  }
}
