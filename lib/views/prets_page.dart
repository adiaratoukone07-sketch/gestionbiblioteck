import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/adherent_controller.dart';
import '../controllers/exemplaire_controller.dart';
import '../controllers/livre_controller.dart';
import '../controllers/pret_controller.dart';

import '../models/livre.dart';
import '../models/pret.dart';
import '../widgets/app_shell.dart';

/// Filtre appliqué à la liste des emprunts.
enum _FiltrePrets { enCours, enRetard, tous }

/// Détails résolus d'un emprunt (le modèle `Pret` ne stocke que des
/// id : `idAdherent`, `idExemplaire`), pour l'affichage.
class _DetailsPret {
  final String nomAdherent;
  final String titreLivre;
  final String codeExemplaire;

  const _DetailsPret({
    required this.nomAdherent,
    required this.titreLivre,
    required this.codeExemplaire,
  });
}

/// Page "Emprunts" (cf. cahier des charges - module "Gestion des
/// emprunts", cœur fonctionnel du système) : enregistrement d'un
/// emprunt, enregistrement d'un retour, consultation des emprunts en
/// cours et des retards.
///
/// Toute la logique métier passe par [PretController], qui applique
/// RG-02 (disponibilité), RG-03 (max 3 emprunts simultanés) et RG-04
/// (durée max 14 jours).
///
/// Contrairement à `adherents_page.dart` / `livres_page.dart`, cette
/// page utilise une liste de cartes plutôt qu'un tableau à colonnes
/// fixes : chaque emprunt combine des informations de deux entités
/// (adhérent + livre/exemplaire) et se lit mieux empilé qu'aligné en
/// colonnes étroites.
class PretsPage extends StatefulWidget {
  const PretsPage({super.key});

  @override
  State<PretsPage> createState() => _PretsPageState();
}

class _PretsPageState extends State<PretsPage> {
  final PretController _pretController = PretController();
  final AdherentController _adherentController = AdherentController();
  final LivreController _livreController = LivreController();
  final ExemplaireController _exemplaireController = ExemplaireController();

  _FiltrePrets _filtre = _FiltrePrets.enCours;
  List<Pret> _prets = [];
  final Map<int, _DetailsPret> _details = {};
  bool _enChargement = true;

  @override
  void initState() {
    super.initState();
    _chargerPrets();
  }

  // --- CHARGEMENT ---

  Future<void> _chargerPrets() async {
    setState(() => _enChargement = true);

    List<Pret> resultats;
    switch (_filtre) {
      case _FiltrePrets.enCours:
        resultats = await _pretController.obtenirEnCours();
        break;
      case _FiltrePrets.enRetard:
        resultats = await _pretController.obtenirEnRetard();
        break;
      case _FiltrePrets.tous:
        resultats = await _pretController.obtenirTous();
        break;
    }

    await _resoudreDetails(resultats);

    if (!mounted) return;
    setState(() {
      _prets = resultats;
      _enChargement = false;
    });
  }

