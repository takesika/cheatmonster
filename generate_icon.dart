import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

void main() async {
  const apiKey = String.fromEnvironment('GEMINI_API_KEY');

  final url = Uri.parse(
    'https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash-image:generateContent?key=$apiKey',
  );

  final body = jsonEncode({
    'contents': [
      {
        'parts': [
          {
            'text':
                'Generate 4 minimalist app icons side by side in a 2x2 grid. '
                'Each has the same white dragon silhouette (stylish, sharp angular, sleek modern design, facing right). '
                'Each icon has a different bold background color: '
                '1. Deep electric blue (#1a5cff) '
                '2. Rich black (#111111) '
                '3. Vibrant red (#cc2233) '
                '4. Deep purple (#4a00a0) '
                'Ultra minimal, no text, no gradients. Square format for each icon.'
          }
        ]
      }
    ],
    'generationConfig': {
      'responseModalities': ['TEXT', 'IMAGE'],
    },
  });

  print('Generating app icon...');
  final response = await http.post(
    url,
    headers: {'Content-Type': 'application/json'},
    body: body,
  );

  if (response.statusCode != 200) {
    print('Error: ${response.statusCode}');
    print(response.body.substring(0, 300));
    return;
  }

  final json = jsonDecode(response.body) as Map<String, dynamic>;
  final parts = json['candidates']?[0]?['content']?['parts'] as List?;
  if (parts == null) {
    print('No parts in response');
    return;
  }

  for (final part in parts) {
    if (part['text'] != null) print('Text: ${part['text']}');
    final inlineData = part['inlineData'] as Map<String, dynamic>?;
    if (inlineData != null) {
      final data = inlineData['data'] as String;
      final bytes = base64Decode(data);
      File('app_icon.png').writeAsBytesSync(bytes);
      print('Saved to app_icon.png (${bytes.length} bytes)');
    }
  }
}
