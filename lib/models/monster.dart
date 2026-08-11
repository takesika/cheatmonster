import 'dart:typed_data';

class Monster {
  final String name;
  final int atk;
  final int def;
  final String specialAbility;

  /// Raw image bytes — populated when we just generated the image locally.
  final Uint8List? imageBytes;

  /// Firebase Storage download URL — populated when the monster comes from
  /// RTDB with an image already uploaded to Storage. Widgets prefer bytes
  /// when both are set; URL avoids the base64 round-trip through RTDB.
  final String? imageUrl;

  Monster({
    required this.name,
    required this.atk,
    required this.def,
    required this.specialAbility,
    this.imageBytes,
    this.imageUrl,
  });

  Monster copyWith({Uint8List? imageBytes, String? imageUrl}) => Monster(
        name: name,
        atk: atk,
        def: def,
        specialAbility: specialAbility,
        imageBytes: imageBytes ?? this.imageBytes,
        imageUrl: imageUrl ?? this.imageUrl,
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
