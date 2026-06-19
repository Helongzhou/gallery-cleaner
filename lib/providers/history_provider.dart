import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/history_entry.dart';
import '../services/history_service.dart';
import '../shared/result.dart';
import 'providers.dart';

final historyServiceProvider = Provider(
  (ref) => HistoryService(
    ref.watch(organizeRepositoryProvider),
    ref.watch(photoLibraryServiceProvider),
  ),
);

final homeRefreshProvider = StateProvider<int>((ref) => 0);

class HistoryState {
  const HistoryState({
    this.entries = const [],
    this.loading = false,
  });

  final List<HistoryEntry> entries;
  final bool loading;

  bool get hasEntries => entries.isNotEmpty;

  HistoryState copyWith({
    List<HistoryEntry>? entries,
    bool? loading,
  }) {
    return HistoryState(
      entries: entries ?? this.entries,
      loading: loading ?? this.loading,
    );
  }
}

final historyProvider = StateNotifierProvider<HistoryController, HistoryState>((ref) {
  return HistoryController(ref.watch(historyServiceProvider), ref);
});

final historyBadgeProvider = Provider<bool>((ref) {
  return ref.watch(historyProvider).hasEntries;
});

class HistoryController extends StateNotifier<HistoryState> {
  HistoryController(this._service, this._ref) : super(const HistoryState()) {
    refresh();
  }

  final HistoryService _service;
  final Ref _ref;

  Future<void> refresh() async {
    state = state.copyWith(loading: true);
    final entries = await _service.loadEntries();
    state = HistoryState(entries: entries, loading: false);
  }

  Future<String?> undo(int recordId) async {
    final result = await _service.undoEntry(recordId);
    if (result is AppFailure<void>) {
      return result.message;
    }
    await refresh();
    _ref.read(homeRefreshProvider.notifier).state++;
    return null;
  }
}
