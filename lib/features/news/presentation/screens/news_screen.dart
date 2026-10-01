import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:mantri_app/features/auth/presentation/screens/role_wrapper.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:mantri_app/core/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_cropper/image_cropper.dart';
import 'dart:io';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:gal/gal.dart';
import 'package:permission_handler/permission_handler.dart';

final Map<String, int> _localLikeCounts = {};
final Map<String, bool> _localIsLiked = {};
// ─── Providers for news and events from Laravel API ───────────────────────────

final newsCategoriesProvider = FutureProvider<List<NewsCategory>>((ref) async {
  return await ref.read(apiServiceProvider).getNewsCategories();
});

class NewsFeedState {
  final List<NewsPost> posts;
  final bool isLoading;
  final bool hasMore;
  final int page;
  final String categoryId;
  final String? error;

  NewsFeedState({
    this.posts = const [],
    this.isLoading = false,
    this.hasMore = true,
    this.page = 1,
    this.categoryId = 'all',
    this.error,
  });

  NewsFeedState copyWith({
    List<NewsPost>? posts,
    bool? isLoading,
    bool? hasMore,
    int? page,
    String? categoryId,
    String? error,
  }) {
    return NewsFeedState(
      posts: posts ?? this.posts,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      categoryId: categoryId ?? this.categoryId,
      error: error, // Can be set to null
    );
  }
}

class NewsFeedNotifier extends StateNotifier<NewsFeedState> {
  final ApiService api;
  NewsFeedNotifier(this.api) : super(NewsFeedState()) {
    fetchInitial();
  }

  Future<void> fetchInitial() async {
    state = state.copyWith(isLoading: true, page: 1, error: null);
    try {
      final posts = await api.getNews(categoryId: state.categoryId, page: 1);
      state = state.copyWith(
        posts: posts,
        isLoading: false,
        hasMore: posts.isNotEmpty,
        page: 2,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;

    state = state.copyWith(isLoading: true);
    try {
      final posts = await api.getNews(
        categoryId: state.categoryId,
        page: state.page,
      );
      state = state.copyWith(
        posts: [...state.posts, ...posts],
        isLoading: false,
        hasMore: posts.isNotEmpty,
        page: state.page + 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setCategory(String categoryId) {
    if (state.categoryId == categoryId) return;
    state = state.copyWith(categoryId: categoryId);
    fetchInitial();
  }

  void refresh() {
    fetchInitial();
  }
}

final newsFeedProvider = StateNotifierProvider<NewsFeedNotifier, NewsFeedState>(
  (ref) {
    return NewsFeedNotifier(ref.read(apiServiceProvider));
  },
);

final eventsListProvider = FutureProvider<List<Event>>((ref) async {
  final api = ref.read(apiServiceProvider);
  return await api.getEvents();
});

// ─────────────────────────────────────────────────────────────────────────────

class NewsScreen extends ConsumerWidget {
  final String? initialPostId;
  const NewsScreen({super.key, this.initialPostId});

  void _showAdminCreator(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _AdminCreateNewsEventForm(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userData = ref.watch(userDataProvider).value;
    final bool canManage =
        userData?.role == UserRole.admin || userData?.role == UserRole.pa;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            canManage ? 'Management: News & Events' : 'Live News & Updates',
          ),
          backgroundColor: const Color.fromARGB(255, 219, 126, 32),
          foregroundColor: Colors.white,
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Latest News', icon: Icon(Icons.newspaper)),
              Tab(text: 'Upcoming Events', icon: Icon(Icons.event_available)),
            ],
            indicatorColor: Colors.white,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
          ),
        ),
        body: TabBarView(
          children: [
            _NewsFeed(canManage: canManage, highlightPostId: initialPostId),
            _EventsFeed(canManage: canManage),
          ],
        ),
        floatingActionButton:
            canManage
                ? FloatingActionButton.extended(
                  onPressed: () => _showAdminCreator(context),
                  icon: const Icon(Icons.post_add),
                  label: const Text('New Post'),
                  backgroundColor: const Color(0xFFF57C00),
                  foregroundColor: Colors.white,
                )
                : null,
      ),
    );
  }
}

// ─── News Feed ────────────────────────────────────────────────────────────────

class _NewsFeed extends ConsumerWidget {
  final bool canManage;
  final String? highlightPostId;
  const _NewsFeed({required this.canManage, this.highlightPostId});

