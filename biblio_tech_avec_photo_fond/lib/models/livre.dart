/// Entité LIVRE
///
/// Représente un ouvrage du catalogue (titre, auteur, ISBN, genre).
/// Un livre POSSÈDE zéro à plusieurs EXEMPLAIRE (cardinalité 1,1 — 0,n).
/// Rattaché à un UTILISATEUR gestionnaire via l'association GÈRE (RG-07).
///
/// Table MLD : LIVRE (id_livre, titre, auteur, isbn, genre, nombre_exemplaires, #id_utilisateur)
class Livre {
  final int? idLivre;
  final String titre;
  final String auteur;
  final String isbn;
  final String genre;
  final int nombreExemplaires;
  final int idUtilisateur;

  Livre({
    this.idLivre,
    required this.titre,
    required this.auteur,
    required this.isbn,
    required this.genre,
    this.nombreExemplaires = 0,
    required this.idUtilisateur,
  });

  factory Livre.fromMap(Map<String, dynamic> map) {
    return Livre(
      idLivre: map['id_livre'] as int?,
      titre: map['titre'] as String,
      auteur: map['auteur'] as String,
      isbn: map['isbn'] as String,
      genre: map['genre'] as String,
      nombreExemplaires: map['nombre_exemplaires'] as int? ?? 0,
      idUtilisateur: map['id_utilisateur'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (idLivre != null) 'id_livre': idLivre,
      'titre': titre,
      'auteur': auteur,
      'isbn': isbn,
      'genre': genre,
      'nombre_exemplaires': nombreExemplaires,
      'id_utilisateur': idUtilisateur,
    };
  }

  Livre copyWith({
    int? idLivre,
    String? titre,
    String? auteur,
    String? isbn,
    String? genre,
    int? nombreExemplaires,
    int? idUtilisateur,
  }) {
    return Livre(
      idLivre: idLivre ?? this.idLivre,
      titre: titre ?? this.titre,
      auteur: auteur ?? this.auteur,
      isbn: isbn ?? this.isbn,
      genre: genre ?? this.genre,
      nombreExemplaires: nombreExemplaires ?? this.nombreExemplaires,
      idUtilisateur: idUtilisateur ?? this.idUtilisateur,
    );
  }

  @override
  String toString() =>
      'Livre(id: $idLivre, titre: $titre, auteur: $auteur, isbn: $isbn)';
}
