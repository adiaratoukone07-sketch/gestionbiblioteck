/// Entité EMPRUNTER (table EMPRUNT en MLD, fichier `pret.dart` selon
/// l'arborescence du cahier des charges §3.2).
///
/// Nouveauté de la version révisée du MCD : EMPRUNTER n'est plus une
/// simple association porteuse d'attributs entre ADHERENT et
/// EXEMPLAIRE, mais une entité à part entière, identifiée par
/// [idEmprunt], reliée à ADHERENT via EFFECTUE et à EXEMPLAIRE via
/// CONCERNE (cardinalités 1,1 côté EMPRUNTER).
///
/// Table MLD : EMPRUNT (id_emprunt, date_emprunt, date_retour_prevue,
/// date_retour_effective, #id_adherent, #id_exemplaire)
class Pret {
  final int? idEmprunt;
  final DateTime dateEmprunt;
  final DateTime dateRetourPrevue;
  final DateTime? dateRetourEffective;
  final int idAdherent;
  final int idExemplaire;

  Pret({
    this.idEmprunt,
    required this.dateEmprunt,
    required this.dateRetourPrevue,
    this.dateRetourEffective,
    required this.idAdherent,
    required this.idExemplaire,
  });

  /// RG-04 : durée maximale d'emprunt de 14 jours.
  static const int dureeMaxJours = 14;

  /// Construit un emprunt en calculant automatiquement la date de
  /// retour prévue à `dateEmprunt + 14 jours` (RG-04).
  factory Pret.nouveau({
    int? idEmprunt,
    DateTime? dateEmprunt,
    required int idAdherent,
    required int idExemplaire,
  }) {
    final debut = dateEmprunt ?? DateTime.now();
    return Pret(
      idEmprunt: idEmprunt,
      dateEmprunt: debut,
      dateRetourPrevue: debut.add(const Duration(days: dureeMaxJours)),
      dateRetourEffective: null,
      idAdherent: idAdherent,
      idExemplaire: idExemplaire,
    );
  }

  /// Un prêt est en cours tant qu'aucune date de retour effective n'est
  /// enregistrée.
  bool get estEnCours => dateRetourEffective == null;

  /// Calcul et affichage automatique des retards (cf. cahier des
  /// charges - module Gestion des emprunts).
  bool get estEnRetard =>
      estEnCours && DateTime.now().isAfter(dateRetourPrevue);

  factory Pret.fromMap(Map<String, dynamic> map) {
    return Pret(
      idEmprunt: map['id_emprunt'] as int?,
      dateEmprunt: DateTime.parse(map['date_emprunt'] as String),
      dateRetourPrevue: DateTime.parse(map['date_retour_prevue'] as String),
      dateRetourEffective: map['date_retour_effective'] != null
          ? DateTime.parse(map['date_retour_effective'] as String)
          : null,
      idAdherent: map['id_adherent'] as int,
      idExemplaire: map['id_exemplaire'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (idEmprunt != null) 'id_emprunt': idEmprunt,
      'date_emprunt': dateEmprunt.toIso8601String(),
      'date_retour_prevue': dateRetourPrevue.toIso8601String(),
      'date_retour_effective': dateRetourEffective?.toIso8601String(),
      'id_adherent': idAdherent,
      'id_exemplaire': idExemplaire,
    };
  }

  Pret copyWith({
    int? idEmprunt,
    DateTime? dateEmprunt,
    DateTime? dateRetourPrevue,
    DateTime? dateRetourEffective,
    int? idAdherent,
    int? idExemplaire,
  }) {
    return Pret(
      idEmprunt: idEmprunt ?? this.idEmprunt,
      dateEmprunt: dateEmprunt ?? this.dateEmprunt,
      dateRetourPrevue: dateRetourPrevue ?? this.dateRetourPrevue,
      dateRetourEffective: dateRetourEffective ?? this.dateRetourEffective,
      idAdherent: idAdherent ?? this.idAdherent,
      idExemplaire: idExemplaire ?? this.idExemplaire,
    );
  }

  @override
  String toString() =>
      'Pret(id: $idEmprunt, adherent: $idAdherent, exemplaire: $idExemplaire, enCours: $estEnCours, enRetard: $estEnRetard)';
}