  Future<void> _deleteNews(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete News Article?'),
            content: const Text('This action cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await ref.read(apiServiceProvider).deleteNews(id);
        ref.read(newsFeedProvider.notifier).refresh();
        if (context.mounted) {
          AppDialogs.showWarningDialog(context, message: 'News deleted');
        }
      } catch (e) {
        if (context.mounted) {
          AppDialogs.showErrorDialog(context, technicalError: e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _DailyFeedContent(
      canManage: canManage,
      highlightPostId: highlightPostId,
    );
  }
}

class _DailyFeedContent extends ConsumerStatefulWidget {
  final bool canManage;
  final String? highlightPostId;
  const _DailyFeedContent({required this.canManage, this.highlightPostId});

  @override
  ConsumerState<_DailyFeedContent> createState() => _DailyFeedContentState();
}

class _DailyFeedContentState extends ConsumerState<_DailyFeedContent> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(newsFeedProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(newsFeedProvider);
    final categoriesAsync = ref.watch(newsCategoriesProvider);

    return Column(
      children: [
        // Category Filter
        categoriesAsync.when(
          data: (categories) {
            return Container(
              height: 50,
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(bottom: BorderSide(color: Colors.grey.shade200)),
              ),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                children: [
                  _CategoryChip(
                    id: 'all',
                    name: 'All',
                    isSelected: state.categoryId == 'all',
                    onTap:
                        () => ref
                            .read(newsFeedProvider.notifier)
                            .setCategory('all'),
                  ),
                  ...categories.map(
                    (c) => _CategoryChip(
                      id: c.id,
                      name: c.name,
                      isSelected: state.categoryId == c.id,
                      onTap:
                          () => ref
                              .read(newsFeedProvider.notifier)
                              .setCategory(c.id),
                    ),
                  ),
                ],
              ),
            );
          },
          loading:
              () => const SizedBox(
                height: 50,
                child: Center(child: CircularProgressIndicator()),
              ),
          error: (_, __) => const SizedBox(),
        ),

        // Feed
        Expanded(
          child: RefreshIndicator(
            onRefresh:
                () async => ref.read(newsFeedProvider.notifier).refresh(),
            child:
                state.posts.isEmpty && !state.isLoading
                    ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.3,
                        ),
                        const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.feed_outlined,
                                size: 64,
                                color: Colors.grey,
                              ),
                              SizedBox(height: 16),
                              Text(
                                'No updates available.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    )
                    : ListView.builder(
                      controller: _scrollController,
                      // Every 4 real posts, we insert 1 "Install App" banner
                      itemCount:
                          state.posts.length +
                          (state.isLoading && state.posts.isNotEmpty ? 1 : 0) +
                          (state.posts.length ~/ 4),
                      itemBuilder: (context, index) {
                        // "Install App" banner slot every 4 posts (index 4, 9, 14…)
                        if (index > 0 &&
                            (index % 5 == 4) &&
                            index <
                                state.posts.length +
                                    (state.posts.length ~/ 4)) {
                          return _InstallAppBanner();
                        }

                        // Adjust real post index accounting for banners inserted
                        final bannersBefore = index ~/ 5;
                        final postIndex = index - bannersBefore;

                        if (postIndex >= state.posts.length) {
                          return state.isLoading
                              ? const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(),
                                ),
                              )
                              : const SizedBox.shrink();
                        }

                        final post = state.posts[postIndex];
                        final bool isHighlighted =
                            widget.highlightPostId != null &&
                            post.id == widget.highlightPostId;
                        return isHighlighted
                            ? Container(
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFFDB7E20),
                                  width: 3,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              child: InstaFeedCard(
                                post: post,
                                canManage: widget.canManage,
                              ),
                            )
                            : InstaFeedCard(
                              post: post,
                              canManage: widget.canManage,
                            );
                      },
                    ),
          ),
        ),
      ],
    );
  }
}

// ─── Install App Banner ───────────────────────────────────────────────────────

