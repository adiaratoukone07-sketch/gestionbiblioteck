/// Statut de disponibilité d'un exemplaire physique.
///
/// Permet de savoir précisément quel exemplaire est emprunté,
/// disponible, ou en retard (cf. cahier des charges §2.1 - Gestion du
/// catalogue des livres).
enum StatutExemplaire {
  disponible,
  emprunte,
  enRetard,
  perdu;

  String get valeur => name;

  static StatutExemplaire fromValeur(String valeur) {
    return StatutExemplaire.values.firstWhere(
      (s) => s.valeur == valeur,
      orElse: () => StatutExemplaire.disponible,
    );
  }
}

/// Entité EXEMPLAIRE
///
/// Nouveauté de la version révisée du MCD/MLD : chaque exemplaire
/// physique d'un LIVRE est désormais individualisé (code, statut),
/// distinct du LIVRE lui-même (association POSSÈDE, LIVRE 1,1 — EXEMPLAIRE 0,n).
/// Rattaché à un UTILISATEUR gestionnaire via l'association GÈRE (RG-07).
///
/// Table MLD : EXEMPLAIRE (id_exemplaire, code_exemplaire, statut_disponibilite, #id_livre, #id_utilisateur)
class Exemplaire {
  final int? idExemplaire;
  final String codeExemplaire;
  final StatutExemplaire statutDisponibilite;
  final int idLivre;
  final int idUtilisateur;

  Exemplaire({
    this.idExemplaire,
    required this.codeExemplaire,
    this.statutDisponibilite = StatutExemplaire.disponible,
    required this.idLivre,
    required this.idUtilisateur,
  });

  bool get estDisponible => statutDisponibilite == StatutExemplaire.disponible;

  factory Exemplaire.fromMap(Map<String, dynamic> map) {
    return Exemplaire(
      idExemplaire: map['id_exemplaire'] as int?,
      codeExemplaire: map['code_exemplaire'] as String,
      statutDisponibilite:
          StatutExemplaire.fromValeur(map['statut_disponibilite'] as String),
      idLivre: map['id_livre'] as int,
      idUtilisateur: map['id_utilisateur'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (idExemplaire != null) 'id_exemplaire': idExemplaire,
      'code_exemplaire': codeExemplaire,
      'statut_disponibilite': statutDisponibilite.valeur,
      'id_livre': idLivre,
      'id_utilisateur': idUtilisateur,
    };
  }

  Exemplaire copyWith({
    int? idExemplaire,
    String? codeExemplaire,
    StatutExemplaire? statutDisponibilite,
    int? idLivre,
    int? idUtilisateur,
  }) {
    return Exemplaire(
      idExemplaire: idExemplaire ?? this.idExemplaire,
      codeExemplaire: codeExemplaire ?? this.codeExemplaire,
      statutDisponibilite: statutDisponibilite ?? this.statutDisponibilite,
      idLivre: idLivre ?? this.idLivre,
      idUtilisateur: idUtilisateur ?? this.idUtilisateur,
    );
  }

  @override
  String toString() =>
      'Exemplaire(id: $idExemplaire, code: $codeExemplaire, statut: ${statutDisponibilite.valeur})';
}
