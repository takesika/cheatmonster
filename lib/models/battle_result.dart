enum BattleOutcome { win, lose, draw }

class BattleResult {
  final BattleOutcome outcome;
  final String narration;

  BattleResult({
    required this.outcome,
    required this.narration,
  });
}
