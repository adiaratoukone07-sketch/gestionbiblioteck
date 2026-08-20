import 'package:sqflite/sqflite.dart';

import '../models/utilisateur.dart';
import 'database_helper.dart';

/// DAO (Data Access Object) pour l'entité UTILISATEUR.
///
/// Exécute les requêtes SQLite liées à l'authentification de
/// l'administrateur (cf. cahier des charges - module Authentification).
class UtilisateurDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String _table = 'UTILISATEUR';

  Future<int> ajouter(Utilisateur utilisateur) async {
    final db = await _dbHelper.database;
    return await db.insert(
      _table,
      utilisateur.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Utilisateur?> obtenirParId(int idUtilisateur) async {
    final db = await _dbHelper.database;
    final resultats = await db.query(
      _table,
      where: 'id_utilisateur = ?',
      whereArgs: [idUtilisateur],
      limit: 1,
    );
    if (resultats.isEmpty) return null;
    return Utilisateur.fromMap(resultats.first);
  }

  /// Utilisé par la page de connexion pour vérifier les identifiants
  /// (cf. cahier des charges - Authentification : "Page de connexion
  /// avec saisie d'identifiant et de mot de passe").
  Future<Utilisateur?> obtenirParIdentifiant(String identifiant) async {
    final db = await _dbHelper.database;
    final resultats = await db.query(
      _table,
      where: 'identifiant = ?',
      whereArgs: [identifiant],
      limit: 1,
    );
    if (resultats.isEmpty) return null;
    return Utilisateur.fromMap(resultats.first);
  }

  Future<List<Utilisateur>> obtenirTous() async {
    final db = await _dbHelper.database;
    final resultats = await db.query(_table);
    return resultats.map((map) => Utilisateur.fromMap(map)).toList();
  }

  Future<int> modifier(Utilisateur utilisateur) async {
    final db = await _dbHelper.database;
    return await db.update(
      _table,
      utilisateur.toMap(),
      where: 'id_utilisateur = ?',
      whereArgs: [utilisateur.idUtilisateur],
    );
  }

  Future<int> supprimer(int idUtilisateur) async {
    final db = await _dbHelper.database;
    return await db.delete(
      _table,
      where: 'id_utilisateur = ?',
      whereArgs: [idUtilisateur],
    );
  }
}
