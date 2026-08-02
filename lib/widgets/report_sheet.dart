import 'package:flutter/material.dart';

const _reasons = <String>[
  '差別・ヘイト表現',
  '露骨な性表現・下ネタ',
  '実在の個人・団体への攻撃',
  'スパム・広告',
  'その他',
];

/// Show a bottom sheet asking the user why they are reporting the content.
/// Returns the selected reason, or null if the user cancels.
Future<String?> showReportSheet(BuildContext context) {
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (ctx) {
      return SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 8, 20, 4),
                child: Text(
                  '通報の理由を選択',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
                child: Text(
                  '通報するとこの投稿はあなたの端末では非表示になり、運営に内容が送信されます。',
                  style: TextStyle(fontSize: 12, color: Colors.black54),
                ),
              ),
              ..._reasons.map((r) => ListTile(
                    title: Text(r),
                    onTap: () => Navigator.pop(ctx, r),
                  )),
              const Divider(height: 1),
              ListTile(
                title: const Text('キャンセル',
                    style: TextStyle(color: Colors.black54)),
                onTap: () => Navigator.pop(ctx),
              ),
            ],
          ),
        ),
      );
    },
  );
}
