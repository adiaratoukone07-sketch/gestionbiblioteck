import 'package:sqflite/sqflite.dart';

import '../models/exemplaire.dart';
import 'database_helper.dart';

/// DAO pour l'entité EXEMPLAIRE (nouveauté de la révision du MCD/MLD).
///
/// Gère les exemplaires physiques individualisés d'un LIVRE, avec leur
/// statut de disponibilité (cf. cahier des charges - "Affichage du
/// statut de disponibilité de chaque exemplaire").
class ExemplaireDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String _table = 'EXEMPLAIRE';

  Future<int> ajouter(Exemplaire exemplaire) async {
    final db = await _dbHelper.database;
    return await db.insert(
      _table,
      exemplaire.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Exemplaire?> obtenirParId(int idExemplaire) async {
    final db = await _dbHelper.database;
    final resultats = await db.query(
      _table,
      where: 'id_exemplaire = ?',
      whereArgs: [idExemplaire],
      limit: 1,
    );
    if (resultats.isEmpty) return null;
    return Exemplaire.fromMap(resultats.first);
  }

  /// Tous les exemplaires d'un livre donné (association POSSÈDE :
  /// LIVRE 1,1 — EXEMPLAIRE 0,n).
  Future<List<Exemplaire>> obtenirParLivre(int idLivre) async {
    final db = await _dbHelper.database;
    final resultats = await db.query(
      _table,
      where: 'id_livre = ?',
      whereArgs: [idLivre],
      orderBy: 'code_exemplaire',
    );
    return resultats.map((map) => Exemplaire.fromMap(map)).toList();
  }

  /// Utilisé par RG-02 : un emprunt n'est possible que si au moins un
  /// exemplaire du livre est disponible.
  Future<List<Exemplaire>> obtenirDisponiblesParLivre(int idLivre) async {
    final db = await _dbHelper.database;
    final resultats = await db.query(
      _table,
      where: 'id_livre = ? AND statut_disponibilite = ?',
      whereArgs: [idLivre, StatutExemplaire.disponible.valeur],
      orderBy: 'code_exemplaire',
    );
    return resultats.map((map) => Exemplaire.fromMap(map)).toList();
  }

  Future<List<Exemplaire>> obtenirTous() async {
    final db = await _dbHelper.database;
    final resultats = await db.query(_table, orderBy: 'code_exemplaire');
    return resultats.map((map) => Exemplaire.fromMap(map)).toList();
  }

  Future<int> modifier(Exemplaire exemplaire) async {
    final db = await _dbHelper.database;
    return await db.update(
      _table,
      exemplaire.toMap(),
      where: 'id_exemplaire = ?',
      whereArgs: [exemplaire.idExemplaire],
    );
  }

  /// Mise à jour rapide du statut, utilisée par `PretController` lors
  /// de l'enregistrement d'un emprunt ou d'un retour.
  Future<int> mettreAJourStatut(
      int idExemplaire, StatutExemplaire statut) async {
    final db = await _dbHelper.database;
    return await db.update(
      _table,
      {'statut_disponibilite': statut.valeur},
      where: 'id_exemplaire = ?',
      whereArgs: [idExemplaire],
    );
  }

  /// Suppression brute en base. RG-06 (au niveau du livre parent) doit
  /// être vérifiée en amont par le contrôleur.
  Future<int> supprimer(int idExemplaire) async {
    final db = await _dbHelper.database;
    return await db.delete(
      _table,
      where: 'id_exemplaire = ?',
      whereArgs: [idExemplaire],
    );
  }
}
