import 'dart:typed_data';

class Monster {
  final String name;
  final int atk;
  final int def;
  final String specialAbility;
  final Uint8List? imageBytes;

  Monster({
    required this.name,
    required this.atk,
    required this.def,
    required this.specialAbility,
    this.imageBytes,
  });

  Monster copyWith({Uint8List? imageBytes}) => Monster(
        name: name,
        atk: atk,
        def: def,
        specialAbility: specialAbility,
        imageBytes: imageBytes ?? this.imageBytes,
      );
}
