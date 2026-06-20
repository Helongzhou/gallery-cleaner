import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../models/album_info.dart';
import '../../models/photo_permission_status.dart';
import '../../providers/history_provider.dart';
import '../../providers/home_provider.dart';
import '../../providers/library_tab_state.dart';
import '../../providers/providers.dart';
import '../../router/app_router.dart';
import '../../router/routes.dart';
import '../../shared/constants/organize_constants.dart';
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
  late final LibraryTabController _libraryTab;

  @override
  void initState() {
    super.initState();
    _libraryTab = ref.read(libraryTabStateProvider.notifier);
    WidgetsBinding.instance.addPostFrameCallback((_) => _bootstrap());
  }

  @override
  void dispose() {
    _libraryTab.setStartHandler(null);
    super.dispose();
  }

  void _bootstrap() {
    if (!mounted) return;
    final home = ref.read(homeControllerProvider);
    ref.read(homeControllerProvider.notifier).load(silent: home.hasData);
  }

  Future<void> _load({bool silent = false}) async {
    await ref.read(homeControllerProvider.notifier).load(silent: silent);
    if (!mounted) return;
    final error = ref.read(homeControllerProvider).error;
    if (error == 'permission_denied') {
      context.push(AppRoutes.permissionDenied);
      return;
    }
    ref.read(homeControllerProvider.notifier).syncLibraryTab(onStart: _start);
  }

  Future<void> _pickSource(HomeState home) async {
    final picked = await showAlbumPickerSheet(
      context: context,
      title: '选择来源相册',
      albums: home.allAlbums,
      pendingCounts: home.pendingByAlbum,
      selectedId: home.source?.id,
    );
    if (picked == null) return;
    ref.read(homeControllerProvider.notifier).setSource(picked);
    await _load(silent: true);
  }

  Future<void> _pickTarget(HomeState home, {bool viewAll = false}) async {
    final picked = await showAlbumPickerSheet(
      context: context,
      title: viewAll ? '全部目标相册' : '选择目标相册',
      albums: home.writableAlbums,
      pendingCounts: home.pendingByAlbum,
      selectedId: home.isDeleteOnly ? null : home.targetSelectionId,
    );
    if (picked == null) return;
    final ok = await ref.read(homeControllerProvider.notifier).selectTarget(picked.id);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法使用该相册作为目标，请选择其他相册')),
      );
    }
    ref.read(homeControllerProvider.notifier).syncLibraryTab(onStart: _start);
  }

  Future<void> _selectTarget(String id) async {
    final ok = await ref.read(homeControllerProvider.notifier).selectTarget(id);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('无法使用该相册作为目标，请选择其他相册')),
      );
    }
    ref.read(homeControllerProvider.notifier).syncLibraryTab(onStart: _start);
  }

  Future<void> _createAlbum() async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final trimmed = controller.text.trim();
          final canCreate = trimmed.isNotEmpty && trimmed.length <= OrganizeConstants.maxAlbumNameLength;
          return AlertDialog(
            title: const Text(AppStrings.createAlbum),
            content: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: '输入相册名称',
                counterText: '${trimmed.length}/${OrganizeConstants.maxAlbumNameLength}',
              ),
              autofocus: true,
              maxLength: OrganizeConstants.maxAlbumNameLength,
              onChanged: (_) => setDialogState(() {}),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('取消')),
              FilledButton(
                onPressed: canCreate ? () => Navigator.pop(context, trimmed) : null,
                child: const Text('创建'),
              ),
            ],
          );
        },
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
    await _load(silent: true);
    await _selectTarget(album.id);
  }

  Future<void> _start({bool continueSession = false}) async {
    if (!mounted) return;
    final home = ref.read(homeControllerProvider);
    final source = home.source;
    if (source == null) return;

    if (!home.isDeleteOnly && home.targetAlbum == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先选择有效的目标相册')),
      );
      return;
    }

    final sessionService = ref.read(sessionServiceProvider);
    final targetId = home.isDeleteOnly ? OrganizeMode.deleteOnlyTargetId : home.targetAlbum!.id;

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
        targetAlbumId: home.isDeleteOnly ? null : home.targetAlbum?.id,
        targetAlbumName: home.isDeleteOnly ? '仅删除' : home.targetAlbum?.name,
        totalCount: pending > 0 ? pending : source.assetCount,
        initialIndex: 0,
        deleteOnly: home.isDeleteOnly,
      ),
    );
  }

  Future<void> _reorganize() async {
    final source = ref.read(homeControllerProvider).source;
    if (source == null) return;
    await ref.read(organizeRepositoryProvider).clearProcessed(source.id);
    await _load(silent: true);
  }

  @override
  Widget build(BuildContext context) {
    final home = ref.watch(homeControllerProvider);

    ref.listen<int>(homeRefreshProvider, (previous, next) {
      if (previous != next) _load(silent: true);
    });

    if (home.isInitialLoading || (!home.hasData && home.error == null)) {
      return Scaffold(
        backgroundColor: context.appBackground,
        body: const LoadingView(message: '加载相册...'),
      );
    }
    if (home.error != null && home.error != 'permission_denied') {
      return Scaffold(
        backgroundColor: context.appBackground,
        body: ErrorView(message: home.error!, onRetry: () => _load()),
      );
    }

    final source = home.source;
    final showHistoryBadge = ref.watch(historyBadgeProvider);

    return Scaffold(
      backgroundColor: context.appBackground,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () => _load(),
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
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
              if (home.isRefreshing)
                const SliverToBoxAdapter(
                  child: LinearProgressIndicator(minHeight: 2),
                ),
              if (home.permission == PhotoPermissionStatus.limited)
                SliverToBoxAdapter(
                  child: LimitedAccessBanner(
                    onAddMore: () => ref.read(photoLibraryServiceProvider).presentLimitedLibraryPicker(),
                  ),
                ),
              if (home.activeSessionHint != null && home.pendingOrganizeCount > 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: Material(
                      color: context.appPrimary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      child: ListTile(
                        title: Text(home.activeSessionHint!, style: TextStyle(color: context.appPrimary)),
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
                    pendingCount: home.pendingOrganizeCount,
                    coverBytes: home.sourceCover,
                    onTap: () => _pickSource(home),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: AlbumTargetCarousel(
                    albums: home.writableAlbums.map((a) => (id: a.id, name: a.name)).toList(),
                    selectedId: home.targetSelectionId,
                    thumbnails: home.targetCovers,
                    onSelect: _selectTarget,
                    onCreate: _createAlbum,
                    onViewAll: () => _pickTarget(home, viewAll: true),
                  ),
                ),
              ),
              if (home.pendingOrganizeCount == 0)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: OutlinedButton(
                      onPressed: _reorganize,
                      child: const Text(AppStrings.reorganize),
                    ),
                  ),
                ),
              if (home.pendingDeleteCount > 0)
                SliverToBoxAdapter(
                  child: PendingDeleteEntry(
                    count: home.pendingDeleteCount,
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
