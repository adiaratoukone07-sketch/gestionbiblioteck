import 'dart:async';
import 'dart:io';

import 'package:path/path.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Singleton SQLite (cf. cahier des charges §3.1 - Base de données :
/// SQLite via `sqflite`, fichier unique .db, adapté à une application
/// desktop sur un poste unique).
///
/// IMPORTANT : le package `sqflite` "pur" ne fonctionne que sur
/// Android/iOS. Comme l'application cible est un exécutable Windows
/// (cf. cahier des charges §4.1 - poste Windows unique), on utilise ici
/// `sqflite_common_ffi`, qui fournit une implémentation SQLite basée
/// sur FFI pour Windows/Linux/macOS. C'est cette différence de backend
/// qui explique l'absence de `getDatabasesDirectory()` : sur desktop,
/// le chemin de la base est obtenu via `databaseFactory.getDatabasesPath()`.
///
/// Crée et gère la connexion à la base de données, ainsi que le schéma
/// relationnel issu du MLD révisé (5 tables : UTILISATEUR, ADHERENT,
/// LIVRE, EXEMPLAIRE, EMPRUNT).
class DatabaseHelper {
  DatabaseHelper._interne() {
    // Initialise le backend FFI et le déclare comme factory par défaut.
    // À faire une seule fois, avant toute utilisation de la base.
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }
  }

  static final DatabaseHelper instance = DatabaseHelper._interne();

  static Database? _database;

  static const String _nomFichierDb = 'bibliotheque.db';
  static const int _versionSchema = 1;

  /// Retourne l'instance unique de la base, en l'ouvrant/créant si besoin.
  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initialiserDatabase();
    return _database!;
  }

  Future<Database> _initialiserDatabase() async {
    final String dossierBase = await databaseFactory.getDatabasesPath();
    final String chemin = join(dossierBase, _nomFichierDb);

    return await databaseFactory.openDatabase(
      chemin,
      options: OpenDatabaseOptions(
        version: _versionSchema,
        onConfigure: _onConfigure,
        onCreate: _onCreate,
      ),
    );
  }

  /// Active la vérification des contraintes de clé étrangère (désactivée
  /// par défaut par SQLite), nécessaire pour RG-07 (NOT NULL + FK
  /// id_utilisateur) et les FK des tables EXEMPLAIRE / EMPRUNT.
  Future<void> _onConfigure(Database db) async {
    await db.execute('PRAGMA foreign_keys = ON');
  }

  /// Création du schéma relationnel (cf. document MCD/MLD §2.1).
  ///
  /// Ordre de création respectant les dépendances de clés étrangères :
  /// UTILISATEUR -> ADHERENT / LIVRE -> EXEMPLAIRE -> EMPRUNT.
  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE UTILISATEUR (
        id_utilisateur INTEGER PRIMARY KEY AUTOINCREMENT,
        identifiant TEXT NOT NULL UNIQUE,
        mot_de_passe_hash TEXT NOT NULL,
        role TEXT NOT NULL DEFAULT 'bibliothecaire'
      )
    ''');

    // RG-01 : unicité de l'adhérent via num_carte.
    await db.execute('''
      CREATE TABLE ADHERENT (
        id_adherent INTEGER PRIMARY KEY AUTOINCREMENT,
        num_carte TEXT NOT NULL UNIQUE,
        nom TEXT NOT NULL,
        prenom TEXT NOT NULL,
        classe TEXT NOT NULL,
        id_utilisateur INTEGER NOT NULL,
        FOREIGN KEY (id_utilisateur) REFERENCES UTILISATEUR (id_utilisateur)
      )
    ''');

    await db.execute('''
      CREATE TABLE LIVRE (
        id_livre INTEGER PRIMARY KEY AUTOINCREMENT,
        titre TEXT NOT NULL,
        auteur TEXT NOT NULL,
        isbn TEXT NOT NULL,
        genre TEXT NOT NULL,
        nombre_exemplaires INTEGER NOT NULL DEFAULT 0,
        id_utilisateur INTEGER NOT NULL,
        FOREIGN KEY (id_utilisateur) REFERENCES UTILISATEUR (id_utilisateur)
      )
    ''');

    // Entité EXEMPLAIRE (nouveauté de la révision du MCD/MLD) :
    // individualise chaque exemplaire physique d'un livre (RG-06).
    await db.execute('''
      CREATE TABLE EXEMPLAIRE (
        id_exemplaire INTEGER PRIMARY KEY AUTOINCREMENT,
        code_exemplaire TEXT NOT NULL UNIQUE,
        statut_disponibilite TEXT NOT NULL DEFAULT 'disponible',
        id_livre INTEGER NOT NULL,
        id_utilisateur INTEGER NOT NULL,
        FOREIGN KEY (id_livre) REFERENCES LIVRE (id_livre),
        FOREIGN KEY (id_utilisateur) REFERENCES UTILISATEUR (id_utilisateur)
      )
    ''');

    // Table EMPRUNT, issue de l'entité EMPRUNTER et de ses deux
    // associations EFFECTUE (-> ADHERENT) et CONCERNE (-> EXEMPLAIRE),
    // chacune (1,1) côté EMPRUNTER => FK NOT NULL (cf. MCD/MLD §2.1/2.2).
    await db.execute('''
      CREATE TABLE EMPRUNT (
        id_emprunt INTEGER PRIMARY KEY AUTOINCREMENT,
        date_emprunt TEXT NOT NULL,
        date_retour_prevue TEXT NOT NULL,
        date_retour_effective TEXT,
        id_adherent INTEGER NOT NULL,
        id_exemplaire INTEGER NOT NULL,
        FOREIGN KEY (id_adherent) REFERENCES ADHERENT (id_adherent),
        FOREIGN KEY (id_exemplaire) REFERENCES EXEMPLAIRE (id_exemplaire)
      )
    ''');
  }

  /// Ferme la connexion (utile pour les tests ou la fermeture propre de
  /// l'application).
  Future<void> fermer() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
