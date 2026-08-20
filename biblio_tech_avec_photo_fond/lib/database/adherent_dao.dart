import 'package:sqflite/sqflite.dart';

import '../models/adherent.dart';
import 'database_helper.dart';

/// DAO pour l'entité ADHERENT.
///
/// Exécute les requêtes SQLite liées au module "Gestion des adhérents"
/// du cahier des charges (inscription, modification, suppression,
/// recherche/filtrage par nom ou classe).
///
/// Remarque : la vérification de RG-01 (unicité num_carte) est en
/// partie garantie par la contrainte UNIQUE en base (voir
/// [DatabaseHelper]) ; RG-05 (interdiction de suppression si emprunts
/// en cours) reste vérifiée au niveau de `controllers/adherent_controller.dart`.
class AdherentDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String _table = 'ADHERENT';

  Future<int> ajouter(Adherent adherent) async {
    final db = await _dbHelper.database;
    return await db.insert(
      _table,
      adherent.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Adherent?> obtenirParId(int idAdherent) async {
    final db = await _dbHelper.database;
    final resultats = await db.query(
      _table,
      where: 'id_adherent = ?',
      whereArgs: [idAdherent],
      limit: 1,
    );
    if (resultats.isEmpty) return null;
    return Adherent.fromMap(resultats.first);
  }

  Future<Adherent?> obtenirParNumCarte(String numCarte) async {
    final db = await _dbHelper.database;
    final resultats = await db.query(
      _table,
      where: 'num_carte = ?',
      whereArgs: [numCarte],
      limit: 1,
    );
    if (resultats.isEmpty) return null;
    return Adherent.fromMap(resultats.first);
  }

  Future<List<Adherent>> obtenirTous() async {
    final db = await _dbHelper.database;
    final resultats = await db.query(_table, orderBy: 'nom, prenom');
    return resultats.map((map) => Adherent.fromMap(map)).toList();
  }

  /// Recherche multicritère simplifiée par nom ou classe (cf. cahier
  /// des charges - "Recherche et affichage de la liste des adhérents
  /// avec filtrage par nom ou classe").
  Future<List<Adherent>> rechercher({String? nom, String? classe}) async {
    final db = await _dbHelper.database;
    final conditions = <String>[];
    final arguments = <Object?>[];

    if (nom != null && nom.isNotEmpty) {
      conditions.add('(nom LIKE ? OR prenom LIKE ?)');
      arguments.addAll(['%$nom%', '%$nom%']);
    }
    if (classe != null && classe.isNotEmpty) {
      conditions.add('classe = ?');
      arguments.add(classe);
    }

    final resultats = await db.query(
      _table,
      where: conditions.isEmpty ? null : conditions.join(' AND '),
      whereArgs: conditions.isEmpty ? null : arguments,
      orderBy: 'nom, prenom',
    );
    return resultats.map((map) => Adherent.fromMap(map)).toList();
  }

  Future<int> modifier(Adherent adherent) async {
    final db = await _dbHelper.database;
    return await db.update(
      _table,
      adherent.toMap(),
      where: 'id_adherent = ?',
      whereArgs: [adherent.idAdherent],
    );
  }

  /// Suppression brute en base. RG-05 (pas de suppression si emprunts
  /// en cours) doit être vérifiée en amont par le contrôleur.
  Future<int> supprimer(int idAdherent) async {
    final db = await _dbHelper.database;
    return await db.delete(
      _table,
      where: 'id_adherent = ?',
      whereArgs: [idAdherent],
    );
  }

  /// Compte le nombre total d'adhérents (utilisé par le tableau de
  /// bord - "Nombre total d'adhérents inscrits").
  Future<int> compterTous() async {
    final db = await _dbHelper.database;
    final resultat =
        await db.rawQuery('SELECT COUNT(*) AS total FROM $_table');
    return Sqflite.firstIntValue(resultat) ?? 0;
  }
}
