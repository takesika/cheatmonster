// One-shot migration entry point. Run with:
//   flutter run --target=lib/migrate.dart -d <device-id>
//
// Reads every /champion and /history entry that still carries
// `imageBase64`, uploads the raw bytes to Firebase Storage, replaces the
// field with `imageUrl`, and reports progress in a minimal UI. Safe to
// re-run — entries that already have `imageUrl` are skipped.
//
// This file is NOT reachable from the shipping app; the App Store binary
// always uses lib/main.dart. It exists purely so the migration reuses the
// production Firebase config without needing a separate admin script.

import 'dart:convert';
import 'dart:typed_data';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const _MigrateApp());
}

class _MigrateApp extends StatelessWidget {
  const _MigrateApp();

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Chronicle Image Migration',
      home: _MigratePage(),
    );
  }
}

class _MigratePage extends StatefulWidget {
  const _MigratePage();

  @override
  State<_MigratePage> createState() => _MigratePageState();
}

class _MigratePageState extends State<_MigratePage> {
  final _log = <String>[];
  bool _running = false;
  bool _done = false;

  void _write(String line) {
    setState(() => _log.add(line));
    debugPrint(line);
  }

  Future<void> _run() async {
    if (_running) return;
    setState(() {
      _running = true;
      _done = false;
      _log.clear();
    });

    final db = FirebaseDatabase.instance.ref();
    final storage = FirebaseStorage.instance;

    // ── History ────────────────────────────────────────────────────
    _write('Fetching /history…');
    final historySnap = await db.child('history').get();
    if (historySnap.exists && historySnap.value is Map) {
      final entries = Map<Object?, Object?>.from(historySnap.value as Map);
      _write('Found ${entries.length} history entries. Migrating…');
      int migrated = 0;
      int skipped = 0;
      int failed = 0;
      for (final e in entries.entries) {
        final key = e.key as String?;
        if (key == null) continue;
        final data = Map<String, dynamic>.from(e.value as Map);
        if (data['imageUrl'] is String &&
            (data['imageUrl'] as String).isNotEmpty) {
          skipped++;
          continue;
        }
        final base64 = data['imageBase64'];
        if (base64 is! String || base64.isEmpty) {
          skipped++;
          continue;
        }
        try {
          final Uint8List bytes = base64Decode(base64);
          final ref = storage.ref('history/$key.png');
          await ref.putData(
            bytes,
            SettableMetadata(contentType: 'image/png'),
          );
          final url = await ref.getDownloadURL();
          await db.child('history/$key').update({
            'imageUrl': url,
            'imageBase64': null, // delete the fat field
          });
          migrated++;
          _write('  ✓ history/$key (${bytes.length} bytes)');
        } catch (err) {
          failed++;
          _write('  ✗ history/$key: $err');
        }
      }
      _write('History done — migrated=$migrated skipped=$skipped failed=$failed');
    } else {
      _write('No /history data.');
    }

    // ── Champion ───────────────────────────────────────────────────
    _write('');
    _write('Fetching /champion…');
    final champSnap = await db.child('champion').get();
    if (champSnap.exists && champSnap.value is Map) {
      final data = Map<String, dynamic>.from(champSnap.value as Map);
      if (data['imageUrl'] is String &&
          (data['imageUrl'] as String).isNotEmpty) {
        _write('Champion already has imageUrl — skipping.');
      } else {
        final base64 = data['imageBase64'];
        if (base64 is String && base64.isNotEmpty) {
          try {
            final Uint8List bytes = base64Decode(base64);
            final updatedAt = (data['updatedAt'] as num?)?.toInt() ??
                DateTime.now().millisecondsSinceEpoch;
            final ref = storage.ref('champion/$updatedAt.png');
            await ref.putData(
              bytes,
              SettableMetadata(contentType: 'image/png'),
            );
            final url = await ref.getDownloadURL();
            await db.child('champion').update({
              'imageUrl': url,
              'imageBase64': null,
            });
            _write('  ✓ champion/$updatedAt (${bytes.length} bytes)');
          } catch (err) {
            _write('  ✗ champion: $err');
          }
        } else {
          _write('Champion has no imageBase64 — nothing to do.');
        }
      }
    } else {
      _write('No /champion data.');
    }

    _write('');
    _write('== Migration complete ==');
    setState(() {
      _running = false;
      _done = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Image Migration')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              '既存の /history と /champion に埋め込まれた base64 画像を '
              'Firebase Storage に移し、RTDB を imageUrl 参照に置き換えます。'
              '再実行しても既に移行済みのエントリはスキップされます。',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _running ? null : _run,
              child: Text(
                _running
                    ? '移行中...'
                    : _done
                        ? 'もう一度実行'
                        : '移行を開始',
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                reverse: true,
                child: SelectableText(
                  _log.join('\n'),
                  style: const TextStyle(
                      fontFamily: 'Menlo', fontSize: 12, height: 1.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
