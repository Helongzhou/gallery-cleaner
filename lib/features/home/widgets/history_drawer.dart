import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/history_entry.dart';
import '../../../models/history_session.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/providers.dart';
import '../../../shared/constants/app_motion.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
import '../../../shared/utils/formatters.dart';
import '../../../shared/widgets/top_toast.dart';

Future<void> showHistoryDrawer(BuildContext context) {
  return showGeneralDialog<void>(
    context: context,
    barrierDismissible: true,
    barrierLabel: '历史记录',
    barrierColor: Colors.black.withValues(alpha: 0.35),
    transitionDuration: AppMotion.panelDuration,
    pageBuilder: (context, animation, secondaryAnimation) {
      return const _HistoryDrawerPanel();
    },
    transitionBuilder: (context, animation, secondaryAnimation, child) {
      final offset = Tween<Offset>(
        begin: const Offset(1, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: AppMotion.panelCurve));
      return SlideTransition(position: offset, child: child);
    },
  );
}

class _HistoryDrawerPanel extends ConsumerStatefulWidget {
  const _HistoryDrawerPanel();

  @override
  ConsumerState<_HistoryDrawerPanel> createState() => _HistoryDrawerPanelState();
}

class _HistoryDrawerPanelState extends ConsumerState<_HistoryDrawerPanel> {
  @override
  void dispose() {
    ref.read(historyProvider.notifier).closeSession();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(historyProvider);
    final scheme = Theme.of(context).colorScheme;
    final inDetail = state.selectedSessionId != null;

    return Align(
      alignment: Alignment.centerRight,
      child: Material(
        color: context.appSurfaceContainerLowest,
        child: SizedBox(
          width: MediaQuery.sizeOf(context).width * 0.55,
          height: double.infinity,
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 12, 8, 8),
                  child: Row(
                    children: [
                      if (inDetail)
                        IconButton(
                          onPressed: () => ref.read(historyProvider.notifier).closeSession(),
                          icon: const Icon(Icons.arrow_back),
                          tooltip: '返回',
                        ),
                      Expanded(
                        child: Text(
                          inDetail ? '会话详情' : '整理历史',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.pop(context),
                        icon: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    inDetail
                        ? (state.selectedSession?.statsLabel ?? '')
                        : '最近 ${state.sessions.length} 次整理，点击查看照片',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: state.loading
                      ? const Center(child: CircularProgressIndicator())
                      : inDetail
                          ? _SessionDetailList(state: state)
                          : _SessionTimelineList(sessions: state.sessions),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SessionTimelineList extends ConsumerWidget {
  const _SessionTimelineList({required this.sessions});

  final List<HistorySession> sessions;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (sessions.isEmpty) {
      return Center(
        child: Text(
          '暂无整理记录',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: sessions.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _SessionTimelineRow(
          session: session,
          onTap: () => ref.read(historyProvider.notifier).openSession(session.sessionId),
        );
      },
    );
  }
}

class _SessionTimelineRow extends StatelessWidget {
  const _SessionTimelineRow({required this.session, required this.onTap});

  final HistorySession session;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Material(
      color: context.appSurfaceContainerLow,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.md),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppRadius.md),
            border: Border.all(color: context.appOutlineVariant.withValues(alpha: 0.35)),
          ),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 48,
                decoration: BoxDecoration(
                  color: context.appPrimary.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatHistorySessionTime(session.lastActionAt),
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      session.routeLabel,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (session.statsLabel.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        session.statsLabel,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: context.appAccent,
                            ),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _SessionDetailList extends ConsumerWidget {
  const _SessionDetailList({required this.state});

  final HistoryState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (state.sessionLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (state.sessionEntries.isEmpty) {
      return Center(
        child: Text(
          '该会话暂无照片记录',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: state.sessionEntries.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final entry = state.sessionEntries[index];
        return _HistoryRow(
          entry: entry,
          onUndo: () async {
            final error = await ref.read(historyProvider.notifier).undo(entry.recordId!);
            if (!context.mounted) return;
            if (error != null) {
              TopToast.show(context, message: error);
            } else {
              TopToastInfo.show(context, '已反悔');
            }
          },
        );
      },
    );
  }
}

class _HistoryRow extends ConsumerStatefulWidget {
  const _HistoryRow({required this.entry, required this.onUndo});

  final HistoryEntry entry;
  final Future<void> Function() onUndo;

  @override
  ConsumerState<_HistoryRow> createState() => _HistoryRowState();
}

class _HistoryRowState extends ConsumerState<_HistoryRow> {
  Uint8List? _thumb;

  @override
  void initState() {
    super.initState();
    _loadThumb();
  }

  @override
  void didUpdateWidget(covariant _HistoryRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.entry.assetId != widget.entry.assetId) {
      _loadThumb();
    }
  }

  Future<void> _loadThumb() async {
    final bytes = await ref.read(photoLibraryServiceProvider).getThumbnail(
          assetId: widget.entry.assetId,
          width: 96,
          height: 96,
        );
    if (mounted) setState(() => _thumb = bytes);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: context.appSurfaceContainerLow,
        borderRadius: BorderRadius.circular(AppRadius.md),
        border: Border.all(color: context.appOutlineVariant.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: context.appSurfaceContainerHigh,
              borderRadius: BorderRadius.circular(8),
            ),
            child: _thumb != null
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.memory(_thumb!, fit: BoxFit.cover),
                  )
                : Icon(Icons.image_outlined, color: context.appPrimary.withValues(alpha: 0.5)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(widget.entry.label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          TextButton(
            key: Key('history_undo_${widget.entry.recordId}'),
            onPressed: widget.onUndo,
            child: const Text('反悔'),
          ),
        ],
      ),
    );
  }
}