class _InstallAppBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF1B3B5A), Color(0xFF2C5282)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1B3B5A).withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.phone_android,
                color: Color(0xFF1B3B5A),
                size: 30,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📲 Install Mantri App',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Stay updated with the latest news, register complaints & connect with your MP.',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () async {
                // Opens Play Store — update with your actual store URL
                final uri = Uri.parse(
                  'https://play.google.com/store/apps/details?id=com.mantri.app',
                );
                if (await canLaunchUrl(uri))
                  launchUrl(uri, mode: LaunchMode.externalApplication);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDB7E20),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text(
                'Install',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String id;
  final String name;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.id,
    required this.name,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFDB7E20) : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? const Color(0xFFDB7E20) : Colors.grey.shade300,
          ),
        ),
        child: Center(
          child: Text(
            name,
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.grey.shade800,
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Instagram-style Feed Card ────────────────────────────────────────────────

class InstaFeedCard extends StatefulWidget {
  final NewsPost post;
  final bool canManage;
  const InstaFeedCard({required this.post, this.canManage = false});

  @override
  State<InstaFeedCard> createState() => InstaFeedCardState();
}

class InstaFeedCardState extends State<InstaFeedCard> {
  int _currentImageIndex = 0;
  bool _isExpanded = false;
  bool _isLiked = false;
  int _likeCount = 0;
  bool _isDownloading = false;

  // Video player
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;
  bool _videoInitialized = false;
  bool _showVideoPlayer = false;

  Future<void> _saveMedia() async {
    if (_isDownloading) return;

    try {
      final hasAccess = await Gal.hasAccess();
      if (!hasAccess) {
        final requestAccess = await Gal.requestAccess();
        if (!requestAccess) {
          if (!mounted) return;
          AppDialogs.showErrorDialog(
            context,
            userMessage: 'Storage permission is required to save media',
          );
          return;
        }
      }
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showErrorDialog(
        context,
        userMessage: 'Error checking permissions:',
        technicalError: e,
      );
      return;
    }

    setState(() {
      _isDownloading = true;
    });

    try {
      final hasVideo =
          widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty;
      final urlToSave =
          hasVideo
              ? widget.post.videoUrl!
              : (widget.post.images.isNotEmpty
                  ? widget.post.images[_currentImageIndex]
                  : null);

      if (urlToSave == null) {
        throw Exception("No media to save.");
      }

      var tempDir = await getTemporaryDirectory();
      String savePath =
          '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch}${hasVideo ? ".mp4" : ".jpg"}';

      await Dio().download(urlToSave, savePath);
      if (hasVideo) {
        await Gal.putVideo(savePath);
      } else {
        await Gal.putImage(savePath);
      }

      if (!mounted) return;
      AppDialogs.showErrorDialog(context, userMessage: 'Saved to Gallery!');
    } catch (e) {
      if (!mounted) return;
      AppDialogs.showErrorDialog(
        context,
        userMessage: 'Error saving media:',
        technicalError: e,
      );
    } finally {
      if (mounted) {
        setState(() {
          _isDownloading = false;
        });
      }
    }
  }

  Future<void> _showRsvpDialog(BuildContext context) async {
    final status = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('RSVP to Event'),
            content: const Text('Are you planning to attend this event?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'not_attending'),
                child: const Text('Not Attending'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB7E20),
                ),
                onPressed: () => Navigator.pop(ctx, 'attending'),
                child: const Text(
                  'Attending',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (status != null) {
      try {
        await ApiService().submitRsvp(widget.post.id, status);
        if (mounted) {
          AppDialogs.showSuccessDialog(context, message: 'RSVP submitted successfully!');
        }
      } catch (e) {
        if (mounted) {
          AppDialogs.showErrorDialog(
            context,
            userMessage: 'Failed to submit RSVP:',
            technicalError: e,
          );
        }
      }
    }
  }

  Future<void> _showRsvpsList(BuildContext context) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (_) => _RsvpListSheet(
            postId: widget.post.id,
            postTitle: widget.post.title,
          ),
    );
  }

  @override
  void initState() {
    super.initState();
    _likeCount = _localLikeCounts[widget.post.id] ?? widget.post.likesCount;
    _isLiked = _localIsLiked[widget.post.id] ?? widget.post.isLiked;
  }

  @override
  void dispose() {
    _chewieController?.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  String _formatMediaUrl(String url) {
    if (url.startsWith('http://mlapp.codexxa.co.in')) {
      return url.replaceFirst(
        'http://mlapp.codexxa.co.in',
        'http://192.168.1.19',
      );
    } else if (url.startsWith('https://mlapp.codexxa.co.in')) {
      return url.replaceFirst(
        'https://mlapp.codexxa.co.in',
        'http://192.168.1.19',
      );
    } else if (!url.startsWith('http')) {
      return url.startsWith('/')
          ? 'http://192.168.1.19$url'
          : 'http://192.168.1.19/$url';
    }
    return url;
  }

  Future<void> _initializePlayer() async {
    String? url = widget.post.videoUrl;
    if (url == null || url.isEmpty) return;

    // Format URL to use local IP for development or correct domain
    url = _formatMediaUrl(url);

    setState(() => _showVideoPlayer = true);

    _videoController = VideoPlayerController.networkUrl(Uri.parse(url));
    try {
      await _videoController!.initialize();
      if (!mounted) return;

      // Small delay to ensure initialization is stable
      await Future.delayed(const Duration(milliseconds: 100));

      _chewieController = ChewieController(
        videoPlayerController: _videoController!,
        autoPlay: true,
        looping: false,
        allowFullScreen: true,
        aspectRatio: _videoController!.value.aspectRatio,
        placeholder: _buildThumbnailOverlay(),
        errorBuilder: (context, errorMessage) {
          final isHevc =
              errorMessage.contains('video/hevc') ||
              errorMessage.contains('MediaCodecVideoRenderer') ||
              errorMessage.contains('ExoPlaybackException');
          return Container(
            color: Colors.black,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.videocam_off,
                      color: Colors.white54,
                      size: 48,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isHevc
                          ? 'This video uses H.265 (HEVC) format which is not supported on this device.\n\nPlease upload H.264 (MP4) videos for best compatibility.'
                          : 'Unable to play this video.',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );

      // Listen for errors after initialization (e.g. HEVC decode failures)
      _videoController!.addListener(() {
        if (_videoController!.value.hasError && mounted) {
          final err = _videoController!.value.errorDescription ?? '';
          debugPrint('VideoPlayer runtime error: $err');
        }
      });

      setState(() => _videoInitialized = true);
    } catch (e) {
      debugPrint('Video init error ($url): $e');
      if (mounted) {
        setState(() {
          _showVideoPlayer = false;
        });

        String errorMsg = 'Could not play this video.';
        final errorString = e.toString();

        if (errorString.contains('video/hevc') ||
            errorString.contains('MediaCodecVideoRenderer')) {
          errorMsg =
              'Your device/emulator does not support playing HEVC (H.265) videos. Please use standard MP4 (H.264) videos for best compatibility.';
        } else {
          errorMsg = 'Playback error: $e';
        }

        AppDialogs.showErrorDialog(context);
      }
    }
  }

  Widget _buildThumbnailOverlay() {
    final thumbUrl =
        widget.post.thumbnailUrl ??
        (widget.post.images.isNotEmpty ? widget.post.images.first : null);

    return Stack(
      alignment: Alignment.center,
      children: [
        // Black background only — no thumbnail shown while video plays
        Container(color: Colors.black),

        // Dark Overlay for play button visibility
        Container(color: Colors.black.withOpacity(0.2)),

        // Play Button Overlay
        if (!_showVideoPlayer)
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 50,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Tap to play video',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  shadows: [Shadow(blurRadius: 8, color: Colors.black54)],
                ),
              ),
            ],
          ),
      ],
    );
  }

  void _openFullScreenImage(String imageUrl) {
    showDialog(
      context: context,
      builder:
          (context) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: EdgeInsets.zero,
            child: Stack(
              children: [
                InteractiveViewer(
                  minScale: 0.8,
                  maxScale: 5.0,
                  child: Center(
                    child: Image.network(
                      _formatMediaUrl(imageUrl),
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) {
                        if (progress == null) return child;
                        return const Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        );
                      },
                    ),
                  ),
                ),
                Positioned(
                  top: 40,
                  right: 16,
                  child: IconButton(
                    icon: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 30,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  Future<void> _toggleLike(BuildContext context) async {
    final api = ApiService();
    setState(() {
      _isLiked = !_isLiked;
      _likeCount += _isLiked ? 1 : -1;
      _localIsLiked[widget.post.id] = _isLiked;
      _localLikeCounts[widget.post.id] = _likeCount;
    });
    try {
      if (_isLiked) {
        await api.likeNews(widget.post.id);
      } else {
        await api.unlikeNews(widget.post.id);
      }
    } catch (e) {
      // For now, we will NOT revert the UI state if the API fails,
      // so that the like count is visible for the user in the UI demo.
      debugPrint('Error toggling like: $e');
    }
  }

  void _showComments(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => CommentsSheet(postId: widget.post.id.toString()),
    );
  }

  void _sharePost() {
    // Deep link: mantriapp://news/{id}  (also a web fallback URL)
    final deepLink =
        'https://mantriapp.page.link/news?postId=${widget.post.id}';
    final hasVideo =
        widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty;
    final shareText =
        hasVideo
            ? '🎬 ${widget.post.title}\n\n${widget.post.description}\n\n▶️ Watch here: $deepLink\n\n📲 Download Mantri App to see more updates!'
            : '📰 ${widget.post.title}\n\n${widget.post.description}\n\n🔗 Read more: $deepLink\n\n📲 Download Mantri App to see more updates!';

    Share.share(shareText, subject: widget.post.title);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        widget.post.publishedAt != null
            ? DateFormat(
              'd MMM yyyy',
            ).format(widget.post.publishedAt!).toUpperCase()
            : '';
    final allImages = widget.post.images;
    final hasVideo =
        widget.post.videoUrl != null && widget.post.videoUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.grey.shade200, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 18,
                  backgroundColor: Color(0xFFDB7E20),
                  backgroundImage: AssetImage('assets/images/download (1).jpg'),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.post.createdBy,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                          color: Color(0xFF1B3B5A),
                        ),
                      ),
                      Text(
                        (widget.post.location != null &&
                                widget.post.location!.isNotEmpty)
                            ? widget.post.location!
                            : 'pune',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
              ],
            ),
          ),

          // ── Inline Video Player ──────────────────────────────────────────────
          if (hasVideo)
            AspectRatio(
              aspectRatio: 1.0,
              child:
                  _showVideoPlayer &&
                          _videoInitialized &&
                          _chewieController != null
                      ? Chewie(controller: _chewieController!)
                      : GestureDetector(
                        onTap: _initializePlayer,
                        child: _buildThumbnailOverlay(),
                      ),
            ),

          // ── Image Carousel (only if no video, or alongside video) ────────────
          if (!hasVideo && allImages.isNotEmpty)
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                AspectRatio(
                  aspectRatio: 1.0,
                  child: PageView.builder(
                    itemCount: allImages.length,
                    onPageChanged:
                        (index) => setState(() => _currentImageIndex = index),
                    itemBuilder: (context, index) {
                      return GestureDetector(
                        onTap: () => _openFullScreenImage(allImages[index]),
                        child: Image.network(
                          _formatMediaUrl(allImages[index]),
                          width: double.infinity,
                          height: double.infinity,
                          fit: BoxFit.cover,
                          errorBuilder:
                              (_, __, ___) => Container(
                                color: Colors.grey.shade100,
                                child: Center(
                                  child: Icon(
                                    Icons.broken_image_outlined,
                                    color: Colors.grey.shade300,
                                    size: 48,
                                  ),
                                ),
                              ),
                        ),
                      );
                    },
                  ),
                ),
                // Dot indicators (Instagram-style)
                if (allImages.length > 1)
                  Positioned(
                    bottom: 10,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        allImages.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: _currentImageIndex == i ? 18 : 6,
                          height: 6,
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          decoration: BoxDecoration(
                            color:
                                _currentImageIndex == i
                                    ? Colors.white
                                    : Colors.white54,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          // ── Actions Bar ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                // Like
                if (widget.post.allowLikes) ...[
                  GestureDetector(
                    onTap: () => _toggleLike(context),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder:
                          (child, anim) =>
                              ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        _isLiked ? Icons.favorite : Icons.favorite_border,
                        key: ValueKey(_isLiked),
                        size: 28,
                        color: _isLiked ? Colors.red : const Color(0xFF1B3B5A),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                ],

                // Share
                if (widget.post.allowShare) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _sharePost,
                    child: const Icon(
                      Icons.share,
                      size: 26,
                      color: Color(0xFF1B3B5A),
                    ),
                  ),
                ],
                const Spacer(),
                GestureDetector(
                  onTap: _saveMedia,
                  child:
                      _isDownloading
                          ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Color(0xFF1B3B5A),
                            ),
                          )
                          : const Icon(
                            Icons.bookmark_border,
                            size: 28,
                            color: Color(0xFF1B3B5A),
                          ),
                ),
              ],
            ),
          ),

          // ── Likes Count ─────────────────────────────────────────────────────
          if (_likeCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '$_likeCount ${_likeCount == 1 ? 'like' : 'likes'}',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: Color(0xFF1B3B5A),
                ),
              ),
            ),

          // ── Content ─────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (widget.post.category != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFDB7E20).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      widget.post.category!.name,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDB7E20),
                      ),
                    ),
                  ),
                RichText(
                  text: TextSpan(
                    style: const TextStyle(
                      fontSize: 14,
                      color: Color(0xFF1B3B5A),
                    ),
                    children: [
                      if (widget.post.createdBy.isNotEmpty)
                        TextSpan(
                          text: '${widget.post.createdBy} ',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      TextSpan(
                        text: widget.post.title,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ),
                if (widget.post.description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => setState(() => _isExpanded = !_isExpanded),
                    child: Text(
                      widget.post.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade800,
                      ),
                      maxLines: _isExpanded ? null : 2,
                      overflow: _isExpanded ? null : TextOverflow.ellipsis,
                    ),
                  ),
                ],

                // RSVP Section for Events
                if (widget.post.eventDate != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.event, color: Colors.blue.shade700),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Event on ${DateFormat('dd MMM yyyy, hh:mm a').format(widget.post.eventDate!)}',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.blue.shade900,
                                    fontSize: 13,
                                  ),
                                ),
                                if (widget.post.location != null)
                                  Text(
                                    widget.post.location!,
                                    style: TextStyle(
                                      color: Colors.blue.shade800,
                                      fontSize: 12,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          if (widget.canManage)
                            ElevatedButton.icon(
                              onPressed: () => _showRsvpsList(context),
                              icon: const Icon(Icons.people_alt, size: 16),
                              label: const Text('RSVPs'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: Colors.blue.shade800,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                            )
                          else
                            ElevatedButton(
                              onPressed: () => _showRsvpDialog(context),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue.shade700,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 8,
                                ),
                                minimumSize: Size.zero,
                                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: const Text('RSVP'),
                            ),
                        ],
                      ),
                    ),
                  ),

                if (widget.post.allowComments && widget.post.commentsCount > 0)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: GestureDetector(
                      onTap: () => _showComments(context),
                      child: Text(
                        'View all ${widget.post.commentsCount} comments',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500,
                        ),
                      ),
                    ),
                  ),
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    dateStr.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Comments Bottom Sheet ────────────────────────────────────────────────────

