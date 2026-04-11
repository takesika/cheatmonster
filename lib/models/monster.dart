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

  Map<String, dynamic> toJson() => {
        'name': name,
        'atk': atk,
        'def': def,
        'specialAbility': specialAbility,
      };

  factory Monster.fromJson(Map<String, dynamic> json) => Monster(
        name: json['name'] as String,
        atk: json['atk'] as int,
        def: json['def'] as int,
        specialAbility: json['specialAbility'] as String,
      );
}
