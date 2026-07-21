import '../models/challenge.dart';

/// Défis du voyage (placeholders pour l'instant).
/// La DURÉE du voyage = le nombre d'éléments de cette liste.
/// Remplace simplement les titres/descriptions quand tu auras tes vrais défis.
List<Challenge> buildChallenges() {
  return List.generate(
    14,
    (i) => Challenge(
      day: i + 1,
      title: 'Défi ${i + 1}',
      description: 'Description du défi ${i + 1}',
    ),
  );
}
