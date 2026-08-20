/// Résultat générique d'une opération métier exécutée par un contrôleur.
///
/// Permet de renvoyer un succès ou un échec accompagné d'un message
/// clair destiné à la couche `views/` (ex. affichage d'une erreur de
/// règle de gestion RG-01 à RG-07 dans une boîte de dialogue).
class ResultatOperation {
  final bool succes;
  final String? messageErreur;

  const ResultatOperation.succes()
      : succes = true,
        messageErreur = null;

  const ResultatOperation.echec(this.messageErreur) : succes = false;
}

/// Variante générique de [ResultatOperation] qui renvoie également une
/// donnée en cas de succès (ex. l'objet créé, l'id inséré, l'utilisateur
/// authentifié...).
class ResultatOperationAvecDonnee<T> {
  final bool succes;
  final String? messageErreur;
  final T? donnee;

  const ResultatOperationAvecDonnee.succes(this.donnee)
      : succes = true,
        messageErreur = null;

  const ResultatOperationAvecDonnee.echec(this.messageErreur)
      : succes = false,
        donnee = null;
}
