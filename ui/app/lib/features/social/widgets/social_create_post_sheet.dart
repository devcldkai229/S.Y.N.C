import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sync_app/core/permissions/media_permissions.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';
import 'package:sync_app/features/social/cubit/social_cubit.dart';
import 'package:sync_app/features/social/utils/social_media_utils.dart';

class SocialCreatePostSheet extends StatefulWidget {
  const SocialCreatePostSheet({super.key});

  static Future<void> show(BuildContext context) {
    final cubit = context.read<SocialCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => BlocProvider.value(
        value: cubit,
        child: const SocialCreatePostSheet(),
      ),
    );
  }

  @override
  State<SocialCreatePostSheet> createState() => _SocialCreatePostSheetState();
}

class _SocialCreatePostSheetState extends State<SocialCreatePostSheet> {
  final _contentCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _repo = getIt<SocialRepository>();
  final _profileApi = getIt<ProfileApiService>();

  final List<_MediaItem> _media = [];
  bool _isCreating = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    super.dispose();
  }

  bool get _canPost => _contentCtrl.text.trim().isNotEmpty || _media.isNotEmpty;

  int get _imageCount => _media.where((m) => !m.isVideo).length;
  int get _videoCount => _media.where((m) => m.isVideo).length;

  void _showLimitSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _canAddImages(int count) {
    if (_imageCount + count > SocialMediaUtils.maxPostImages) {
      _showLimitSnack('Tối đa ${SocialMediaUtils.maxPostImages} ảnh mỗi bài viết');
      return false;
    }
    return true;
  }

  bool _canAddVideo() {
    if (_videoCount >= SocialMediaUtils.maxPostVideos) {
      _showLimitSnack('Tối đa ${SocialMediaUtils.maxPostVideos} video mỗi bài viết');
      return false;
    }
    return true;
  }

  Future<void> _pickImages() async {
    if (!await MediaPermissions.ensurePhotos(context)) return;
    final picked = await _picker.pickMultiImage(imageQuality: 85);
    if (picked.isEmpty) return;
    if (!_canAddImages(picked.length)) return;
    setState(() {
      for (final f in picked) {
        if (_imageCount >= SocialMediaUtils.maxPostImages) break;
        _media.add(_MediaItem(file: f, isVideo: false));
      }
    });
  }

  Future<void> _pickVideo() async {
    if (!await MediaPermissions.ensureVideoLibrary(context)) return;
    if (!_canAddVideo()) return;
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _media.add(_MediaItem(file: picked, isVideo: true)));
  }

  Future<void> _takePhoto() async {
    if (!await MediaPermissions.ensureCamera(context)) return;
    if (!_canAddImages(1)) return;
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85);
    if (picked == null) return;
    setState(() => _media.add(_MediaItem(file: picked, isVideo: false)));
  }

  Future<void> _create() async {
    if (_isCreating || !_canPost) return;
    setState(() => _isCreating = true);

    try {
      final settings = await _profileApi.getProfileSettings();
      final files = _media.map((m) => m.file).toList();
      final mediaUrls = files.isEmpty ? <String>[] : await _repo.uploadMediaFiles(files);

      await _repo.createPost(
        content: _contentCtrl.text.trim(),
        mediaUrls: mediaUrls,
        isPublic: true,
        authorFullName: settings.basic.fullName,
        authorAvatarUrl: settings.basic.avatarUrl,
      );

      if (!mounted) return;
      Navigator.pop(context);
      if (!context.mounted) return;
      context.read<SocialCubit>().loadFeed(refresh: true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString())),
      );
    } finally {
      if (mounted) setState(() => _isCreating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;

    return SizedBox(
      height: screenHeight * 0.82,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Column(
          children: [
            // Drag handle
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),

            // Header row
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Bài viết mới',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.textPrimary),
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: (_canPost && !_isCreating) ? _create : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      disabledBackgroundColor: AppColors.primaryGreen.withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text(
                            'Đăng',
                            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                          ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 14),
            const Divider(height: 1),

            // Scrollable body
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Text field
                    TextField(
                      controller: _contentCtrl,
                      maxLines: null,
                      minLines: 5,
                      style: const TextStyle(fontSize: 15, color: AppColors.textPrimary, height: 1.5),
                      decoration: InputDecoration(
                        hintText: 'Bạn đang nghĩ gì thế?',
                        hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 15),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        contentPadding: EdgeInsets.zero,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),

                    // Media previews
                    if (_media.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _media.length + 1,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, i) {
                            if (i == _media.length) {
                              return _AddMoreButton(
                                onPickImages: _pickImages,
                                onPickVideo: _pickVideo,
                              );
                            }
                            return _Thumbnail(
                              item: _media[i],
                              onRemove: () => setState(() => _media.removeAt(i)),
                            );
                          },
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Bottom toolbar
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomPad),
              child: Row(
                children: [
                  _ToolbarButton(
                    icon: Icons.photo_library_outlined,
                    label: 'Photos',
                    onTap: _pickImages,
                  ),
                  _ToolbarButton(
                    icon: Icons.videocam_outlined,
                    label: 'Video',
                    onTap: _pickVideo,
                  ),
                  _ToolbarButton(
                    icon: Icons.camera_alt_outlined,
                    label: 'Camera',
                    onTap: _takePhoto,
                  ),
                  const Spacer(),
                  if (_media.isNotEmpty)
                    Text(
                      '$_imageCount ảnh · $_videoCount video',
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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

// ─── Data ───────────────────────────────────────────────────────────────────

class _MediaItem {
  const _MediaItem({required this.file, required this.isVideo});
  final XFile file;
  final bool isVideo;
}

// ─── Widgets ─────────────────────────────────────────────────────────────────

class _Thumbnail extends StatelessWidget {
  const _Thumbnail({required this.item, required this.onRemove});
  final _MediaItem item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 110,
          height: 110,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            color: AppColors.lightGreen.withValues(alpha: 0.25),
          ),
          clipBehavior: Clip.antiAlias,
          child: item.isVideo
              ? const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.videocam_rounded, size: 36, color: AppColors.primaryGreen),
                    SizedBox(height: 4),
                    Text(
                      'Video',
                      style: TextStyle(fontSize: 11, color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              : FutureBuilder<Uint8List>(
                  future: item.file.readAsBytes(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                    }
                    return Image.memory(snapshot.data!, fit: BoxFit.cover);
                  },
                ),
        ),
        Positioned(
          top: -6,
          right: -6,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              child: const Icon(Icons.close, size: 14, color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }
}

class _AddMoreButton extends StatelessWidget {
  const _AddMoreButton({required this.onPickImages, required this.onPickVideo});
  final VoidCallback onPickImages;
  final VoidCallback onPickVideo;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onPickImages,
      child: Container(
        width: 110,
        height: 110,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.primaryGreen, width: 1.5),
          color: AppColors.lightGreen.withValues(alpha: 0.1),
        ),
        child: const Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_photo_alternate_outlined, size: 30, color: AppColors.primaryGreen),
            SizedBox(height: 4),
            Text(
              'Add more',
              style: TextStyle(fontSize: 11, color: AppColors.primaryGreen, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: AppColors.primaryGreen),
            const SizedBox(width: 5),
            Text(
              label,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryGreen),
            ),
          ],
        ),
      ),
    );
  }
}
