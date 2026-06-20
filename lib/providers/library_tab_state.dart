import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryTabState {
  const LibraryTabState({
    this.canStart = false,
    this.buttonLabel = '开始整理',
  });

  final bool canStart;
  final String buttonLabel;

  LibraryTabState copyWith({
    bool? canStart,
    String? buttonLabel,
  }) {
    return LibraryTabState(
      canStart: canStart ?? this.canStart,
      buttonLabel: buttonLabel ?? this.buttonLabel,
    );
  }
}

class LibraryTabController extends StateNotifier<LibraryTabState> {
  LibraryTabController() : super(const LibraryTabState());

  VoidCallback? _startHandler;

  void setStartHandler(VoidCallback? handler) {
    _startHandler = handler;
  }

  void startOrganize() {
    _startHandler?.call();
  }

  void updateTab({required bool canStart, required String buttonLabel, VoidCallback? onStart}) {
    setStartHandler(onStart);
    state = LibraryTabState(canStart: canStart, buttonLabel: buttonLabel);
  }

  void updateTabState({required bool canStart, required String buttonLabel}) {
    state = state.copyWith(canStart: canStart, buttonLabel: buttonLabel);
  }
}

final libraryTabStateProvider =
    StateNotifierProvider<LibraryTabController, LibraryTabState>((ref) {
  return LibraryTabController();
});