  /// Résout le nom de l'adhérent et le titre du livre pour chaque
  /// emprunt, avec un petit cache pour éviter de refaire la même
  /// requête plusieurs fois dans la liste.
  Future<void> _resoudreDetails(List<Pret> prets) async {
    for (final pret in prets) {
      final id = pret.idEmprunt;
      if (id == null || _details.containsKey(id)) continue;

      final adherent = await _adherentController.obtenirParId(pret.idAdherent);
      final exemplaire =
          await _exemplaireController.obtenirParId(pret.idExemplaire);
      final livre = exemplaire != null
          ? await _livreController.obtenirParId(exemplaire.idLivre)
          : null;

      _details[id] = _DetailsPret(
        nomAdherent: adherent?.nomComplet ?? 'Adhérent inconnu',
        titreLivre: livre?.titre ?? 'Livre inconnu',
        codeExemplaire: exemplaire?.codeExemplaire ?? '—',
      );
    }
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

  Future<void> _enregistrerRetour(Pret pret) async {
    final id = pret.idEmprunt;
    if (id == null) return;
    final resultat = await _pretController.enregistrerRetour(id);
    if (!resultat.succes) {
      _showToast(resultat.messageErreur ?? 'Retour impossible.', isError: true);
      return;
    }
    _showToast('Retour enregistré');
    await _chargerPrets();
  }

  // --- NOUVEL EMPRUNT ---

  Future<void> _ouvrirFormulaireEmprunt() async {
    final adherents = await _adherentController.obtenirTous();
    final livres = await _livreController.obtenirTous();

    // Ne propose que les livres ayant au moins un exemplaire
    // disponible, pour éviter à l'utilisateur de sélectionner un livre
    // et de se heurter systématiquement à RG-02.
    final livresDisponibles = <Livre>[];
    for (final livre in livres) {
      final idLivre = livre.idLivre;
      if (idLivre == null) continue;
      final exemplaires = await _livreController.obtenirExemplaires(idLivre);
      if (exemplaires.any((e) => e.estDisponible)) {
        livresDisponibles.add(livre);
      }
    }

    if (!mounted) return;

    if (adherents.isEmpty) {
      _showToast('Aucun adhérent enregistré — ajoutez-en un d\'abord.',
          isError: true);
      return;
    }
    if (livresDisponibles.isEmpty) {
      _showToast('Aucun exemplaire disponible actuellement.', isError: true);
      return;
    }

    int? adherentSelectionne;
    int? livreSelectionne;

    final confirme = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              title: Text('Nouvel emprunt',
                  style: GoogleFonts.quicksand(fontWeight: FontWeight.bold)),
              content: SizedBox(
                width: 360,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Adhérent',
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: adherentSelectionne,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: adherents
                          .where((a) => a.idAdherent != null)
                          .map((a) => DropdownMenuItem(
                                value: a.idAdherent,
                                child: Text('${a.nomComplet} (${a.numCarte})',
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (valeur) =>
                          setDialogState(() => adherentSelectionne = valeur),
                    ),
                    const SizedBox(height: 16),
                    Text('Livre',
                        style: GoogleFonts.quicksand(
                            fontWeight: FontWeight.w700, fontSize: 13)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<int>(
                      isExpanded: true,
                      initialValue: livreSelectionne,
                      decoration: const InputDecoration(
                        isDense: true,
                        border: OutlineInputBorder(),
                      ),
                      items: livresDisponibles
                          .where((l) => l.idLivre != null)
                          .map((l) => DropdownMenuItem(
                                value: l.idLivre,
                                child: Text(l.titre,
                                    overflow: TextOverflow.ellipsis),
                              ))
                          .toList(),
                      onChanged: (valeur) =>
                          setDialogState(() => livreSelectionne = valeur),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                ElevatedButton(
                  onPressed:
                      adherentSelectionne == null || livreSelectionne == null
                          ? null
                          : () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5E4FA2),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirme != true ||
        adherentSelectionne == null ||
        livreSelectionne == null) {
      return;
    }

    final resultat = await _pretController.emprunter(
      idAdherent: adherentSelectionne!,
      idLivre: livreSelectionne!,
    );

    if (!resultat.succes) {
      _showToast(resultat.messageErreur ?? 'Emprunt impossible.',
          isError: true);
      return;
    }

    _showToast('Emprunt enregistré');
    await _chargerPrets();
  }

  // --- UI ---

  Widget _buildFiltres() {
    Widget chip(_FiltrePrets valeur, String label) {
      final actif = _filtre == valeur;
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: ChoiceChip(
          label: Text(label),
          selected: actif,
          onSelected: (_) {
            setState(() => _filtre = valeur);
            _chargerPrets();
          },
          labelStyle: GoogleFonts.quicksand(
              fontWeight: FontWeight.w700,
              color: actif ? Colors.white : const Color(0xFF3B2470)),
          selectedColor: const Color(0xFF5E4FA2),
          backgroundColor: const Color(0xFFF3F1FA),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20), side: BorderSide.none),
        ),
      );
    }

    return Row(
      children: [
        chip(_FiltrePrets.enCours, 'En cours'),
        chip(_FiltrePrets.enRetard, 'En retard'),
        chip(_FiltrePrets.tous, 'Tous'),
        const Spacer(),
        ElevatedButton.icon(
          onPressed: _ouvrirFormulaireEmprunt,
          icon: const Icon(Icons.add, size: 20),
          label: Text('Nouvel emprunt',
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

  Widget _buildListe() {
    if (_enChargement) {
      return const Center(
          child: CircularProgressIndicator(color: Color(0xFF5E4FA2)));
    }

    if (_prets.isEmpty) {
      final message = switch (_filtre) {
        _FiltrePrets.enCours => 'Aucun emprunt en cours.',
        _FiltrePrets.enRetard => 'Aucun emprunt en retard — tout est à jour.',
        _FiltrePrets.tous => 'Aucun emprunt enregistré pour le moment.',
      };
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.fact_check_outlined,
                size: 48, color: Color(0xFFB9AEDD)),
            const SizedBox(height: 12),
            Text(message,
                style: GoogleFonts.nunito(color: const Color(0xFF9C93B8)),
                textAlign: TextAlign.center),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _prets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildCartePret(_prets[index]),
    );
  }

  Widget _buildCartePret(Pret pret) {
    final details = pret.idEmprunt != null ? _details[pret.idEmprunt] : null;
    final enRetard = pret.estEnRetard;
    final enCours = pret.estEnCours;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFFAF8FD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2DBF1)),
      ),
      child: Row(
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(details?.nomAdherent ?? '…',
                    style: GoogleFonts.quicksand(
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF3B2470))),
                const SizedBox(height: 2),
                Text(
                    '${details?.titreLivre ?? '…'} (${details?.codeExemplaire ?? ''})',
                    style: GoogleFonts.nunito(
                        color: const Color(0xFF9C93B8), fontSize: 13)),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Emprunté le ${_formaterDate(pret.dateEmprunt)}',
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: const Color(0xFF3B2470))),
                Text('Retour prévu le ${_formaterDate(pret.dateRetourPrevue)}',
                    style: GoogleFonts.nunito(
                        fontSize: 13, color: const Color(0xFF3B2470))),
              ],
            ),
          ),
          _buildBadgeStatut(enCours: enCours, enRetard: enRetard),
          const SizedBox(width: 12),
          if (enCours)
            TextButton.icon(
              onPressed: () => _enregistrerRetour(pret),
              icon: const Icon(Icons.assignment_return, size: 18),
              label: const Text('Retour'),
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5E4FA2),
              ),
            )
          else
            Text('Rendu le ${_formaterDate(pret.dateRetourEffective!)}',
                style: GoogleFonts.nunito(
                    fontSize: 12, color: const Color(0xFF9C93B8))),
        ],
      ),
    );
  }

  Widget _buildBadgeStatut({required bool enCours, required bool enRetard}) {
    final Color fond;
    final Color texte;
    final String label;
    if (!enCours) {
      fond = const Color(0xFFEDF7EE);
      texte = const Color(0xFF2E7D32);
      label = 'Rendu';
    } else if (enRetard) {
      fond = const Color(0xFFFCE8E8);
      texte = const Color(0xFFB91C1C);
      label = 'En retard';
    } else {
      fond = const Color(0xFFE3E0FB);
      texte = const Color(0xFF4338CA);
      label = 'En cours';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration:
          BoxDecoration(color: fond, borderRadius: BorderRadius.circular(20)),
      child: Text(label,
          style: GoogleFonts.quicksand(
              color: texte, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }

  String _formaterDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return AppShell(
      moduleActif: ModuleSidebar.emprunts,
      titre: 'Emprunts',
      enfant: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildFiltres(),
            const SizedBox(height: 16),
            Expanded(child: _buildListe()),
          ],
        ),
      ),
    );
  }
}
