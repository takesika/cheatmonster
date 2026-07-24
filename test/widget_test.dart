import 'package:flutter_test/flutter_test.dart';

import 'package:card_game/models/battle_result.dart';
import 'package:card_game/models/champion.dart';
import 'package:card_game/models/game_mode.dart';
import 'package:card_game/models/monster.dart';

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
    test('has cpu, online, throne values', () {
      expect(GameMode.values.length, 3);
      expect(GameMode.values.contains(GameMode.cpu), true);
      expect(GameMode.values.contains(GameMode.online), true);
      expect(GameMode.values.contains(GameMode.throne), true);
    });
  });

  group('Champion', () {
    test('fromRaw returns null when raw is null', () {
      expect(Champion.fromRaw(null), isNull);
    });

    test('fromRaw parses a well-formed map', () {
      final champ = Champion.fromRaw({
        'name': 'ChampMonster',
        'atk': 80,
        'def': 60,
        'specialAbility': 'buy the judge',
        'updatedAt': 1234567890,
      });
      expect(champ, isNotNull);
      expect(champ!.monster.name, 'ChampMonster');
      expect(champ.monster.atk, 80);
      expect(champ.monster.def, 60);
      expect(champ.monster.specialAbility, 'buy the judge');
      expect(champ.updatedAt, 1234567890);
      expect(champ.monster.imageBytes, isNull);
    });

    test('toJson round-trip via fromRaw preserves scalar fields', () {
      final original = Champion(
        monster: Monster(
          name: 'RoundTrip',
          atk: 55,
          def: 45,
          specialAbility: 'time rewind',
        ),
        updatedAt: 42,
      );
      final restored = Champion.fromRaw(original.toJson());
      expect(restored, isNotNull);
      expect(restored!.monster.name, 'RoundTrip');
      expect(restored.monster.atk, 55);
      expect(restored.monster.def, 45);
      expect(restored.monster.specialAbility, 'time rewind');
      expect(restored.updatedAt, 42);
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