class CommentsSheet extends StatefulWidget {
  final String postId;
  const CommentsSheet({required this.postId});

  @override
  State<CommentsSheet> createState() => CommentsSheetState();
}

class CommentsSheetState extends State<CommentsSheet> {
  final _commentController = TextEditingController();
  List<Map<String, dynamic>> _comments = [];
  bool _loading = true;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _loadComments() async {
    setState(() => _loading = true);
    try {
      final api = ApiService();
      final comments = await api.getComments(widget.postId);
      if (mounted) setState(() => _comments = comments);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;
    setState(() => _submitting = true);
    try {
      final api = ApiService();
      await api.addComment(widget.postId, text);
      _commentController.clear();
      await _loadComments();
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(
          context,
          userMessage: 'Failed:',
          technicalError: e,
        );
      }
    }
    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      builder: (_, controller) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Handle
              Container(
                margin: const EdgeInsets.only(top: 10, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 10),
                child: Text(
                  'Comments',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
              const Divider(height: 1),
              // Comments list
              Expanded(
                child:
                    _loading
                        ? const Center(child: CircularProgressIndicator())
                        : _comments.isEmpty
                        ? const Center(
                          child: Text(
                            'No comments yet. Be the first!',
                            style: TextStyle(color: Colors.grey),
                          ),
                        )
                        : ListView.separated(
                          controller: controller,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          itemCount: _comments.length,
                          separatorBuilder: (_, __) => const Divider(),
                          itemBuilder: (context, index) {
                            final c = _comments[index];
                            return Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 14,
                                  backgroundColor: const Color(0xFFDB7E20),
                                  child: Text(
                                    (c['user']?['name'] ?? 'U')[0]
                                        .toUpperCase(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        c['user']?['name'] ?? 'User',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13,
                                        ),
                                      ),
                                      Text(
                                        c['comment'] ?? '',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey.shade700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
              ),
              // Input area
              Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: MediaQuery.of(context).viewInsets.bottom + 12,
                ),
                child: Row(
                  children: [
                    const CircleAvatar(
                      radius: 16,
                      backgroundColor: Color(0xFFDB7E20),
                      child: Icon(Icons.person, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        decoration: InputDecoration(
                          hintText: 'Add a comment…',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(24),
                            borderSide: BorderSide.none,
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                        ),
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _submitComment(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _submitting
                        ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                        : IconButton(
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Color(0xFFDB7E20),
                          ),
                          onPressed: _submitComment,
                        ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Events Feed ──────────────────────────────────────────────────────────────

class _EventsFeed extends ConsumerWidget {
  final bool canManage;
  const _EventsFeed({required this.canManage});

  Future<void> _deleteEvent(
    BuildContext context,
    WidgetRef ref,
    String id,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('Delete Event?'),
            content: const Text(
              'This will remove the event from the public schedule.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Delete'),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      try {
        await ref.read(apiServiceProvider).deleteEvent(id);
        ref.invalidate(eventsListProvider);
        if (context.mounted) {
          AppDialogs.showSuccessDialog(context, message: 'Success');
        }
      } catch (e) {
        if (context.mounted) {
          AppDialogs.showErrorDialog(context, technicalError: e);
        }
      }
    }
  }

  Future<void> _showRsvpDialog(BuildContext context, String eventId) async {
    final status = await showDialog<String>(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: const Text('RSVP to Event'),
            content: const Text('Are you planning to attend this event?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, 'not_attending'),
                child: const Text('Not Attending'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFDB7E20),
                ),
                onPressed: () => Navigator.pop(ctx, 'attending'),
                child: const Text(
                  'Attending',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
    );

    if (status != null) {
      try {
        await ApiService().submitRsvp(eventId, status);
        if (context.mounted) {
          await AppDialogs.showSuccessDialog(context, message: 'RSVP submitted successfully!');
        }
      } catch (e) {
        if (context.mounted) {
          AppDialogs.showErrorDialog(
            context,
            userMessage: 'Failed to submit RSVP:',
            technicalError: e,
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final eventsAsync = ref.watch(eventsListProvider);

    return eventsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading events: $e')),
      data: (eventList) {
        if (eventList.isEmpty) {
          return const Center(child: Text('No upcoming events scheduled.'));
        }

        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(eventsListProvider),
          child: ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: eventList.length,
            itemBuilder: (context, index) {
              final item = eventList[index];
              final title = item.title;
              final location = item.location;
              final isLive = false;
              final id = item.id;

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                  side:
                      isLive
                          ? const BorderSide(color: Colors.red, width: 2)
                          : BorderSide.none,
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.all(16),
                  leading: CircleAvatar(
                    backgroundColor:
                        isLive
                            ? Colors.red
                            : const Color(
                              0xFFF57C00,
                            ).withAlpha((0.1 * 255).toInt()),
                    radius: 25,
                    child: Icon(
                      isLive ? Icons.live_tv : Icons.event,
                      color: isLive ? Colors.white : const Color(0xFFF57C00),
                    ),
                  ),
                  title: Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 17,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text(
                        '📍 $location',
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      if (isLive)
                        const Padding(
                          padding: EdgeInsets.only(top: 4),
                          child: Text(
                            '🔴 HAPPENING NOW',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 11,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing:
                      canManage
                          ? IconButton(
                            icon: const Icon(
                              Icons.delete_outline,
                              color: Colors.red,
                            ),
                            onPressed: () => _deleteEvent(context, ref, id),
                          )
                          : ElevatedButton(
                            onPressed: () => _showRsvpDialog(context, id),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color.fromARGB(
                                255,
                                219,
                                126,
                                32,
                              ),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('RSVP'),
                          ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ─── PA/Admin Create News/Event Form ─────────────────────────────────────────

class _AdminCreateNewsEventForm extends ConsumerStatefulWidget {
  const _AdminCreateNewsEventForm();

  @override
  ConsumerState<_AdminCreateNewsEventForm> createState() =>
      _AdminCreateNewsEventFormState();
}

class _AdminCreateNewsEventFormState
    extends ConsumerState<_AdminCreateNewsEventForm> {
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _videoUrlController = TextEditingController();

  final List<File> _imageFiles = [];
  File? _videoFile;
  bool _isEvent = false;
  bool _isLive = false;
  bool _isSubmitting = false;

  // Social interaction toggles
  bool _allowLikes = true;
  bool _allowComments = true;
  bool _allowShare = true;

  final ImagePicker _picker = ImagePicker();

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _videoUrlController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    if (_imageFiles.length >= 5) {
      AppDialogs.showErrorDialog(
        context,
        userMessage: 'Maximum 5 images allowed',
      );
      return;
    }
    final images = await _picker.pickMultiImage(imageQuality: 85);
    if (images.isEmpty) return;

    final remaining = 5 - _imageFiles.length;
    final toProcess = images.take(remaining).toList();

    for (final image in toProcess) {
      final cropped = await ImageCropper().cropImage(
        sourcePath: image.path,
        aspectRatio: const CropAspectRatio(ratioX: 1, ratioY: 1),
        uiSettings: [
          AndroidUiSettings(
            toolbarTitle: 'Adjust Photo',
            toolbarColor: const Color(0xFFDB7E20),
            toolbarWidgetColor: Colors.white,
            initAspectRatio: CropAspectRatioPreset.square,
            lockAspectRatio: false,
          ),
          IOSUiSettings(title: 'Adjust Photo'),
        ],
      );
      if (cropped != null) {
        setState(() => _imageFiles.add(File(cropped.path)));
      }
    }
  }

  Future<void> _pickVideo() async {
    final video = await _picker.pickVideo(source: ImageSource.gallery);
    if (video != null) {
      setState(() {
        _videoFile = File(video.path);
        _videoUrlController.clear();
      });
    }
  }

  void _removeImage(int index) {
    setState(() => _imageFiles.removeAt(index));
  }

  void _removeVideo() {
    setState(() => _videoFile = null);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) return;
    setState(() => _isSubmitting = true);

    try {
      final api = ref.read(apiServiceProvider);

      // Upload images
      List<String> uploadedImageUrls = [];
      for (final file in _imageFiles) {
        final url = await api.uploadFile(file, 'news_images');
        uploadedImageUrls.add(url);
      }

      // Upload video file if picked from gallery
      String? videoUrl =
          _videoUrlController.text.trim().isNotEmpty
              ? _videoUrlController.text.trim()
              : null;
      if (_videoFile != null) {
        videoUrl = await api.uploadFile(_videoFile!, 'news_videos');
      }

      final title = _titleController.text.trim();
      final description = _descController.text.trim();
      final userData = ref.read(userDataProvider).value;
      final createdBy = userData?.name ?? 'Admin';

      if (_isEvent) {
        final event = Event(
          id: '',
          title: title,
          description: description,
          location: description,
          date: DateTime.now(),
          createdBy: createdBy,
        );
        await api.addEvent(event);
        ref.invalidate(eventsListProvider);
      } else {
        await api.addNews(
          title: title,
          description: description,
          images: uploadedImageUrls.isNotEmpty ? uploadedImageUrls : null,
          imageUrl:
              uploadedImageUrls.isNotEmpty ? uploadedImageUrls.first : null,
          videoUrl: videoUrl,
          status: _isLive ? 'published' : 'draft',
          allowLikes: _allowLikes,
          allowComments: _allowComments,
          allowShare: _allowShare,
        );
        ref.invalidate(newsFeedProvider);
      }

      if (!mounted) return;
      Navigator.pop(context);
      AppDialogs.showSuccessDialog(context, message: _isEvent ? 'Event published!' : 'News published!');
    } catch (e) {
      if (mounted) AppDialogs.showErrorDialog(context, technicalError: e);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Publish Updates & Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 20),
            Center(
              child: SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('News Feed'),
                    icon: Icon(Icons.newspaper),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Upcoming Event'),
                    icon: Icon(Icons.event),
                  ),
                ],
                selected: {_isEvent},
                onSelectionChanged:
                    (val) => setState(() => _isEvent = val.first),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: _isEvent ? 'Event Title' : 'Article Headline',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _descController,
              maxLines: 3,
              decoration: InputDecoration(
                labelText:
                    _isEvent ? 'Location & Time Info' : 'Short Description',
                border: const OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            if (!_isEvent) ...[
              // ── Photo Section ──────────────────────────────────────────────
              const Text(
                'Photos  (up to 5)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (_imageFiles.isNotEmpty)
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: _imageFiles.length + 1,
                    itemBuilder: (context, index) {
                      if (index == _imageFiles.length) {
                        // Add more button
                        if (_imageFiles.length >= 5) return const SizedBox();
                        return GestureDetector(
                          onTap: _pickImages,
                          child: Container(
                            width: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade300),
                            ),
                            child: const Icon(
                              Icons.add_photo_alternate_outlined,
                              size: 32,
                              color: Colors.grey,
                            ),
                          ),
                        );
                      }
                      return Stack(
                        children: [
                          Container(
                            width: 100,
                            height: 100,
                            margin: const EdgeInsets.only(right: 8),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              image: DecorationImage(
                                image: FileImage(_imageFiles[index]),
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 4,
                            right: 12,
                            child: GestureDetector(
                              onTap: () => _removeImage(index),
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.close,
                                  color: Colors.white,
                                  size: 16,
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              if (_imageFiles.isEmpty)
                GestureDetector(
                  onTap: _pickImages,
                  child: Container(
                    height: 110,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.grey.shade300,
                        style: BorderStyle.solid,
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 36,
                          color: Colors.grey.shade600,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tap to add photos',
                          style: TextStyle(color: Colors.grey.shade600),
                        ),
                        Text(
                          'Up to 5 • Crop/adjust after picking',
                          style: TextStyle(
                            color: Colors.grey.shade400,
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 16),

              // ── Video Section ──────────────────────────────────────────────
              const Text(
                'Video',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              if (_videoFile != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.video_file_outlined,
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _videoFile!.path.split('/').last,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white70),
                        onPressed: _removeVideo,
                      ),
                    ],
                  ),
                )
              else ...[
                TextField(
                  controller: _videoUrlController,
                  decoration: InputDecoration(
                    labelText: 'Video URL (YouTube, mp4 direct link…)',
                    border: const OutlineInputBorder(),
                    suffixIcon: const Icon(Icons.link),
                    helperText: 'Paste a direct .mp4 link for inline playback',
                  ),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: _pickVideo,
                  icon: const Icon(Icons.video_library_outlined),
                  label: const Text('Or pick video from gallery'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF1B3B5A),
                  ),
                ),
              ],
              const SizedBox(height: 16),

              // ── Interaction Settings ───────────────────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Text(
                        '⚙️  Interaction Settings',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: Color(0xFF1B3B5A),
                        ),
                      ),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: const Text('Allow Likes ❤️'),
                      value: _allowLikes,
                      onChanged: (v) => setState(() => _allowLikes = v),
                      activeColor: const Color(0xFFDB7E20),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: const Text('Allow Comments 💬'),
                      value: _allowComments,
                      onChanged: (v) => setState(() => _allowComments = v),
                      activeColor: const Color(0xFFDB7E20),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: const Text('Allow Sharing 📤'),
                      value: _allowShare,
                      onChanged: (v) => setState(() => _allowShare = v),
                      activeColor: const Color(0xFFDB7E20),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],

            // ── Live toggle ────────────────────────────────────────────────
            SwitchListTile(
              title: const Text('Mark as LIVE Broadcast'),
              subtitle: Text(
                _isEvent
                    ? 'The event is happening now'
                    : 'Show "Live" badge on home',
              ),
              value: _isLive,
              onChanged: (v) => setState(() => _isLive = v),
              activeColor: Colors.red,
            ),
            const SizedBox(height: 16),

            // ── Submit button ──────────────────────────────────────────────
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color.fromARGB(255, 219, 126, 32),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child:
                    _isSubmitting
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text('Publish Immediately'),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

// ─── RSVP List Sheet (Admin View) ─────────────────────────────────────────────

class _RsvpListSheet extends StatefulWidget {
  final String postId;
  final String postTitle;
  const _RsvpListSheet({required this.postId, required this.postTitle});

  @override
  State<_RsvpListSheet> createState() => _RsvpListSheetState();
}

class _RsvpListSheetState extends State<_RsvpListSheet> {
  List<Rsvp> _rsvps = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadRsvps();
  }

  Future<void> _loadRsvps() async {
    setState(() => _loading = true);
    try {
      final rsvps = await ApiService().getRsvps(widget.postId);
      if (mounted) setState(() => _rsvps = rsvps);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    const saffron = Color.fromARGB(255, 219, 126, 32);

    final attending = _rsvps.where((r) => r.status == 'attending').toList();
    final notAttending =
        _rsvps.where((r) => r.status == 'not_attending').toList();

    return DraggableScrollableSheet(
      initialChildSize: 0.65,
      maxChildSize: 0.92,
      minChildSize: 0.35,
      builder:
          (_, controller) => Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 10, bottom: 4),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 20,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.how_to_reg,
                        color: Color.fromARGB(255, 219, 126, 32),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'RSVPs — ${widget.postTitle}',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                if (_loading)
                  const Expanded(
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_rsvps.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text(
                        'No RSVPs yet.',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  )
                else
                  Expanded(
                    child: ListView(
                      controller: controller,
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Summary chips
                        Row(
                          children: [
                            _chip(
                              '✅ Attending: ${attending.length}',
                              Colors.green,
                            ),
                            const SizedBox(width: 10),
                            _chip(
                              '❌ Not Attending: ${notAttending.length}',
                              Colors.red,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        if (attending.isNotEmpty) ...[
                          Text(
                            'Attending (${attending.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...attending.map((r) => _rsvpTile(r, saffron)),
                        ],

                        if (notAttending.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Not Attending (${notAttending.length})',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                              fontSize: 14,
                            ),
                          ),
                          const SizedBox(height: 8),
                          ...notAttending.map((r) => _rsvpTile(r, saffron)),
                        ],
                      ],
                    ),
                  ),
              ],
            ),
          ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
          fontSize: 13,
        ),
      ),
    );
  }

  Widget _rsvpTile(Rsvp rsvp, Color saffron) {
    final name = rsvp.user?.name ?? 'Unknown User';
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: saffron.withOpacity(0.15),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: TextStyle(color: saffron, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
                if (rsvp.user?.phone != null)
                  Text(
                    rsvp.user!.phone!,
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color:
                  rsvp.status == 'attending'
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              rsvp.status == 'attending' ? '✅ Attending' : '❌ Not Going',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: rsvp.status == 'attending' ? Colors.green : Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
