import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/album_info.dart';
import '../../models/photo_permission_status.dart';
import '../../providers/history_provider.dart';
import '../../providers/library_tab_state.dart';
import '../../providers/providers.dart';
import '../../router/app_router.dart';
import '../../router/routes.dart';
import '../../shared/constants/organize_mode.dart';
import '../../shared/constants/strings.dart';
import '../../shared/result.dart';
import '../../shared/theme/app_theme.dart';
import '../../shared/widgets/album_source_card.dart';
import '../../shared/widgets/album_target_carousel.dart';
import '../../shared/widgets/error_view.dart';
import '../../shared/widgets/header_action_button.dart';
import '../../shared/widgets/large_title_header.dart';
import '../../shared/widgets/limited_access_banner.dart';
import '../../shared/widgets/loading_view.dart';
import '../../shared/widgets/pending_delete_entry.dart';
import 'album_picker_sheet.dart';
import 'widgets/history_drawer.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  bool _loading = true;
  String? _error;
  PhotoPermissionStatus? _permission;
  List<AlbumInfo> _allAlbums = [];
  List<AlbumInfo> _writableAlbums = [];
  AlbumInfo? _source;
  String _targetSelectionId = OrganizeMode.deleteOnlyTargetId;
  int _pendingDeleteCount = 0;
  int _pendingOrganizeCount = 0;
  String? _activeSessionHint;
  Uint8List? _sourceCover;
  final Map<String, Uint8List?> _targetCovers = {};
  final Map<String, int> _pendingByAlbum = {};
  bool _restoredTarget = false;

  bool get _isDeleteOnly => OrganizeMode.isDeleteOnly(_targetSelectionId);

  AlbumInfo? get _targetAlbum {
    if (_isDeleteOnly) return null;
    for (final a in _writableAlbums) {
      if (a.id == _targetSelectionId) return a;
    }
    return null;
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    final photoService = ref.read(photoLibraryServiceProvider);
    final organizeRepo = ref.read(organizeRepositoryProvider);
    final sessionService = ref.read(sessionServiceProvider);
    final settings = ref.read(settingsRepositoryProvider);

    final permission = await photoService.requestPermission();
    if (permission == PhotoPermissionStatus.denied) {
      if (mounted) context.push(AppRoutes.permissionDenied);
      return;
    }

    final allAlbumsResult = await photoService.listAlbums();
    final writableAlbumsResult = await photoService.listAlbums(writableOnly: true);
    final pendingDelete = await organizeRepo.pendingDeleteCount();
    final activeSession = await sessionService.getActiveSession();
    final savedTargetId = await settings.getLastTargetAlbumId();

    if (!mounted) return;

    if (allAlbumsResult is AppFailure<List<AlbumInfo>>) {
      setState(() {
        _loading = false;
        _error = allAlbumsResult.message;
      });
      return;
    }

    final allAlbums = (allAlbumsResult as AppSuccess<List<AlbumInfo>>).value;
    final writableAlbums = writableAlbumsResult is AppSuccess<List<AlbumInfo>>
        ? writableAlbumsResult.value
        : <AlbumInfo>[];

    final source = _source ?? (allAlbums.isNotEmpty ? allAlbums.first : null);

    var targetSelectionId = _targetSelectionId;
    if (!_restoredTarget) {
      if (savedTargetId != null) {
        targetSelectionId = savedTargetId;
      }
      _restoredTarget = true;
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

    if (!mounted) return;

    setState(() {
      _loading = false;
      _permission = permission;
      _allAlbums = allAlbums;
      _writableAlbums = writableAlbums;
      _source = source;
      _targetSelectionId = targetSelectionId;
      _pendingDeleteCount = pendingDelete;
      _pendingOrganizeCount = pendingOrganize;
      _pendingByAlbum
        ..clear()
        ..addAll(pendingByAlbum);
      _sourceCover = sourceCover;
      _targetCovers
        ..clear()
        ..addAll(targetCovers);
      _activeSessionHint = activeSession == null
          ? null
          : '继续整理「${_albumName(activeSession.sourceAlbumId)}」？还剩 $pendingOrganize 张';
    });

    _syncLibraryTabState();
  }

  void _syncLibraryTabState() {
    final canStart = _pendingOrganizeCount > 0 && _source != null;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(libraryTabStateProvider.notifier).state = LibraryTabState(
        canStart: canStart,
        buttonLabel: canStart ? AppStrings.startOrganize : AppStrings.allOrganized,
        onStart: canStart ? () => _start() : null,
      );
    });
  }

  Future<void> _selectTarget(String id) async {
    setState(() => _targetSelectionId = id);
    await ref.read(settingsRepositoryProvider).setLastTargetAlbumId(id);
    _syncLibraryTabState();
  }

  String _albumName(String id) {
    return _allAlbums
        .firstWhere((a) => a.id == id, orElse: () => AlbumInfo(id: id, name: id, assetCount: 0))
        .name;
  }

  Future<void> _pickSource() async {
    final picked = await showAlbumPickerSheet(
      context: context,
      title: '选择来源相册',
      albums: _allAlbums,
      pendingCounts: _pendingByAlbum,
      selectedId: _source?.id,
    );
    if (picked == null) return;
    setState(() => _source = picked);
    await _load();
  }

  Future<void> _pickTarget({bool viewAll = false}) async {
    final picked = await showAlbumPickerSheet(
      context: context,
      title: viewAll ? '全部目标相册' : '选择目标相册',
      albums: _writableAlbums,
      pendingCounts: _pendingByAlbum,
      selectedId: _isDeleteOnly ? null : _targetSelectionId,
    );
    if (picked == null) return;
    await _selectTarget(picked.id);
  }

  Future<void> _createAlbum() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(AppStrings.createAlbum),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(hintText: '输入相册名称'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('创建'),
          ),
        ],
      ),
    );
    if (name == null || name.isEmpty) return;

    final result = await ref.read(photoLibraryServiceProvider).createAlbum(name);
    if (!mounted) return;
    if (result is AppFailure<AlbumInfo>) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result.message)));
      return;
    }
    final album = (result as AppSuccess<AlbumInfo>).value;
    await _load();
    await _selectTarget(album.id);
  }

  Future<void> _start({bool continueSession = false}) async {
    final source = _source;
    if (source == null) return;

    final sessionService = ref.read(sessionServiceProvider);
    final targetId = _isDeleteOnly ? OrganizeMode.deleteOnlyTargetId : _targetAlbum!.id;

    final session = continueSession
        ? await sessionService.getActiveSession()
        : await sessionService.startSession(
            sourceAlbumId: source.id,
            targetAlbumId: targetId,
          );

    if (session == null) return;
    if (!mounted) return;

    final processed = await ref.read(organizeRepositoryProvider).getProcessedIds(source.id);
    final pending = source.assetCount - processed.length;
    if (!mounted) return;

    context.push(
      AppRoutes.swipe,
      extra: SwipeRouteArgs(
        sessionId: session.sessionId,
        sourceAlbumId: source.id,
        sourceAlbumName: source.name,
        targetAlbumId: _isDeleteOnly ? null : _targetAlbum?.id,
        targetAlbumName: _isDeleteOnly ? '仅删除' : _targetAlbum?.name,
        totalCount: pending > 0 ? pending : source.assetCount,
        initialIndex: 0,
        deleteOnly: _isDeleteOnly,
      ),
    );
  }

  Future<void> _reorganize() async {
    final source = _source;
    if (source == null) return;
    await ref.read(organizeRepositoryProvider).clearProcessed(source.id);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(homeRefreshProvider, (previous, next) {
      if (previous != next) _load();
    });

    if (_loading) {
      return Scaffold(
        backgroundColor: context.appBackground,
        body: const LoadingView(message: '加载相册...'),
      );
    }
    if (_error != null) {
      return Scaffold(
        backgroundColor: context.appBackground,
        body: ErrorView(message: _error!, onRetry: _load),
      );
    }

    final source = _source;
    final showHistoryBadge = ref.watch(historyBadgeProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: _load,
          child: CustomScrollView(
            slivers: [
              LargeTitleHeader(
                title: AppStrings.appTitle,
                trailing: HeaderActionButton(
                  key: const Key('home_history_button'),
                  icon: Icons.history,
                  showBadge: showHistoryBadge,
                  semanticLabel: '整理历史',
                  onTap: () {
                    ref.read(historyProvider.notifier).refresh();
                    showHistoryDrawer(context);
                  },
                ),
              ),
              if (_permission == PhotoPermissionStatus.limited)
                SliverToBoxAdapter(
                  child: LimitedAccessBanner(
                    onAddMore: () => ref.read(photoLibraryServiceProvider).presentLimitedLibraryPicker(),
                  ),
                ),
              if (_activeSessionHint != null && _pendingOrganizeCount > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Material(
                      color: context.appPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        title: Text(_activeSessionHint!, style: TextStyle(color: context.appPrimary)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _start(continueSession: true),
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                  child: Text('来源相册', style: Theme.of(context).textTheme.titleMedium),
                ),
              ),
              if (source != null)
                SliverToBoxAdapter(
                  child: AlbumSourceCard(
                    albumName: source.name,
                    totalCount: source.assetCount,
                    pendingCount: _pendingOrganizeCount,
                    coverBytes: _sourceCover,
                    onTap: _pickSource,
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: AlbumTargetCarousel(
                    albums: _writableAlbums.map((a) => (id: a.id, name: a.name)).toList(),
                    selectedId: _targetSelectionId,
                    thumbnails: _targetCovers,
                    onSelect: _selectTarget,
                    onCreate: _createAlbum,
                    onViewAll: () => _pickTarget(viewAll: true),
                  ),
                ),
              ),
              if (_pendingOrganizeCount == 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton(
                      onPressed: _reorganize,
                      child: const Text(AppStrings.reorganize),
                    ),
                  ),
                ),
              if (_pendingDeleteCount > 0)
                SliverToBoxAdapter(
                  child: PendingDeleteEntry(
                    count: _pendingDeleteCount,
                    onTap: () => context.push(AppRoutes.pendingDelete),
                  ),
                ),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}
