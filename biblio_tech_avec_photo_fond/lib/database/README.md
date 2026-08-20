# Database — Système de Gestion de Bibliothèque Scolaire

Ce dossier correspond au répertoire `lib/database/` de l'arborescence
MVC du cahier des charges (§3.2) : couche DAO (Data Access Object),
responsable de l'exécution des requêtes SQLite et de la conversion
entre lignes SQLite et modèles (`lib/models/`).

| Fichier                | Rôle |
|--------------------------|------|
| `database_helper.dart`  | Singleton SQLite : ouverture/création du fichier `.db`, script `CREATE TABLE` du schéma relationnel (MLD révisé, 5 tables), activation des clés étrangères (`PRAGMA foreign_keys = ON`) |
| `utilisateur_dao.dart`  | CRUD + recherche par identifiant (authentification) |
| `adherent_dao.dart`     | CRUD + recherche par nom/classe + compteur (tableau de bord) |
| `livre_dao.dart`        | CRUD + recherche multicritère (titre, auteur, ISBN, genre) + compteur |
| `exemplaire_dao.dart`   | CRUD + exemplaires disponibles par livre (RG-02) + mise à jour du statut — DAO ajouté suite à la promotion d'EXEMPLAIRE en entité distincte |
| `pret_dao.dart`         | Enregistrement emprunt/retour, emprunts en cours (RG-03), retards, historique par adhérent/exemplaire, statistiques (tableau de bord) |

## Ordre de création des tables (contraintes FK)

```
UTILISATEUR
   ├── ADHERENT (#id_utilisateur)
   └── LIVRE (#id_utilisateur)
         └── EXEMPLAIRE (#id_livre, #id_utilisateur)
               └── EMPRUNT (#id_exemplaire, #id_adherent)
```

## Règles de gestion (RG) et responsabilités

Les DAO exposent les requêtes nécessaires mais **ne valident pas** les
règles de gestion applicatives complexes ; celles-ci restent portées
par la couche `controllers/`, conformément à la note d'architecture du
document MCD/MLD :

| Règle | Description | Où elle est vérifiée |
|---|---|---|
| RG-01 | Unicité num_carte | Contrainte `UNIQUE` SQL (déclarative) |
| RG-02 | Emprunt possible seulement si exemplaire dispo | `PretController`, via `ExemplaireDao.obtenirDisponiblesParLivre` |
| RG-03 | Max 3 emprunts simultanés | `PretController`, via `PretDao.obtenirEnCoursParAdherent` |
| RG-04 | Durée max 14 jours | Calculée dans le modèle `Pret.nouveau()` |
| RG-05 | Pas de suppression d'adhérent si emprunt en cours | `AdherentController`, via `PretDao.obtenirEnCoursParAdherent` |
| RG-06 | Pas de suppression de livre si exemplaire emprunté | `LivreController`, via `ExemplaireDao.obtenirParLivre` |
| RG-07 | Rattachement obligatoire à un utilisateur gestionnaire | Contrainte `NOT NULL` + `FOREIGN KEY` SQL (déclarative) |

## ⚠️ Windows desktop : `sqflite_common_ffi`

Le package `sqflite` "pur" ne fonctionne que sur **Android/iOS**
(il repose sur des canaux de plateforme mobiles). Comme l'application
cible un exécutable **Windows** (cahier des charges §4.1), le fichier
`database_helper.dart` utilise **`sqflite_common_ffi`**, qui fournit un
backend SQLite via FFI pour Windows/Linux/macOS.

C'est pour cela que `getDatabasesDirectory()` (API mobile) n'existe
pas ici : sur desktop, on récupère le dossier de la base via
`databaseFactory.getDatabasesPath()` et on ouvre la base avec
`databaseFactory.openDatabase(...)`, après avoir déclaré
`databaseFactory = databaseFactoryFfi` (fait automatiquement dans le
constructeur de `DatabaseHelper`).

Les DAO continuent d'importer `package:sqflite/sqflite.dart` : ce
package reste utile pour les types partagés (`Database`,
`ConflictAlgorithm`, `Sqflite.firstIntValue`), qui sont communs aux
deux backends (mobile et FFI) via `sqflite_common`.

Sur Windows, `sqflite_common_ffi` nécessite que les DLL SQLite
(`sqlite3.dll`) soient accessibles à l'exécution. Le plus simple est
d'ajouter le package `sqlite3_flutter_libs`, qui les embarque
automatiquement dans le build.

## Dépendances requises (`pubspec.yaml`)

```yaml
dependencies:
  sqflite: ^2.3.0             # types partagés (Database, ConflictAlgorithm...) utilisés par les DAO
  sqflite_common_ffi: ^2.3.0  # backend SQLite desktop (Windows/Linux/macOS)
  sqlite3_flutter_libs: ^0.5.0   # fournit sqlite3.dll pour Windows
  path: ^1.9.0
```
