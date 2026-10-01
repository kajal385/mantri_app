import 'package:mantri_app/core/utils/app_dialogs.dart';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mantri_app/core/services/firebase_service.dart';
import 'package:mantri_app/core/utils/image_helper.dart';

class SliderManagementScreen extends ConsumerStatefulWidget {
  const SliderManagementScreen({super.key});

  @override
  ConsumerState<SliderManagementScreen> createState() =>
      _SliderManagementScreenState();
}

class _SliderManagementScreenState extends ConsumerState<SliderManagementScreen> {
  bool _isUploading = false;

  final List<String> _defaultBanners = const [
    'assets/images/image.png',
    'assets/images/image2.jpg',
    'assets/images/image3.jpg',
  ];

  Future<void> _pickAndUpload() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      final croppedFile = await ImageHelper.cropImage(File(image.path));
      if (croppedFile != null) {
        setState(() => _isUploading = true);
        try {
          await ref
              .read(firestoreServiceProvider)
              .uploadSliderImage(croppedFile);
          ref.invalidate(sliderImagesProvider);
          if (mounted) {
            AppDialogs.showSuccessDialog(context, message: 'Custom slider image added successfully!');
          }
        } catch (e) {
          if (mounted) {
            AppDialogs.showErrorDialog(context, technicalError: e);
          }
        } finally {
          if (mounted) setState(() => _isUploading = false);
        }
      }
    }
  }

  Future<void> _toggleDefaultBanner(String bannerPath, bool isCurrentlyActive, List<String> currentUrls) async {
    setState(() => _isUploading = true);
    try {
      final dbPath = 'asset://$bannerPath';
      if (isCurrentlyActive) {
        // Toggle OFF (deactivate)
        if (currentUrls.isEmpty) {
          // If the DB list was empty, it meant all 3 were active.
          // To deactivate this one, we must add the OTHER TWO to the DB.
          for (final banner in _defaultBanners) {
            if (banner != bannerPath) {
              await ref.read(firestoreServiceProvider).uploadSliderImageLink('asset://$banner');
            }
          }
        } else {
          await ref.read(firestoreServiceProvider).deleteSliderImage(dbPath);
        }
      } else {
        // Toggle ON (activate)
        await ref.read(firestoreServiceProvider).uploadSliderImageLink(dbPath);
      }
      ref.invalidate(sliderImagesProvider);
      if (mounted) {
        AppDialogs.showErrorDialog(context);
      }
    } catch (e) {
      if (mounted) {
        AppDialogs.showErrorDialog(context, technicalError: e);
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sliderImages = ref.watch(sliderImagesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FE),
      appBar: AppBar(
        title: Text(
          'Manage Welcome Slider',
          style: GoogleFonts.poppins(
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF1B3B5A),
        foregroundColor: Colors.white,
      ),
      body: sliderImages.when(
        data: (urls) {
          // Built-in banners state
          final bool isUrlEmpty = urls.isEmpty;

          return Column(
            children: [
              if (_isUploading)
                const LinearProgressIndicator(color: Color(0xFFDB7E20)),

              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Section 1: Built-in Banners (Permanent Section)
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          color: const Color(0xFFDB7E20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Built-in Banners',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B3B5A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _defaultBanners.length,
                      itemBuilder: (context, index) {
                        final bannerPath = _defaultBanners[index];
                        final dbPath = 'asset://$bannerPath';
                        // Active if urls list is empty (default all ON) OR urls contains dbPath
                        final isActive = isUrlEmpty || urls.contains(dbPath);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Stack(
                              children: [
                                SizedBox(
                                  height: 120,
                                  width: double.infinity,
                                  child: Image.asset(
                                    bannerPath,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                  ),
                                ),
                                // Inactive grey overlay
                                if (!isActive)
                                  Positioned.fill(
                                    child: Container(
                                      color: Colors.black.withOpacity(0.4),
                                    ),
                                  ),
                                // Text info & Toggle
                                Positioned(
                                  bottom: 0,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    color: Colors.black.withOpacity(0.6),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Banner ${index + 1}',
                                          style: GoogleFonts.poppins(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Row(
                                          children: [
                                            Text(
                                              isActive ? 'ACTIVE' : 'INACTIVE',
                                              style: GoogleFonts.poppins(
                                                color: isActive ? const Color(0xFFDB7E20) : Colors.white70,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Switch(
                                              value: isActive,
                                              activeColor: const Color(0xFFDB7E20),
                                              onChanged: (val) => _toggleDefaultBanner(bannerPath, isActive, urls),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),

                    const SizedBox(height: 24),

                    // Section 2: Custom Uploads
                    Row(
                      children: [
                        Container(
                          width: 4,
                          height: 18,
                          color: const Color(0xFFDB7E20),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Custom Uploads',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF1B3B5A),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Filter only custom uploaded ones (not starting with asset://)
                    ...(() {
                      final customUrls = urls.where((u) => !u.startsWith('asset://')).toList();
                      if (customUrls.isEmpty) {
                        return [
                          Container(
                            height: 100,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.grey.shade200),
                            ),
                            child: Text(
                              'No custom uploads yet.\nTap "+" to add custom slider images.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          )
                        ];
                      }
                      return [
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            childAspectRatio: 1.1,
                          ),
                          itemCount: customUrls.length,
                          itemBuilder: (context, idx) {
                            final url = customUrls[idx];
                            return Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Image.network(
                                    url,
                                    fit: BoxFit.cover,
                                    alignment: Alignment.topCenter,
                                    width: double.infinity,
                                    height: double.infinity,
                                  ),
                                ),
                                Positioned(
                                  top: 6,
                                  right: 6,
                                  child: CircleAvatar(
                                    backgroundColor: Colors.red,
                                    radius: 16,
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete,
                                        color: Colors.white,
                                        size: 14,
                                      ),
                                      onPressed: () => _confirmDelete(url),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                      ];
                    })(),
                  ],
                ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _isUploading ? null : _pickAndUpload,
        label: const Text('Add Custom Photo'),
        icon: const Icon(Icons.add_a_photo),
        backgroundColor: const Color(0xFFDB7E20),
        foregroundColor: Colors.white,
      ),
    );
  }

  Future<void> _confirmDelete(String url) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete Image?'),
            content: const Text(
              'Are you sure you want to remove this custom image?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      setState(() => _isUploading = true);
      try {
        await ref.read(firestoreServiceProvider).deleteSliderImage(url);
        ref.invalidate(sliderImagesProvider);
      } catch (e) {
        if (mounted) {
          AppDialogs.showErrorDialog(context, technicalError: e);
        }
      } finally {
        if (mounted) setState(() => _isUploading = false);
      }
    }
  }
}
