import 'dart:math';

import '../models/monster.dart';

class CpuOpponentService {
  static const _names = [
    'ダークドラゴン',
    'シャドウゴーレム',
    'フレイムサーペント',
    'アイスフェンリル',
    'サンダーグリフォン',
    'ポイズンスコーピオン',
    'ストームイーグル',
    'デスナイト',
    'ブラッドヴァンパイア',
    'カオスキメラ',
  ];

  static const _abilities = [
    '炎で全てを焼き尽くす',
    '氷の鎧で身を守る',
    '雷を自在に操る',
    '毒霧を吐く',
    '影に潜み奇襲する',
    '相手の能力を半減する',
    '体力を吸収する',
    '2回連続攻撃',
    '攻撃を反射する',
    '時を止める',
    '地震を起こす',
    '仲間を召喚する',
  ];

  static final _rng = Random();

  Monster generate() {
    return Monster(
      name: _names[_rng.nextInt(_names.length)],
      atk: _rng.nextInt(100) + 1,
      def: _rng.nextInt(100) + 1,
      specialAbility: _abilities[_rng.nextInt(_abilities.length)],
    );
  }
}
