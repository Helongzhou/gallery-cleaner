import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/album_info.dart';
import '../models/photo_permission_status.dart';
import '../shared/constants/organize_mode.dart';
import '../shared/constants/strings.dart';
import '../shared/result.dart';
import '../shared/utils/source_album_resolver.dart';
import 'library_tab_state.dart';
import 'providers.dart';

class HomeState {
  const HomeState({
    this.isInitialLoading = false,
    this.isRefreshing = false,
    this.error,
    this.permission,
    this.allAlbums = const [],
    this.writableAlbums = const [],
    this.source,
    this.targetSelectionId = OrganizeMode.deleteOnlyTargetId,
    this.pendingDeleteCount = 0,
    this.pendingOrganizeCount = 0,
    this.activeSessionHint,
    this.sourceCover,
    this.targetCovers = const {},
    this.pendingByAlbum = const {},
    this.restoredTarget = false,
  });

  static const Object _unset = Object();

  final bool isInitialLoading;
  final bool isRefreshing;
  final String? error;
  final PhotoPermissionStatus? permission;
  final List<AlbumInfo> allAlbums;
  final List<AlbumInfo> writableAlbums;
  final AlbumInfo? source;
  final String targetSelectionId;
  final int pendingDeleteCount;
  final int pendingOrganizeCount;
  final String? activeSessionHint;
  final Uint8List? sourceCover;
  final Map<String, Uint8List?> targetCovers;
  final Map<String, int> pendingByAlbum;
  final bool restoredTarget;

  bool get hasData => allAlbums.isNotEmpty;

  bool get isDeleteOnly => OrganizeMode.isDeleteOnly(targetSelectionId);

  AlbumInfo? get targetAlbum {
    if (isDeleteOnly) return null;
    for (final a in writableAlbums) {
      if (a.id == targetSelectionId) return a;
    }
    return null;
  }

  HomeState copyWith({
    bool? isInitialLoading,
    bool? isRefreshing,
    String? error,
    bool clearError = false,
    PhotoPermissionStatus? permission,
    List<AlbumInfo>? allAlbums,
    List<AlbumInfo>? writableAlbums,
    Object? source = _unset,
    String? targetSelectionId,
    int? pendingDeleteCount,
    int? pendingOrganizeCount,
    String? activeSessionHint,
    Uint8List? sourceCover,
    Map<String, Uint8List?>? targetCovers,
    Map<String, int>? pendingByAlbum,
    bool? restoredTarget,
  }) {
    return HomeState(
      isInitialLoading: isInitialLoading ?? this.isInitialLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      error: clearError ? null : (error ?? this.error),
      permission: permission ?? this.permission,
      allAlbums: allAlbums ?? this.allAlbums,
      writableAlbums: writableAlbums ?? this.writableAlbums,
      source: source == _unset ? this.source : source as AlbumInfo?,
      targetSelectionId: targetSelectionId ?? this.targetSelectionId,
      pendingDeleteCount: pendingDeleteCount ?? this.pendingDeleteCount,
      pendingOrganizeCount: pendingOrganizeCount ?? this.pendingOrganizeCount,
      activeSessionHint: activeSessionHint ?? this.activeSessionHint,
      sourceCover: sourceCover ?? this.sourceCover,
      targetCovers: targetCovers ?? this.targetCovers,
      pendingByAlbum: pendingByAlbum ?? this.pendingByAlbum,
      restoredTarget: restoredTarget ?? this.restoredTarget,
    );
  }
}

final homeControllerProvider = StateNotifierProvider<HomeController, HomeState>((ref) {
  return HomeController(ref);
});

class HomeController extends StateNotifier<HomeState> {
  HomeController(this._ref) : super(const HomeState());

  final Ref _ref;

  Future<void> load({bool silent = false}) async {
    if (!silent || !state.hasData) {
      state = state.copyWith(
        isInitialLoading: !state.hasData,
        isRefreshing: silent && state.hasData,
        clearError: true,
      );
    } else {
      state = state.copyWith(isRefreshing: true, clearError: true);
    }

    final photoService = _ref.read(photoLibraryServiceProvider);
    final organizeRepo = _ref.read(organizeRepositoryProvider);
    final sessionService = _ref.read(sessionServiceProvider);
    final settings = _ref.read(settingsRepositoryProvider);

    final permission = await photoService.requestPermission();
    if (permission == PhotoPermissionStatus.denied) {
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        permission: permission,
        error: 'permission_denied',
      );
      return;
    }

    final allAlbumsResult = await photoService.listAlbums();
    final writableAlbumsResult = await photoService.listAlbums(writableOnly: true);
    final pendingDelete = await organizeRepo.pendingDeleteCount();
    final activeSession = await sessionService.getActiveSession();
    final savedSourceId = await settings.getLastSourceAlbumId();
    final savedTargetId = await settings.getLastTargetAlbumId();

