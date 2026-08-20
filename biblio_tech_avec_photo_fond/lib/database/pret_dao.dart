import 'package:sqflite/sqflite.dart';

import '../models/pret.dart';
import 'database_helper.dart';

/// DAO pour l'entité EMPRUNTER (table EMPRUNT), fichier `pret_dao.dart`
/// selon l'arborescence du cahier des charges §3.2.
///
/// Exécute les requêtes SQLite du module "Gestion des emprunts" :
/// enregistrement d'un emprunt/retour, consultation des emprunts en
/// cours, calcul des retards, historique par adhérent et par ouvrage.
///
/// Remarque : RG-02 (disponibilité) et RG-03 (max 3 emprunts
/// simultanés) sont vérifiées au niveau de `controllers/pret_controller.dart`
/// avant tout appel à [ajouter].
class PretDao {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  static const String _table = 'EMPRUNT';

  Future<int> ajouter(Pret pret) async {
    final db = await _dbHelper.database;
    return await db.insert(
      _table,
      pret.toMap(),
      conflictAlgorithm: ConflictAlgorithm.abort,
    );
  }

  Future<Pret?> obtenirParId(int idEmprunt) async {
    final db = await _dbHelper.database;
    final resultats = await db.query(
      _table,
      where: 'id_emprunt = ?',
      whereArgs: [idEmprunt],
      limit: 1,
    );
    if (resultats.isEmpty) return null;
    return Pret.fromMap(resultats.first);
  }

  Future<List<Pret>> obtenirTous() async {
    final db = await _dbHelper.database;
    final resultats = await db.query(_table, orderBy: 'date_emprunt DESC');
    return resultats.map((map) => Pret.fromMap(map)).toList();
  }

  /// Emprunts actuellement en cours (date_retour_effective NULL),
  /// utilisé pour RG-03 (compter les emprunts simultanés d'un adhérent)
  /// et pour le tableau de bord.
  Future<List<Pret>> obtenirEnCours() async {
    final db = await _dbHelper.database;
    final resultats = await db.query(
      _table,
      where: 'date_retour_effective IS NULL',
      orderBy: 'date_retour_prevue',
    );
    return resultats.map((map) => Pret.fromMap(map)).toList();
  }

  /// Emprunts en cours pour un adhérent donné (RG-03 : max 3
  /// simultanés).
  Future<List<Pret>> obtenirEnCoursParAdherent(int idAdherent) async {
    final db = await _dbHelper.database;
    final resultats = await db.query(
      _table,
      where: 'id_adherent = ? AND date_retour_effective IS NULL',
      whereArgs: [idAdherent],
    );
    return resultats.map((map) => Pret.fromMap(map)).toList();
  }

  /// Historique complet des emprunts d'un adhérent (cf. cahier des
  /// charges - "Historique des emprunts par adhérent et par ouvrage").
  Future<List<Pret>> obtenirHistoriqueParAdherent(int idAdherent) async {
    final db = await _dbHelper.database;
    final resultats = await db.query(
      _table,
      where: 'id_adherent = ?',
      whereArgs: [idAdherent],
      orderBy: 'date_emprunt DESC',
    );
    return resultats.map((map) => Pret.fromMap(map)).toList();
  }

  /// Historique des emprunts concernant un exemplaire donné (utile
  /// pour reconstituer l'historique "par ouvrage" en le combinant avec
  /// [ExemplaireDao.obtenirParLivre]).
  Future<List<Pret>> obtenirHistoriqueParExemplaire(int idExemplaire) async {
    final db = await _dbHelper.database;
    final resultats = await db.query(
      _table,
      where: 'id_exemplaire = ?',
      whereArgs: [idExemplaire],
      orderBy: 'date_emprunt DESC',
    );
    return resultats.map((map) => Pret.fromMap(map)).toList();
  }

  /// Emprunts en retard (date_retour_prevue dépassée et non rendus),
  /// cf. cahier des charges - "Liste des emprunts en retard".
  Future<List<Pret>> obtenirEnRetard() async {
    final db = await _dbHelper.database;
    final maintenant = DateTime.now().toIso8601String();
    final resultats = await db.query(
      _table,
      where: 'date_retour_effective IS NULL AND date_retour_prevue < ?',
      whereArgs: [maintenant],
      orderBy: 'date_retour_prevue',
    );
    return resultats.map((map) => Pret.fromMap(map)).toList();
  }

  /// Enregistre le retour effectif d'un ouvrage (cf. cahier des
  /// charges - "Enregistrement du retour effectif d'un ouvrage").
  Future<int> enregistrerRetour(int idEmprunt, {DateTime? dateRetour}) async {
    final db = await _dbHelper.database;
    return await db.update(
      _table,
      {
        'date_retour_effective':
            (dateRetour ?? DateTime.now()).toIso8601String(),
      },
      where: 'id_emprunt = ?',
      whereArgs: [idEmprunt],
    );
  }

  Future<int> supprimer(int idEmprunt) async {
    final db = await _dbHelper.database;
    return await db.delete(
      _table,
      where: 'id_emprunt = ?',
      whereArgs: [idEmprunt],
    );
  }

  /// Nombre d'emprunts en cours, utilisé par le tableau de bord
  /// ("Nombre d'emprunts en cours").
  Future<int> compterEnCours() async {
    final db = await _dbHelper.database;
    final resultat = await db.rawQuery(
      'SELECT COUNT(*) AS total FROM $_table WHERE date_retour_effective IS NULL',
    );
    return Sqflite.firstIntValue(resultat) ?? 0;
  }

  /// Classement des livres les plus empruntés (agrégation via
  /// EXEMPLAIRE -> LIVRE), utilisé par le tableau de bord ("Afficher
  /// les livres les plus empruntés").
  Future<List<Map<String, Object?>>> obtenirLivresLesPlusEmpruntes(
      {int limite = 5}) async {
    final db = await _dbHelper.database;
    return await db.rawQuery('''
      SELECT l.id_livre, l.titre, COUNT(*) AS nombre_emprunts
      FROM $_table e
      JOIN EXEMPLAIRE ex ON ex.id_exemplaire = e.id_exemplaire
      JOIN LIVRE l ON l.id_livre = ex.id_livre
      GROUP BY l.id_livre
      ORDER BY nombre_emprunts DESC
      LIMIT ?
    ''', [limite]);
  }
}
