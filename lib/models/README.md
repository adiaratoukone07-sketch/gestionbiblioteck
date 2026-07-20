# Modèles — Système de Gestion de Bibliothèque Scolaire

Ce dossier correspond au répertoire `lib/models/` de l'arborescence MVC
définie dans le cahier des charges (§3.2), mis à jour avec l'entité
`EXEMPLAIRE` introduite dans la version révisée du MCD/MLD.

| Fichier            | Entité MCD/MLD | Description |
|---------------------|----------------|--------------|
| `utilisateur.dart`  | UTILISATEUR    | Compte d'authentification du bibliothécaire |
| `adherent.dart`     | ADHERENT       | Membre de la bibliothèque (élève) |
| `livre.dart`        | LIVRE          | Ouvrage du catalogue |
| `exemplaire.dart`   | EXEMPLAIRE     | Exemplaire physique d'un livre (statut de disponibilité) — nouvelle entité de la révision |
| `pret.dart`         | EMPRUNTER / EMPRUNT | Emprunt (entité autonome depuis la révision, reliée à ADHERENT via EFFECTUE et à EXEMPLAIRE via CONCERNE) |

Chaque classe fournit :
- des champs correspondant strictement aux colonnes du MLD (clés
  primaires optionnelles, clés étrangères obligatoires) ;
- `fromMap()` / `toMap()` pour l'interfaçage avec la couche `database/`
  (SQLite via `sqflite`) ;
- `copyWith()` pour les mises à jour immuables depuis les contrôleurs ;
- des règles de gestion simples portées par le modèle lorsqu'elles sont
  intrinsèques à l'entité (ex. `Pret.estEnRetard`, `Pret.dureeMaxJours`
  pour RG-04). Les règles applicatives plus complexes (RG-02, RG-03,
  RG-05, RG-06, RG-07) restent implémentées dans `controllers/`,
  conformément à la note d'architecture du document MCD/MLD.
