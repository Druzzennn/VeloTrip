import 'package:flutter_test/flutter_test.dart';

import 'package:frostpedal/data/challenges_data.dart';

void main() {
  test('Les défis sont numérotés séquentiellement à partir de 1', () {
    final challenges = buildChallenges();
    expect(challenges, isNotEmpty);
    for (var i = 0; i < challenges.length; i++) {
      expect(challenges[i].day, i + 1);
    }
  });
}
