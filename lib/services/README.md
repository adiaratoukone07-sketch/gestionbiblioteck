# Services — Système de Gestion de Bibliothèque Scolaire

Ce dossier correspond au répertoire `lib/services/` de l'arborescence
MVC du cahier des charges (§3.2) : fonctions transverses, sans logique
métier ni accès direct aux DAO.

| Fichier                | Rôle |
|--------------------------|------|
| `hash_service.dart`     | Hachage/vérification de mot de passe avec bcrypt (package `bcrypt`) |
| `session_service.dart`  | État de la session en mémoire (utilisateur connecté, verrouillage par inactivité) — singleton, sans accès base de données |

Ces services sont utilisés par `controllers/auth_controller.dart`, qui
porte la logique métier (vérification des identifiants, orchestration
du verrouillage/déverrouillage).

## Dépendance requise (`pubspec.yaml`)

```yaml
dependencies:
  bcrypt: ^1.1.3
```
