import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/history_entry.dart';
import '../../../providers/history_provider.dart';
import '../../../providers/providers.dart';
import '../../../shared/constants/app_motion.dart';
import '../../../shared/theme/app_colors.dart';
import '../../../shared/theme/app_theme.dart';
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

class _HistoryDrawerPanel extends ConsumerWidget {
  const _HistoryDrawerPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(historyProvider);
    final scheme = Theme.of(context).colorScheme;

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
                  padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text('整理历史', style: Theme.of(context).textTheme.titleMedium),
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
                    '最近 ${state.entries.length} 条操作，可逐条反悔',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: state.loading
                      ? const Center(child: CircularProgressIndicator())
                      : state.entries.isEmpty
                          ? Center(
                              child: Text(
                                '暂无整理记录',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: scheme.onSurfaceVariant,
                                    ),
                              ),
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                              itemCount: state.entries.length,
                              separatorBuilder: (_, _) => const SizedBox(height: 10),
                              itemBuilder: (context, index) {
                                final entry = state.entries[index];
                                return _HistoryRow(
                                  entry: entry,
                                  onUndo: () async {
                                    final error = await ref
                                        .read(historyProvider.notifier)
                                        .undo(entry.recordId!);
                                    if (!context.mounted) return;
                                    if (error != null) {
                                      TopToast.show(context, message: error);
                                    } else {
                                      TopToastInfo.show(context, '已反悔');
                                    }
                                  },
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ),
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
