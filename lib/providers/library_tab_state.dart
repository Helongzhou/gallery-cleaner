import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LibraryTabState {
  const LibraryTabState({
    this.canStart = false,
    this.buttonLabel = '开始整理',
    this.onStart,
  });

  final bool canStart;
  final String buttonLabel;
  final VoidCallback? onStart;

  LibraryTabState copyWith({
    bool? canStart,
    String? buttonLabel,
    VoidCallback? onStart,
  }) {
    return LibraryTabState(
      canStart: canStart ?? this.canStart,
      buttonLabel: buttonLabel ?? this.buttonLabel,
      onStart: onStart ?? this.onStart,
    );
  }
}

final libraryTabStateProvider = StateProvider<LibraryTabState>((ref) => const LibraryTabState());