    if (allAlbumsResult is AppFailure<List<AlbumInfo>>) {
      state = state.copyWith(
        isInitialLoading: false,
        isRefreshing: false,
        error: allAlbumsResult.message,
      );
      return;
    }

    final allAlbums = (allAlbumsResult as AppSuccess<List<AlbumInfo>>).value;
    final writableAlbums = writableAlbumsResult is AppSuccess<List<AlbumInfo>>
        ? writableAlbumsResult.value
        : <AlbumInfo>[];

    final source = resolveSourceAlbum(allAlbums, preferredId: savedSourceId);
    if (source != null && savedSourceId == null) {
      await settings.setLastSourceAlbumId(source.id);
    }

    var targetSelectionId = state.targetSelectionId;
    var restoredTarget = state.restoredTarget;
    if (!restoredTarget) {
      if (savedTargetId != null) {
        targetSelectionId = savedTargetId;
      }
      restoredTarget = true;
    }
    if (OrganizeMode.isDeleteOnly(targetSelectionId)) {
      targetSelectionId = OrganizeMode.deleteOnlyTargetId;
    } else if (!writableAlbums.any((a) => a.id == targetSelectionId)) {
      targetSelectionId = OrganizeMode.deleteOnlyTargetId;
    }

    final pendingByAlbum = <String, int>{};
    for (final album in allAlbums) {
      final processed = await organizeRepo.getProcessedIds(album.id);
      var pending = album.assetCount - processed.length;
      if (pending < 0) pending = 0;
      pendingByAlbum[album.id] = pending;
    }

    final pendingOrganize = source != null ? pendingByAlbum[source.id] ?? 0 : 0;

    Uint8List? sourceCover;
    if (source != null) {
      sourceCover = await photoService.getAlbumCover(source.id);
    }

    final targetCovers = <String, Uint8List?>{};
    for (final album in writableAlbums.take(8)) {
      targetCovers[album.id] = await photoService.getAlbumCover(album.id, size: 224);
    }

    final sessionHint = activeSession == null
        ? null
        : '继续整理「${_albumName(allAlbums, activeSession.sourceAlbumId)}」？还剩 $pendingOrganize 张';

    state = state.copyWith(
      isInitialLoading: false,
      isRefreshing: false,
      permission: permission,
      allAlbums: allAlbums,
      writableAlbums: writableAlbums,
      source: source,
      targetSelectionId: targetSelectionId,
      pendingDeleteCount: pendingDelete,
      pendingOrganizeCount: pendingOrganize,
      pendingByAlbum: pendingByAlbum,
      sourceCover: sourceCover,
      targetCovers: targetCovers,
      activeSessionHint: sessionHint,
      restoredTarget: restoredTarget,
    );
  }

  void syncLibraryTab({VoidCallback? onStart}) {
    final hasValidTarget = state.isDeleteOnly || state.targetAlbum != null;
    final canStart = state.pendingOrganizeCount > 0 && state.source != null && hasValidTarget;
    _ref.read(libraryTabStateProvider.notifier).updateTab(
          canStart: canStart,
          buttonLabel: canStart ? AppStrings.startOrganize : AppStrings.allOrganized,
          onStart: canStart ? onStart : null,
        );
  }

  void refreshLibraryTabState() {
    final hasValidTarget = state.isDeleteOnly || state.targetAlbum != null;
    final canStart = state.pendingOrganizeCount > 0 && state.source != null && hasValidTarget;
    _ref.read(libraryTabStateProvider.notifier).updateTabState(
          canStart: canStart,
          buttonLabel: canStart ? AppStrings.startOrganize : AppStrings.allOrganized,
        );
  }

  Future<bool> selectTarget(String id) async {
    if (!OrganizeMode.isDeleteOnly(id) && !state.writableAlbums.any((a) => a.id == id)) {
      return false;
    }
    state = state.copyWith(targetSelectionId: id);
    await _ref.read(settingsRepositoryProvider).setLastTargetAlbumId(id);
    return true;
  }

  Future<void> setSource(AlbumInfo source) async {
    state = state.copyWith(source: source);
    await _ref.read(settingsRepositoryProvider).setLastSourceAlbumId(source.id);
  }

  String albumName(String id) {
    return _albumName(state.allAlbums, id);
  }

  String _albumName(List<AlbumInfo> albums, String id) {
    return albums
        .firstWhere((a) => a.id == id, orElse: () => AlbumInfo(id: id, name: id, assetCount: 0))
        .name;
  }
}
