/// Entité UTILISATEUR
///
/// Représente le compte d'authentification de l'administrateur
/// (bibliothécaire). Rattachée aux entités métier (ADHERENT, LIVRE,
/// EXEMPLAIRE) via l'association GÈRE (cf. MCD).
///
/// Table MLD : UTILISATEUR (id_utilisateur, identifiant, mot_de_passe_hash, role)
class Utilisateur {
  final int? idUtilisateur;
  final String identifiant;
  final String motDePasseHash;
  final String role;

  Utilisateur({
    this.idUtilisateur,
    required this.identifiant,
    required this.motDePasseHash,
    this.role = 'bibliothecaire',
  });

  /// Construit un [Utilisateur] à partir d'une ligne SQLite.
  factory Utilisateur.fromMap(Map<String, dynamic> map) {
    return Utilisateur(
      idUtilisateur: map['id_utilisateur'] as int?,
      identifiant: map['identifiant'] as String,
      motDePasseHash: map['mot_de_passe_hash'] as String,
      role: map['role'] as String? ?? 'bibliothecaire',
    );
  }

  /// Convertit l'objet en Map pour insertion/mise à jour SQLite.
  Map<String, dynamic> toMap() {
    return {
      if (idUtilisateur != null) 'id_utilisateur': idUtilisateur,
      'identifiant': identifiant,
      'mot_de_passe_hash': motDePasseHash,
      'role': role,
    };
  }

  Utilisateur copyWith({
    int? idUtilisateur,
    String? identifiant,
    String? motDePasseHash,
    String? role,
  }) {
    return Utilisateur(
      idUtilisateur: idUtilisateur ?? this.idUtilisateur,
      identifiant: identifiant ?? this.identifiant,
      motDePasseHash: motDePasseHash ?? this.motDePasseHash,
      role: role ?? this.role,
    );
  }

  @override
  String toString() =>
      'Utilisateur(id: $idUtilisateur, identifiant: $identifiant, role: $role)';
}
