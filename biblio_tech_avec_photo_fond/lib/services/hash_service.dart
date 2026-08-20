import 'package:bcrypt/bcrypt.dart';

/// Service transverse de hachage de mot de passe (cf. cahier des
/// charges §3.1 - "Hash de mot de passe : bcrypt (package bcrypt),
/// algorithme robuste et reconnu pour le stockage sécurisé des mots de
/// passe").
///
/// Fichier `services/hash_service.dart` selon l'arborescence MVC du
/// cahier des charges §3.2.
class HashService {
  /// Génère un hash bcrypt à partir d'un mot de passe en clair, à
  /// stocker dans `Utilisateur.motDePasseHash`.
  static String hacher(String motDePasseClair) {
    return BCrypt.hashpw(motDePasseClair, BCrypt.gensalt());
  }

  /// Vérifie qu'un mot de passe en clair correspond bien au hash stocké
  /// en base. Utilisé à la fois pour la connexion et pour le
  /// déverrouillage par PIN (qui réutilise le mot de passe du compte).
  static bool verifier(String motDePasseClair, String hash) {
    return BCrypt.checkpw(motDePasseClair, hash);
  }
}
