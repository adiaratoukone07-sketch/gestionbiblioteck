import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/adherent_controller.dart';
import '../controllers/auth_controller.dart';
import '../controllers/resultat_operation.dart';
import '../models/adherent.dart';

/// Page "Adhérents" (cf. cahier des charges - module "Gestion des
/// adhérents" : inscription, modification, suppression, recherche et
/// filtrage par nom ou classe).
///
/// Contrairement à la maquette d'origine, cette page ne contient plus
/// de données simulées : elle passe systématiquement par
/// [AdherentController], qui applique RG-01 (unicité du numéro de
/// carte) et RG-05 (interdiction de suppression si emprunt en cours) et
/// s'appuie sur la base SQLite via `AdherentDao`.
class AdherentsPage extends StatefulWidget {
  const AdherentsPage({super.key});

  @override
  State<AdherentsPage> createState() => _AdherentsPageState();
}

class _AdherentsPageState extends State<AdherentsPage> {
  final AdherentController _adherentController = AdherentController();
  final AuthController _authController = AuthController();

  List<Adherent> _adherents = [];
  bool _enChargement = true;

  int? selectedId;
  int? editingId;
  bool isFormVisible = false;

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

  // --- CHARGEMENT DES DONNÉES (remplace la liste simulée) ---

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

  void _resetForm() {
    editingId = null;
    _nomCtrl.clear();
    _prenomCtrl.clear();
    _numCarteCtrl.clear();
    _classeCtrl.clear();
    setState(() {
      isFormVisible = false;
      selectedId = null;
    });
  }

  void _openForm({int? id}) {
    setState(() {
      isFormVisible = true;
      selectedId = null; // Ferme le menu contextuel s'il est ouvert.
    });

    if (id != null) {
      editingId = id;
      final a = _adherents.firstWhere((x) => x.idAdherent == id);
      _nomCtrl.text = a.nom;
      _prenomCtrl.text = a.prenom;
      _numCarteCtrl.text = a.numCarte;
      _classeCtrl.text = a.classe;
    } else {
      editingId = null;
      _nomCtrl.clear();
      _prenomCtrl.clear();
      _numCarteCtrl.clear();
      _classeCtrl.clear();
    }
  }

  // --- ENREGISTREMENT (passe désormais par AdherentController) ---

  Future<void> _saveAdherent() async {
    final nom = _nomCtrl.text.trim();
    final prenom = _prenomCtrl.text.trim();
    final numCarte = _numCarteCtrl.text.trim();
    final classe = _classeCtrl.text.trim();

    if (nom.isEmpty || prenom.isEmpty || numCarte.isEmpty) {
      _showToast('Veuillez remplir Nom, Prénom et Numéro de carte.',
          isError: true);
      return;
    }

    // L'adhérent doit être rattaché à l'utilisateur (bibliothécaire)
    // actuellement connecté (RG-07). Tant que la page de connexion
    // n'est pas branchée, `utilisateurCourant` sera `null` ici — ce
    // garde-fou restera actif une fois `login_page.dart` en place.
    final idUtilisateur = _authController.utilisateurCourant?.idUtilisateur;
    if (idUtilisateur == null) {
      _showToast('Session expirée, veuillez vous reconnecter.',
          isError: true);
      return;
    }

    ResultatOperation resultat;
    if (editingId != null) {
      final adherent = Adherent(
        idAdherent: editingId,
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

    _showToast(editingId != null ? 'Adhérent modifié' : 'Adhérent ajouté');
    _resetForm();
    await _chargerAdherents(motCle: _searchCtrl.text.trim());
  }

  Future<void> _deleteAdherent(int id) async {
    // RG-05 est vérifiée par le contrôleur : la suppression est
    // refusée si l'adhérent a des emprunts en cours.
    final resultat = await _adherentController.supprimer(id);
    _resetForm();

    if (!resultat.succes) {
      _showToast(resultat.messageErreur ?? 'Suppression impossible.',
          isError: true);
      return;
    }

    await _chargerAdherents(motCle: _searchCtrl.text.trim());
    _showToast('Adhérent supprimé');
  }

  // --- WIDGETS DE DESIGN ---

  Widget _buildSidebar() {
    return Container(
      width: 240,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF4C3E87), Color(0xFF3A2D65)],
        ),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.menu_book_rounded,
                    color: Colors.white.withOpacity(0.8), size: 30),
                const SizedBox(width: 10),
                Text('Bibliotech',
                    style: GoogleFonts.quicksand(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          const Divider(color: Colors.white24),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(top: 20),
              children: [
                // Les autres pages (dashboard, livres, prêts,
                // statistiques) seront branchées ici une fois
                // construites — cf. arborescence lib/views/ du cahier
                // des charges §3.2.
                _buildNavItem(Icons.home_outlined, 'Accueil'),
                _buildNavItem(Icons.menu_book_rounded, 'Livres'),
                _buildNavItem(Icons.people_alt_outlined, 'Adhérents',
                    isActive: true),
                _buildNavItem(Icons.swap_horiz, 'Emprunts'),
                _buildNavItem(Icons.bar_chart, 'Tableau de bord'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, {bool isActive = false}) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: isActive
          ? BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            )
          : null,
      child: ListTile(
        leading: Icon(icon, color: Colors.white.withOpacity(0.9), size: 26),
        title: Text(label,
            style: GoogleFonts.quicksand(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 16)),
        onTap: () {},
      ),
    );
  }

