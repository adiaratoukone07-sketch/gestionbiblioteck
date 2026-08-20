import 'package:sqflite/sqflite.dart';

import '../models/livre.dart';
import 'database_helper.dart';

/// DAO pour l'entité LIVRE.
///
/// Exécute les requêtes SQLite liées au module "Gestion du catalogue
/// des livres" (ajout, modification, suppression, recherche
/// multicritère par titre, auteur, ISBN ou genre).
///
/// Remarque : RG-06 (interdiction de suppression si exemplaires
/// empruntés) reste vérifiée au niveau de `controllers/livre_controller.dart`,
/// en s'appuyant sur [ExemplaireDao].
class LivreDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String _table = 'LIVRE';

  Future<int> ajouter(Livre livre) async {
    final db = await _dbHelper.database;
    return await db.insert(
      _table,
      livre.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Livre?> obtenirParId(int idLivre) async {
    final db = await _dbHelper.database;
    final resultats = await db.query(
      _table,
      where: 'id_livre = ?',
      whereArgs: [idLivre],
      limit: 1,
    );
    if (resultats.isEmpty) return null;
    return Livre.fromMap(resultats.first);
  }

  Future<List<Livre>> obtenirTous() async {
    final db = await _dbHelper.database;
    final resultats = await db.query(_table, orderBy: 'titre');
    return resultats.map((map) => Livre.fromMap(map)).toList();
  }

  /// Recherche multicritère (titre, auteur, ISBN ou genre), cf. cahier
  /// des charges - module Gestion du catalogue.
  Future<List<Livre>> rechercher(String motCle) async {
    final db = await _dbHelper.database;
    final resultats = await db.query(
      _table,
      where: 'titre LIKE ? OR auteur LIKE ? OR isbn LIKE ? OR genre LIKE ?',
      whereArgs: List.filled(4, '%$motCle%'),
      orderBy: 'titre',
    );
    return resultats.map((map) => Livre.fromMap(map)).toList();
  }

  Future<int> modifier(Livre livre) async {
    final db = await _dbHelper.database;
    return await db.update(
      _table,
      livre.toMap(),
      where: 'id_livre = ?',
      whereArgs: [livre.idLivre],
    );
  }

  /// Suppression brute en base. RG-06 doit être vérifiée en amont par
  /// le contrôleur (aucun exemplaire du livre ne doit être en cours
  /// d'emprunt).
  Future<int> supprimer(int idLivre) async {
    final db = await _dbHelper.database;
    return await db.delete(
      _table,
      where: 'id_livre = ?',
      whereArgs: [idLivre],
    );
  }

  /// Compte le nombre de livres au catalogue (utilisé par le tableau
  /// de bord - "Nombre de livres disponibles dans le catalogue").
  Future<int> compterTous() async {
    final db = await _dbHelper.database;
    final resultat =
        await db.rawQuery('SELECT COUNT(*) AS total FROM $_table');
    return Sqflite.firstIntValue(resultat) ?? 0;
  }
}
