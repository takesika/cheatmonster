import 'package:flutter/material.dart';

import '../config/theme.dart';
import '../models/champion.dart';
import '../models/history_entry.dart';
import '../services/champion_service.dart';
import '../services/report_service.dart';
import '../widgets/game_background.dart';
import '../widgets/monster_art.dart';
import '../widgets/report_sheet.dart';

class ChronicleScreen extends StatefulWidget {
  const ChronicleScreen({super.key});

  @override
  State<ChronicleScreen> createState() => _ChronicleScreenState();
}

/// Info about a single champion's reign, derived from adjacent chronicle
/// entries + the current champion.
class _ReignInfo {
  /// Number of defenses this champion made during their reign. Null when it
  /// couldn't be determined (no matching next-newer entry AND not the
  /// current champion).
  final int? defenseCount;

  /// True if this champion is the one currently sitting on the throne.
  final bool isCurrent;

  const _ReignInfo({this.defenseCount, this.isCurrent = false});
}

class _ChronicleScreenState extends State<ChronicleScreen> {
  static const _pageSize = 20;

  final _service = ChampionService();
  final _reports = ReportService();
  bool _loading = true;
  bool _loadingMore = false;
  bool _hasMore = true;
  String? _error;
  Champion? _currentChampion;
  List<HistoryEntry> _entries = const [];
  Map<String, _ReignInfo> _reigns = const {};
  int? _totalCount;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _hasMore = true;
    });
    try {
      await _reports.load();
      final results = await Future.wait([
        _service.fetchHistory(limit: _pageSize),
        _service.fetchChampion().catchError((_) => null),
        _service.fetchHistoryCount().catchError((_) => null),
      ]);
      final raw = results[0] as List<HistoryEntry>;
      final currentChampion = results[1] as Champion?;
      int? totalCount = results[2] as int?;
      // Pre-migration or /historyCount write blocked by RTDB rules —
      // backfill by counting entries. When the write is blocked this
      // repeats on every load, which is slower but keeps # numbers stable.
      totalCount ??= await _service
          .backfillHistoryCount()
          .catchError((_) => 0);
      final entries =
          raw.where((e) => !_reports.isHistoryBlocked(e.key)).toList();
      if (!mounted) return;
      setState(() {
        _currentChampion = currentChampion;
        _entries = entries;
        _totalCount = totalCount;
        _reigns = _computeReigns(entries, currentChampion);
        _hasMore = raw.length >= _pageSize;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = '年表の取得に失敗しました';
        _loading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_loadingMore || !_hasMore || _entries.isEmpty) return;
    setState(() => _loadingMore = true);
    try {
      final oldest = _entries.last.key;
      final raw = await _service.fetchHistory(
        limit: _pageSize,
        before: oldest,
      );
      final more =
          raw.where((e) => !_reports.isHistoryBlocked(e.key)).toList();
      if (!mounted) return;
      final combined = [..._entries, ...more];
      setState(() {
        _entries = combined;
        _reigns = _computeReigns(combined, _currentChampion);
        _hasMore = raw.length >= _pageSize;
        _loadingMore = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingMore = false);
    }
  }

  /// For each entry, figure out how many times its winner defended their
  /// throne during their reign. Newer entries carry the defeated champion's
  /// defense count, so entry `i`'s reign count = the next-newer entry's
  /// `defeatedDefenseCount` when that entry's defeated matches this entry's
  /// winner. The newest entry gets its count from the live champion if the
  /// winner is still sitting on the throne.
  Map<String, _ReignInfo> _computeReigns(
      List<HistoryEntry> entries, Champion? current) {
    final result = <String, _ReignInfo>{};
    for (int i = 0; i < entries.length; i++) {
      final e = entries[i];
      _ReignInfo info = const _ReignInfo();
      for (int j = i - 1; j >= 0; j--) {
        final newer = entries[j];
        if (newer.defeatedName == e.winner.name &&
            newer.defeatedAbility == e.winner.specialAbility) {
          info = _ReignInfo(defenseCount: newer.defeatedDefenseCount);
          break;
        }
      }
      if (i == 0 &&
          current != null &&
          current.monster.name == e.winner.name &&
          current.monster.specialAbility == e.winner.specialAbility) {
        info = _ReignInfo(
            defenseCount: current.defenseCount, isCurrent: true);
      }
      result[e.key] = info;
    }
    return result;
  }

  Future<void> _reportEntry(HistoryEntry entry) async {
    final reason = await showReportSheet(context);
    if (reason == null) return;
    await _reports.reportHistory(
      key: entry.key,
      winnerName: entry.winner.name,
      defeatedName: entry.defeatedName,
      defeatedAbility: entry.defeatedAbility,
      reason: reason,
    );
    if (!mounted) return;
    setState(() {
      _entries = _entries.where((e) => e.key != entry.key).toList();
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('通報を受け付けました。この記録はこの端末では非表示になります。'),
        duration: Duration(seconds: 3),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        child: SafeArea(
          child: Column(
            children: [
              _TopBar(
                title: 'チート年表',
                onBack: () => Navigator.maybePop(context),
                onReload: _load,
              ),
              Expanded(child: _body()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.yellow),
      );
    }
    if (_error != null) {
      return _ErrorView(message: _error!, onRetry: _load);
    }
    if (_entries.isEmpty) {
      return const _EmptyView();
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: _entries.length + (_hasMore ? 1 : 0),
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) {
        if (i >= _entries.length) {
          return _LoadMoreFooter(
            loading: _loadingMore,
            onTap: _loadingMore ? null : _loadMore,
          );
        }
        final entry = _entries[i];
        // Prefer the absolute rank from the running counter so pagination
        // doesn't renumber earlier entries. Fall back to the page-relative
        // ordinal when the counter is unavailable.
        final displayIndex =
            _totalCount != null ? _totalCount! - i : _entries.length - i;
        final reign = _reigns[entry.key] ?? const _ReignInfo();
        return _EntryCard(
          entry: entry,
          index: displayIndex,
          reign: reign,
          onReport: entry.key.isEmpty ? null : () => _reportEntry(entry),
        );
      },
    );
  }
}

class _LoadMoreFooter extends StatelessWidget {
  final bool loading;
  final VoidCallback? onTap;
  const _LoadMoreFooter({required this.loading, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Center(
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: AppColors.yellowDeep,
                ),
              )
            : TextButton(
                onPressed: onTap,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.ink,
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 10),
                ),
                child: const Text(
                  '以前の記録を読み込む',
                  style: TextStyle(
                    fontFamily: AppFonts.gothic,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2,
                  ),
                ),
              ),
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  final String title;
  final VoidCallback? onBack;
  final VoidCallback? onReload;
  const _TopBar({required this.title, this.onBack, this.onReload});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 4, 6, 10),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(Icons.chevron_left,
                color: AppColors.ink, size: 26),
          ),
          Expanded(
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: AppFonts.gothic,
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
          ),
          IconButton(
            onPressed: onReload,
            icon: const Icon(Icons.refresh,
                color: AppColors.inkMid, size: 22),
          ),
        ],
      ),
    );
  }
}