  Widget _buildListCard() {
    if (_enChargement) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator(color: Color(0xFF5E4FA2))),
      );
    }

    if (_adherents.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 40),
        decoration: BoxDecoration(
          color: const Color(0xFFE2DBF1),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Center(
          child: Text('Aucun adhérent trouvé',
              style: GoogleFonts.nunito(
                  color: const Color(0xFF9C93B8), fontSize: 16)),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2DBF1),
        borderRadius: BorderRadius.circular(14),
      ),
      clipBehavior: Clip.antiAlias,
      constraints: const BoxConstraints(maxHeight: 340),
      child: ListView.builder(
        itemCount: _adherents.length,
        itemBuilder: (context, index) {
          final a = _adherents[index];
          final isSelected = a.idAdherent == selectedId;
          final distance = selectedId != null
              ? (_adherents.indexWhere((x) => x.idAdherent == selectedId) -
                      index)
                  .abs()
              : 99;

          double opacity = 1.0;
          double blur = 0.0;
          if (!isSelected && selectedId != null) {
            if (distance == 1) {
              opacity = 0.85;
              blur = 0.4;
            } else if (distance == 2) {
              opacity = 0.65;
              blur = 0.8;
            } else if (distance >= 3) {
              opacity = 0.45;
              blur = 1.3;
            }
          }

          Widget ligne = Container(
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF8074B2) : Colors.transparent,
            ),
            child: ListTile(
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              title: Text(a.nomComplet,
                  style: GoogleFonts.nunito(
                      color: isSelected ? Colors.white : const Color(0xFF9C93B8),
                      fontWeight:
                          isSelected ? FontWeight.w700 : FontWeight.w500,
                      fontSize: 17)),
              subtitle: Text('${a.numCarte} · ${a.classe}',
                  style: GoogleFonts.nunito(
                      color: isSelected
                          ? Colors.white70
                          : const Color(0xFF9C93B8),
                      fontSize: 14)),
              trailing: isSelected
                  ? IconButton(
                      icon: const Icon(Icons.more_horiz, color: Colors.white),
                      onPressed: () {
                        _showContextMenu(context, a.idAdherent!);
                      },
                    )
                  : null,
              onTap: () {
                setState(() {
                  selectedId = (selectedId == a.idAdherent)
                      ? null
                      : a.idAdherent;
                });
              },
            ),
          );

          // Le flou n'est appliqué que si nécessaire (évite un widget
          // ImageFiltered inutile pour chaque ligne au repos).
          if (blur > 0) {
            ligne = ImageFiltered(
              imageFilter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
              child: ligne,
            );
          }

          return Opacity(opacity: opacity, child: ligne);
        },
      ),
    );
  }

  void _showContextMenu(BuildContext context, int id) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildMenuButton('Modifier', Icons.edit, const Color(0xFF3B2470),
                  () {
                Navigator.pop(context);
                _openForm(id: id);
              }),
              const SizedBox(width: 20),
              _buildMenuButton(
                  'Supprimer', Icons.delete_outline, const Color(0xFFB91C1C),
                  () {
                Navigator.pop(context);
                _deleteAdherent(id);
              }),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuButton(
      String label, IconData icon, Color color, VoidCallback onTap) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFF3EEFB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label,
            style: GoogleFonts.quicksand(
                color: Colors.grey[700],
                fontWeight: FontWeight.w600,
                fontSize: 13))
      ],
    );
  }

  Widget _buildForm() {
    if (!isFormVisible) return const SizedBox.shrink();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2DBF1), width: 2),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                  editingId != null
                      ? "Modifier l'adhérent"
                      : 'Nouvel adhérent',
                  style: GoogleFonts.quicksand(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF3B2470))),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.grey),
                onPressed: _resetForm,
              ),
            ],
          ),
          const SizedBox(height: 10),
          _buildField('Nom', _nomCtrl),
          _buildField('Prénom', _prenomCtrl),
          _buildField('Numéro de carte', _numCarteCtrl),
          _buildField('Classe', _classeCtrl),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveAdherent,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5E4FA2),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                elevation: 0,
              ),
              child: Text(
                  editingId != null
                      ? 'Enregistrer les modifications'
                      : 'Ajouter',
                  style:
                      GoogleFonts.quicksand(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: TextField(
        controller: controller,
        style: GoogleFonts.nunito(fontSize: 16),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: GoogleFonts.quicksand(
              color: const Color(0xFF3B2470), fontWeight: FontWeight.w600),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.black, width: 1.5),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Colors.black, width: 1.5),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(6),
            borderSide: const BorderSide(color: Color(0xFF7C3AED), width: 2),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          _buildSidebar(),
          Expanded(
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  color: const Color(0xFFF0E8FF),
                  child: Row(
                    children: [
                      const Icon(Icons.people,
                          color: Color(0xFF4C3E87), size: 20),
                      const SizedBox(width: 10),
                      Text('Adhérents',
                          style: GoogleFonts.quicksand(
                              color: const Color(0xFF4C3E87),
                              fontWeight: FontWeight.bold)),
                      const Spacer(),
                      // Icônes décoratives ; le contrôle réel de la
                      // fenêtre (minimiser/agrandir/fermer) nécessite un
                      // package dédié type `bitsdojo_window` pour
                      // Windows — hors périmètre de cette page.
                      const Icon(Icons.minimize, color: Color(0xFF7A6FA0)),
                      const SizedBox(width: 20),
                      const Icon(Icons.crop_square,
                          color: Color(0xFF7A6FA0)),
                      const SizedBox(width: 20),
                      const Icon(Icons.close, color: Color(0xFF7A6FA0)),
                    ],
                  ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: const BoxDecoration(
                                  color: Color(0xFFC7BADE),
                                  shape: BoxShape.circle),
                              child: const Icon(Icons.menu_book,
                                  color: Color(0xFF3B2470), size: 26),
                            ),
                            const SizedBox(width: 14),
                            Text('Bibliotech',
                                style: GoogleFonts.quicksand(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF3B2470))),
                          ],
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: const Color(0xFF837F7F),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: TextField(
                                  controller: _searchCtrl,
                                  // Recherche par nom (cf. cahier des
                                  // charges - "filtrage par nom ou
                                  // classe"), déclenchée via AdherentController.rechercher().
                                  onSubmitted: (motCle) =>
                                      _chargerAdherents(motCle: motCle.trim()),
                                  onChanged: (motCle) =>
                                      _chargerAdherents(motCle: motCle.trim()),
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    hintText: 'Rechercher un adhérent...',
                                    hintStyle:
                                        const TextStyle(color: Color(0xFFE4E1E1)),
                                    prefixIcon:
                                        const Icon(Icons.search, color: Colors.white),
                                    border: InputBorder.none,
                                    contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 14),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            ElevatedButton.icon(
                              onPressed: () => _openForm(id: null),
                              icon: const Icon(Icons.add, size: 20),
                              label: Text('Nouveau',
                                  style: GoogleFonts.quicksand(
                                      fontWeight: FontWeight.bold)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5E4FA2),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24, vertical: 14),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                elevation: 0,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        _buildListCard(),
                        _buildForm(),
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
