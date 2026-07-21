import 'package:flutter_test/flutter_test.dart';
import 'package:frostpedal/models/challenge.dart';

/// Reproduit la logique de pénalité km de [TripService] pour les tests.
bool dayIncursBonus(Challenge c, DateTime dueDate) {
  DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);
  if (!c.completed) return true;
  if (c.completedAt == null) return true;
  return dateOnly(c.completedAt!).isAfter(dateOnly(dueDate));
}

void main() {
  final dueDate = DateTime(2026, 6, 10);

  test('défi non fait → pénalité', () {
    final c = Challenge(day: 1, title: 't', description: 'd');
    expect(dayIncursBonus(c, dueDate), isTrue);
  });

  test('défi validé le jour même → pas de pénalité', () {
    final c = Challenge(day: 1, title: 't', description: 'd')
      ..completed = true
      ..completedAt = DateTime(2026, 6, 10, 22, 0);
    expect(dayIncursBonus(c, dueDate), isFalse);
  });

  test('défi rattrapé plus tard → pénalité', () {
    final c = Challenge(day: 1, title: 't', description: 'd')
      ..completed = true
      ..completedAt = DateTime(2026, 6, 12);
    expect(dayIncursBonus(c, dueDate), isTrue);
  });
}