class _EntryCard extends StatelessWidget {
  final HistoryEntry entry;
  final int index;
  final _ReignInfo reign;
  final VoidCallback? onReport;
  const _EntryCard({
    required this.entry,
    required this.index,
    required this.reign,
    this.onReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.ink.withValues(alpha: 0.06),
            blurRadius: 14,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: 200,
            child: Stack(
              children: [
                Positioned.fill(
                  child: MonsterArt(
                    imageBytes: entry.winner.imageBytes,
                    radius: 0,
                  ),
                ),
                Positioned(
                  top: 10,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.ink.withValues(alpha: 0.75),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '#$index',
                      style: const TextStyle(
                        fontFamily: AppFonts.mono,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: AppColors.yellow,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ),
                if (onReport != null)
                  Positioned(
                    top: 6,
                    right: 6,
                    child: Material(
                      color: AppColors.ink.withValues(alpha: 0.55),
                      shape: const CircleBorder(),
                      child: InkWell(
                        customBorder: const CircleBorder(),
                        onTap: onReport,
                        child: const Padding(
                          padding: EdgeInsets.all(6),
                          child: Icon(Icons.flag_outlined,
                              size: 16, color: Colors.white),
                        ),
                      ),
                    ),
                  ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: Container(
                    padding: const EdgeInsets.fromLTRB(14, 30, 14, 12),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          AppColors.dark.withValues(alpha: 0.95),
                        ],
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.winner.name,
                          style: TextStyle(
                            fontFamily: AppFonts.gothic,
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.75),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          reign.isCurrent
                              ? '「? ? ? ? ?」'
                              : '「${entry.winner.specialAbility}」',
                          style: const TextStyle(
                            fontFamily: AppFonts.gothic,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.25,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          _ReignBanner(reign: reign),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (entry.defeatedName.isNotEmpty)
                  _DefeatedRow(
                    name: entry.defeatedName,
                    ability: entry.defeatedAbility,
                  )
                else
                  const _FirstReignBadge(),
                const SizedBox(height: 10),
                Text(
                  reign.isCurrent
                      ? 'この王座の顛末はまだ記されていない。'
                      : entry.narration,
                  style: TextStyle(
                    fontFamily: AppFonts.gothic,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: reign.isCurrent
                        ? AppColors.inkSoft
                        : AppColors.inkMid,
                    fontStyle: reign.isCurrent
                        ? FontStyle.italic
                        : FontStyle.normal,
                    height: 1.7,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _formatDate(entry.crownedAt),
                  style: const TextStyle(
                    fontFamily: AppFonts.mono,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(int millis) {
    if (millis <= 0) return '';
    final dt = DateTime.fromMillisecondsSinceEpoch(millis);
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$y-$m-$d $hh:$mm';
  }
}

class _DefeatedRow extends StatelessWidget {
  final String name;
  final String ability;
  const _DefeatedRow({
    required this.name,
    required this.ability,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.red.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '倒した',
            style: TextStyle(
              fontFamily: AppFonts.gothic,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.red,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontFamily: AppFonts.gothic,
                fontSize: 13,
                color: AppColors.ink,
              ),
              children: [
                TextSpan(
                  text: name,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const TextSpan(text: '  '),
                TextSpan(
                  text: '「$ability」',
                  style: const TextStyle(
                    color: AppColors.inkMid,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Prominent gold band shown right under the winner artwork. Displays how
/// many defenses this reign racked up before ending (or the running total,
/// if the champion is still on the throne).
class _ReignBanner extends StatelessWidget {
  final _ReignInfo reign;
  const _ReignBanner({required this.reign});

  @override
  Widget build(BuildContext context) {
    final count = reign.defenseCount;
    final label = _labelFor(count, reign.isCurrent);
    final labelColor = reign.isCurrent
        ? const Color(0xFF1A1400)
        : AppColors.yellowDeep;
    final bg = reign.isCurrent
        ? AppColors.yellow
        : AppColors.yellowSoft;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(color: bg),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shield, size: 16, color: labelColor),
          const SizedBox(width: 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: AppFonts.gothic,
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: labelColor,
              letterSpacing: 2,
            ),
          ),
          if (reign.isCurrent) ...[
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1400),
                borderRadius: BorderRadius.circular(4),
              ),
              child: const Text(
                '現王座',
                style: TextStyle(
                  fontFamily: AppFonts.gothic,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                  color: AppColors.yellow,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  static String _labelFor(int? count, bool isCurrent) {
    if (count == null) return isCurrent ? '防衛回数 —' : '防衛回数 不明';
    if (isCurrent) return '防衛 $count 回 継続中';
    if (count == 0) return '即位直後に陥落';
    return '在位中 防衛 $count 回';
  }
}

class _FirstReignBadge extends StatelessWidget {
  const _FirstReignBadge();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.yellowSoft,
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Text(
            '初代',
            style: TextStyle(
              fontFamily: AppFonts.gothic,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: AppColors.yellowDeep,
              letterSpacing: 1,
            ),
          ),
        ),
        const SizedBox(width: 8),
        const Text(
          '最初の王者',
          style: TextStyle(
            fontFamily: AppFonts.gothic,
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: AppColors.ink,
          ),
        ),
      ],
    );
  }
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.auto_stories_outlined,
                size: 48, color: AppColors.inkSoft),
            SizedBox(height: 14),
            Text(
              'まだ王座の記録はない',
              style: TextStyle(
                fontFamily: AppFonts.gothic,
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.ink,
              ),
            ),
            SizedBox(height: 4),
            Text(
              '王者を倒してチートの歴史を刻もう',
              style: TextStyle(
                fontFamily: AppFonts.gothic,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: AppColors.inkMid,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.wifi_off_outlined,
              size: 48, color: AppColors.inkSoft),
          const SizedBox(height: 12),
          Text(
            message,
            style: const TextStyle(
              fontFamily: AppFonts.gothic,
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: onRetry,
            child: const Text(
              'もう一度',
              style: TextStyle(
                fontFamily: AppFonts.gothic,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
