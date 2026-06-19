import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/history_entry.dart';
import '../models/history_session.dart';
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
    this.sessions = const [],
    this.sessionEntries = const [],
    this.selectedSessionId,
    this.loading = false,
    this.sessionLoading = false,
  });

  final List<HistorySession> sessions;
  final List<HistoryEntry> sessionEntries;
  final String? selectedSessionId;
  final bool loading;
  final bool sessionLoading;

  bool get hasEntries => sessions.isNotEmpty;

  HistorySession? get selectedSession {
    if (selectedSessionId == null) return null;
    for (final session in sessions) {
      if (session.sessionId == selectedSessionId) return session;
    }
    return null;
  }

  HistoryState copyWith({
    List<HistorySession>? sessions,
    List<HistoryEntry>? sessionEntries,
    String? selectedSessionId,
    bool? loading,
    bool? sessionLoading,
    bool clearSelection = false,
  }) {
    return HistoryState(
      sessions: sessions ?? this.sessions,
      sessionEntries: sessionEntries ?? this.sessionEntries,
      selectedSessionId:
          clearSelection ? null : (selectedSessionId ?? this.selectedSessionId),
      loading: loading ?? this.loading,
      sessionLoading: sessionLoading ?? this.sessionLoading,
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
    final selectedId = state.selectedSessionId;
    state = state.copyWith(loading: true);
    final sessions = await _service.loadSessions();
    state = state.copyWith(sessions: sessions, loading: false);
    if (selectedId != null) {
      final stillExists = sessions.any((s) => s.sessionId == selectedId);
      if (stillExists) {
        await openSession(selectedId);
      } else {
        state = state.copyWith(clearSelection: true, sessionEntries: []);
      }
    }
  }

  Future<void> openSession(String sessionId) async {
    state = state.copyWith(
      selectedSessionId: sessionId,
      sessionLoading: true,
      sessionEntries: [],
    );
    final entries = await _service.loadSessionEntries(sessionId);
    state = state.copyWith(sessionEntries: entries, sessionLoading: false);
  }

  void closeSession() {
    state = state.copyWith(clearSelection: true, sessionEntries: []);
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
