import 'package:flutter_test/flutter_test.dart';

import 'package:card_game/models/monster.dart';
import 'package:card_game/models/game_mode.dart';
import 'package:card_game/models/battle_result.dart';

void main() {
  group('Monster', () {
    test('toJson serializes correctly', () {
      final monster = Monster(
        name: 'TestMonster',
        atk: 50,
        def: 75,
        specialAbility: 'fire breath',
      );

      final json = monster.toJson();
      expect(json['name'], 'TestMonster');
      expect(json['atk'], 50);
      expect(json['def'], 75);
      expect(json['specialAbility'], 'fire breath');
      expect(json.containsKey('imageBytes'), false);
    });

    test('fromJson deserializes correctly', () {
      final json = {
        'name': 'TestMonster',
        'atk': 50,
        'def': 75,
        'specialAbility': 'fire breath',
      };

      final monster = Monster.fromJson(json);
      expect(monster.name, 'TestMonster');
      expect(monster.atk, 50);
      expect(monster.def, 75);
      expect(monster.specialAbility, 'fire breath');
      expect(monster.imageBytes, isNull);
    });

    test('toJson/fromJson roundtrip preserves data', () {
      final original = Monster(
        name: 'RoundTripMonster',
        atk: 99,
        def: 1,
        specialAbility: 'all powers',
      );

      final restored = Monster.fromJson(original.toJson());
      expect(restored.name, original.name);
      expect(restored.atk, original.atk);
      expect(restored.def, original.def);
      expect(restored.specialAbility, original.specialAbility);
    });
  });

  group('GameMode', () {
    test('has cpu and online values', () {
      expect(GameMode.values.length, 2);
      expect(GameMode.values.contains(GameMode.cpu), true);
      expect(GameMode.values.contains(GameMode.online), true);
    });
  });

  group('BattleResult', () {
    test('can be created with all outcomes', () {
      final win = BattleResult(outcome: BattleOutcome.win, narration: 'win');
      final lose = BattleResult(outcome: BattleOutcome.lose, narration: 'lose');
      final draw = BattleResult(outcome: BattleOutcome.draw, narration: 'draw');

      expect(win.outcome, BattleOutcome.win);
      expect(lose.outcome, BattleOutcome.lose);
      expect(draw.outcome, BattleOutcome.draw);
    });
  });
}
