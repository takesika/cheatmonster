import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../config/theme.dart';

/// Full-screen blocker shown when the server-side minVersion is higher
/// than the running binary. Nothing else in the app is reachable while
/// this is up.
class UpdateRequiredScreen extends StatelessWidget {
  final String currentVersion;
  final String minVersion;
  const UpdateRequiredScreen({
    super.key,
    required this.currentVersion,
    required this.minVersion,
  });

  static const _appId = '6761651725'; // com.imanaka.cheatmonster

  Future<void> _openStore() async {
    final deepLink = Uri.parse('itms-apps://apps.apple.com/app/id$_appId');
    final webLink = Uri.parse('https://apps.apple.com/app/id$_appId');
    try {
      final ok = await launchUrl(deepLink, mode: LaunchMode.externalApplication);
      if (ok) return;
    } catch (_) {}
    try {
      await launchUrl(webLink, mode: LaunchMode.externalApplication);
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.system_update_alt,
                size: 64,
                color: AppColors.yellowDeep,
              ),
              const SizedBox(height: 24),
              const Text(
                'アプリの更新が必要です',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: AppFonts.gothic,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '公平にプレイするため、最新版へのアップデートをお願いします。\n\n'
                '現在のバージョン: $currentVersion\n必要なバージョン: $minVersion 以降',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: AppFonts.gothic,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.inkMid,
                  height: 1.7,
                ),
              ),
              const SizedBox(height: 32),
              FilledButton(
                onPressed: _openStore,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.yellow,
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text(
                  'App Store で更新',
                  style: TextStyle(
                    fontFamily: AppFonts.gothic,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
