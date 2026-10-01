import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mantri_app/core/services/api_service.dart';
import 'package:mantri_app/core/models/app_models.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

final _newsPostsProvider = FutureProvider.autoDispose<List<NewsPost>>((ref) {
  return ref.read(apiServiceProvider).getNews();
});

class NewsPostManagementScreen extends ConsumerStatefulWidget {
  const NewsPostManagementScreen({super.key});

  @override
  ConsumerState<NewsPostManagementScreen> createState() =>
      _NewsPostManagementScreenState();
}

class _NewsPostManagementScreenState
    extends ConsumerState<NewsPostManagementScreen> {
  static const saffron = Color(0xFFDB7E20);

  void _openForm({NewsPost? existing}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NewsPostForm(existing: existing),
    ).then((_) {
      // Refresh list after form closes
      ref.invalidate(_newsPostsProvider);
    });
  }

  Future<void> _delete(String id) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Post?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await ref.read(apiServiceProvider).deleteNews(id);
        ref.invalidate(_newsPostsProvider);
        if (mounted) {
          AppDialogs.showSuccessDialog(context, message: 'Post deleted!');
        }
      } catch (e) {
        if (mounted) {
          AppDialogs.showErrorDialog(context, technicalError: e);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final postsAsync = ref.watch(_newsPostsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: const Text('Daily Feed Management'),
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: postsAsync.when(
          loading: () =>
              const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Error: $e')),
          data: (posts) {
            if (posts.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.post_add,
                        size: 72, color: Colors.grey.shade300),
                    const SizedBox(height: 16),
                    Text(
                      'No posts yet.\nTap + to create the first one.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.grey.shade400, fontSize: 15),
                    ),
                  ],
                ),
              );
            }
            return ListView.builder(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              itemCount: posts.length,
              itemBuilder: (_, i) {
                final post = posts[i];
                final dateStr = post.publishedAt != null
                    ? DateFormat('d MMM yyyy').format(post.publishedAt!)
                    : '';
                final isPublished = post.status == 'published';

                return Container(
                  margin: const EdgeInsets.only(bottom: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (post.image != null && post.image!.isNotEmpty)
                        ClipRRect(
                          borderRadius: const BorderRadius.only(
                            topLeft: Radius.circular(18),
                            topRight: Radius.circular(18),
                          ),
                          child: Image.network(
                            post.image!,
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 80,
                              color: Colors.grey.shade100,
                              child: const Icon(Icons.image_not_supported),
                            ),
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(14, 12, 14, 8),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    post.title,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 15,
                                        color: Color(0xFF1B3B5A)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: isPublished
                                        ? Colors.green.shade50
                                        : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isPublished
                                          ? Colors.green.shade200
                                          : Colors.orange.shade200,
                                    ),
                                  ),
                                  child: Text(
                                    isPublished ? 'Published' : 'Draft',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: isPublished
                                          ? Colors.green.shade700
                                          : Colors.orange.shade700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (dateStr.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(
                                dateStr,
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade500),
                              ),
                            ],
                            if (post.description.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              Text(
                                post.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                    fontSize: 13,
                                    color: Colors.grey.shade600),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const Divider(height: 1),
                      Row(
                        children: [
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => _openForm(existing: post),
                              icon: const Icon(Icons.edit_outlined,
                                  size: 17, color: saffron),
                              label: const Text('Edit',
                                  style: TextStyle(color: saffron)),
                            ),
                          ),
                          Container(
                              width: 1, height: 36, color: Colors.grey.shade200),
                          Expanded(
                            child: TextButton.icon(
                              onPressed: () => _delete(post.id),
                              icon: Icon(Icons.delete_outline,
                                  size: 17, color: Colors.red.shade400),
                              label: Text('Delete',
                                  style: TextStyle(
                                      color: Colors.red.shade400)),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        backgroundColor: saffron,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.post_add),
        label: const Text('New Post'),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// News Post Form (Create / Edit)
// ─────────────────────────────────────────────────────────────────────────────

class _NewsPostForm extends ConsumerStatefulWidget {
  final NewsPost? existing;
  const _NewsPostForm({this.existing});

  @override
  ConsumerState<_NewsPostForm> createState() => _NewsPostFormState();
}

class _NewsPostFormState extends ConsumerState<_NewsPostForm> {
  static const saffron = Color(0xFFDB7E20);

  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _locationController = TextEditingController();
  
  String _status = 'published';
  String _mediaType = 'photo';
  String? _categoryId;
  DateTime? _eventDate;
  bool _isLoading = false;
  
  List<File> _localImages = [];
  List<String> _imageUrls = [];
  File? _localVideo;
  File? _localThumbnail;
  String? _thumbnailUrl;
  List<NewsCategory> _categories = [];

  @override
  void initState() {
    super.initState();
    _loadCategories();
    if (widget.existing != null) {
      _titleController.text = widget.existing!.title;
      _descController.text = widget.existing!.description;
      _imageUrls = List.from(widget.existing!.images);
      if (widget.existing!.image != null && !_imageUrls.contains(widget.existing!.image)) {
        _imageUrls.insert(0, widget.existing!.image!);
      }
      _mediaType = widget.existing!.mediaType;
      if (widget.existing!.videoUrl != null) {
        _videoUrlController.text = widget.existing!.videoUrl!;
      }
      _thumbnailUrl = widget.existing!.thumbnailUrl;
      _locationController.text = widget.existing!.location ?? '';
      _status = widget.existing!.status;
      _categoryId = widget.existing!.categoryId;
      _eventDate = widget.existing!.eventDate;
    }
  }
  
  Future<void> _loadCategories() async {
    final cats = await ref.read(apiServiceProvider).getNewsCategories();
    if (mounted) setState(() => _categories = cats);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _videoUrlController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage(imageQuality: 80);
    if (picked.isNotEmpty) {
      setState(() => _localImages.addAll(picked.map((e) => File(e.path))));
    }
  }

  Future<void> _pickVideo() async {
    final picker = ImagePicker();
    final picked = await picker.pickVideo(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _localVideo = File(picked.path);
        _videoUrlController.clear();
      });

      // Auto-generate thumbnail
      try {
        final String? thumbPath = await VideoThumbnail.thumbnailFile(
          video: picked.path,
          thumbnailPath: (await getTemporaryDirectory()).path,
          imageFormat: ImageFormat.JPEG,
          maxHeight: 480,
          quality: 75,
        );
        if (thumbPath != null && mounted) {
          setState(() => _localThumbnail = File(thumbPath));
        }
      } catch (e) {
        debugPrint('Thumbnail generation failed: $e');
      }
    }
  }

  Future<void> _pickThumbnail() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (picked != null) {
      setState(() => _localThumbnail = File(picked.path));
    }
  }

  Future<void> _selectEventDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _eventDate = picked);
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      AppDialogs.showErrorDialog(context, userMessage: 'Title is required.');
      return;
    }
    if (_mediaType == 'photo' && _imageUrls.isEmpty && _localImages.isEmpty) {
      AppDialogs.showErrorDialog(context, userMessage: 'Please add at least one photo.');
      return;
    }
    if (_mediaType == 'video' &&
        _localVideo == null &&
        _videoUrlController.text.trim().isEmpty &&
        (widget.existing?.videoUrl == null || widget.existing!.videoUrl!.isEmpty)) {
      AppDialogs.showErrorDialog(context, userMessage: 'Please upload a video or paste a video URL.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final api = ref.read(apiServiceProvider);
      List<String> finalUrls = [];
      String? videoUrl;
      String? thumbUrl = _thumbnailUrl;
      
      if (_mediaType == 'photo') {
        finalUrls = List.from(_imageUrls);
        for (var file in _localImages) {
          final url = await api.uploadFile(file, 'news');
          finalUrls.add(url);
        }
      } else if (_mediaType == 'video') {
        if (_localVideo != null) {
          videoUrl = await api.uploadVideo(_localVideo!, 'news_videos');
        } else {
          // Fallback: use pasted URL or existing URL
          final typed = _videoUrlController.text.trim();
          videoUrl = typed.isNotEmpty ? typed : widget.existing?.videoUrl;
        }

        // Upload custom thumbnail if picked
        if (_localThumbnail != null) {
          thumbUrl = await api.uploadFile(_localThumbnail!, 'news_thumbnails');
        }
      }

      final location = _locationController.text.trim().isNotEmpty ? _locationController.text.trim() : null;

      if (widget.existing != null) {
        await api.updateNewsPost(
          widget.existing!.id,
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          mediaType: _mediaType,
          images: finalUrls,
          imageUrl: finalUrls.isNotEmpty ? finalUrls.first : null,
          videoUrl: videoUrl,
          thumbnailUrl: thumbUrl,
          status: _status,
          categoryId: _categoryId,
          eventDate: _eventDate,
          location: location,
        );
      } else {
        await api.addNews(
          title: _titleController.text.trim(),
          description: _descController.text.trim(),
          mediaType: _mediaType,
          images: finalUrls,
          imageUrl: finalUrls.isNotEmpty ? finalUrls.first : null,
          videoUrl: videoUrl,
          thumbnailUrl: thumbUrl,
          status: _status,
          categoryId: _categoryId,
          eventDate: _eventDate,
          location: location,
        );
      }
      if (mounted) {
        await AppDialogs.showSuccessDialog(
          context, 
          message: widget.existing != null ? 'Post updated successfully!' : 'Post published successfully!',
        );
        if (mounted) Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, technicalError: e);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.93,
      maxChildSize: 0.97,
      minChildSize: 0.5,
      builder: (_, scrollController) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
              child: Row(
                children: [
                  Text(
                    widget.existing != null ? 'Edit Post' : 'New Post',
                    style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF1B3B5A)),
                  ),
                ],
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  const Text('Title *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _titleController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Infrastructure Development Update',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Description', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _descController,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Write something about this update...',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _categoryId,
                    items: _categories.map((c) => DropdownMenuItem(value: c.id, child: Text(c.name))).toList(),
                    onChanged: (val) => setState(() => _categoryId = val),
                    decoration: InputDecoration(
                      hintText: 'Select category',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Location', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _locationController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Nagpur',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      prefixIcon: const Icon(Icons.location_on_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('Event Date', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: _selectEventDate,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.shade400),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, color: Colors.grey),
                          const SizedBox(width: 12),
                          Text(_eventDate != null ? DateFormat('yyyy-MM-dd').format(_eventDate!) : 'Select event date'),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const SizedBox(height: 20),
                  // ── Media Type Toggle ────────────────────────────────────
                  const Text('Media Type', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'photo',
                        label: Text('📷  Photo'),
                        icon: Icon(Icons.image_outlined),
                      ),
                      ButtonSegment(
                        value: 'video',
                        label: Text('🎥  Video'),
                        icon: Icon(Icons.videocam_outlined),
                      ),
                    ],
                    selected: {_mediaType},
                    onSelectionChanged: (val) {
                      setState(() {
                        _mediaType = val.first;
                        if (_mediaType == 'photo') {
                          _localVideo = null;
                        } else {
                          _localImages.clear();
                          _imageUrls.clear();
                        }
                      });
                    },
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return saffron;
                        return null;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return Colors.white;
                        return null;
                      }),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Photo Section ────────────────────────────────────────
                  if (_mediaType == 'photo') ...[
                    if (_imageUrls.isNotEmpty || _localImages.isNotEmpty)
                      SizedBox(
                        height: 120,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          children: [
                            for (var url in _imageUrls)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(url, height: 120, width: 120, fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      right: 4, top: 4,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _imageUrls.remove(url)),
                                        child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            for (var file in _localImages)
                              Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: Stack(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(file, height: 120, width: 120, fit: BoxFit.cover),
                                    ),
                                    Positioned(
                                      right: 4, top: 4,
                                      child: GestureDetector(
                                        onTap: () => setState(() => _localImages.remove(file)),
                                        child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _pickImages,
                      icon: const Icon(Icons.add_photo_alternate_outlined),
                      label: const Text('Add Photos'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: saffron),
                        foregroundColor: saffron,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],

                  // ── Video Section ────────────────────────────────────────
                  if (_mediaType == 'video') ...[
                    if (_localVideo != null)
                      Stack(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.grey.shade50,
                              border: Border.all(color: saffron.withOpacity(0.6)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.video_file, color: saffron, size: 28),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _localVideo!.path.split('/').last,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
                                      ),
                                      const Text('Video selected', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Positioned(
                            right: -4, top: -4,
                            child: IconButton(
                              onPressed: () => setState(() => _localVideo = null),
                              icon: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _pickVideo,
                        icon: const Icon(Icons.video_call_outlined),
                        label: const Text('Upload Video from Gallery'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: saffron),
                          foregroundColor: saffron,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          minimumSize: const Size(double.infinity, 48),
                        ),
                      ),
                    if (_localVideo != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: OutlinedButton.icon(
                          onPressed: _pickVideo,
                          icon: const Icon(Icons.swap_horiz),
                          label: const Text('Replace Video'),
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.grey.shade400),
                            foregroundColor: Colors.grey.shade700,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            minimumSize: const Size(double.infinity, 44),
                          ),
                        ),
                      ),
                    const SizedBox(height: 16),
                    const Text('Video Thumbnail', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                    const SizedBox(height: 8),
                    if (_localThumbnail != null || _thumbnailUrl != null)
                      Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _localThumbnail != null 
                              ? Image.file(_localThumbnail!, height: 120, width: 200, fit: BoxFit.cover)
                              : Image.network(_thumbnailUrl!, height: 120, width: 200, fit: BoxFit.cover),
                          ),
                          Positioned(
                            right: 4, top: 4,
                            child: GestureDetector(
                              onTap: () => setState(() { _localThumbnail = null; _thumbnailUrl = null; }),
                              child: const CircleAvatar(radius: 12, backgroundColor: Colors.red, child: Icon(Icons.close, size: 16, color: Colors.white)),
                            ),
                          ),
                        ],
                      )
                    else
                      OutlinedButton.icon(
                        onPressed: _pickThumbnail,
                        icon: const Icon(Icons.add_photo_alternate_outlined),
                        label: const Text('Add Thumbnail/Preview Image'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: saffron),
                          foregroundColor: saffron,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          minimumSize: const Size(double.infinity, 44),
                        ),
                      ),
                  ],
                  // ── OR paste URL fallback ──────────────────────────────
                  if (_mediaType == 'video') ...[
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            'OR paste a video URL',
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ),
                        Expanded(child: Divider(color: Colors.grey.shade300)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _videoUrlController,
                      decoration: InputDecoration(
                        hintText: 'https://youtube.com/... or direct .mp4 link',
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        prefixIcon: const Icon(Icons.link),
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  const Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  const SizedBox(height: 8),
                  SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(value: 'published', label: Text('Published'), icon: Icon(Icons.public)),
                      ButtonSegment(value: 'draft', label: Text('Draft'), icon: Icon(Icons.drafts_outlined)),
                    ],
                    selected: {_status},
                    onSelectionChanged: (val) => setState(() => _status = val.first),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return saffron;
                        return null;
                      }),
                      foregroundColor: WidgetStateProperty.resolveWith((states) {
                        if (states.contains(WidgetState.selected)) return Colors.white;
                        return null;
                      }),
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: saffron,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 22, width: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                            )
                          : Text(
                              widget.existing != null ? 'Save Changes' : 'Publish Post',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
