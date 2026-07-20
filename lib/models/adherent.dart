/// Entité ADHERENT
///
/// Représente un membre de la bibliothèque (élève ou membre de
/// l'établissement) pouvant emprunter des ouvrages.
/// Rattaché à un UTILISATEUR gestionnaire via l'association GÈRE (RG-07).
///
/// Table MLD : ADHERENT (id_adherent, num_carte, nom, prenom, classe, #id_utilisateur)
class Adherent {
  final int? idAdherent;
  final String numCarte;
  final String nom;
  final String prenom;
  final String classe;
  final int idUtilisateur;

  Adherent({
    this.idAdherent,
    required this.numCarte,
    required this.nom,
    required this.prenom,
    required this.classe,
    required this.idUtilisateur,
  });

  /// Nom complet pratique pour l'affichage dans les vues.
  String get nomComplet => '$prenom $nom';

  factory Adherent.fromMap(Map<String, dynamic> map) {
    return Adherent(
      idAdherent: map['id_adherent'] as int?,
      numCarte: map['num_carte'] as String,
      nom: map['nom'] as String,
      prenom: map['prenom'] as String,
      classe: map['classe'] as String,
      idUtilisateur: map['id_utilisateur'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (idAdherent != null) 'id_adherent': idAdherent,
      'num_carte': numCarte,
      'nom': nom,
      'prenom': prenom,
      'classe': classe,
      'id_utilisateur': idUtilisateur,
    };
  }

  Adherent copyWith({
    int? idAdherent,
    String? numCarte,
    String? nom,
    String? prenom,
    String? classe,
    int? idUtilisateur,
  }) {
    return Adherent(
      idAdherent: idAdherent ?? this.idAdherent,
      numCarte: numCarte ?? this.numCarte,
      nom: nom ?? this.nom,
      prenom: prenom ?? this.prenom,
      classe: classe ?? this.classe,
      idUtilisateur: idUtilisateur ?? this.idUtilisateur,
    );
  }

  @override
  String toString() =>
      'Adherent(id: $idAdherent, carte: $numCarte, nom: $nomComplet, classe: $classe)';
}
