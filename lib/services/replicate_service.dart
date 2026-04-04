import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;

import '../config/env.dart';

class ImageGenerationService {
  Future<Uint8List?> generateMonsterImage(
      String name, String specialAbility) async {
    final prompt =
        'モンスターカードゲームのイラスト。ダークファンタジー風のクリーチャー「$name」。'
        '能力: $specialAbility。迫力のあるカードゲーム用ポートレート、高品質イラスト。';

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-image-preview:generateContent?key=${Env.geminiApiKey}',
    );

    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt}
          ]
        }
      ],
      'generationConfig': {
        'responseModalities': ['TEXT', 'IMAGE'],
      },
    });

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: body,
    );

    if (response.statusCode != 200) {
      return null;
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) return null;

    final parts =
        candidates[0]['content']?['parts'] as List<dynamic>?;
    if (parts == null) return null;

    for (final part in parts) {
      final inlineData = part['inlineData'] as Map<String, dynamic>?;
      if (inlineData != null) {
        final base64Data = inlineData['data'] as String?;
        if (base64Data != null) {
          return base64Decode(base64Data);
        }
      }
    }

    return null;
  }
}
