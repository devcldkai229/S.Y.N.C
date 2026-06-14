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

class SocialCreateStorySheet extends StatefulWidget {
  const SocialCreateStorySheet({super.key});

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
        child: const SocialCreateStorySheet(),
      ),
    );
  }

  @override
  State<SocialCreateStorySheet> createState() => _SocialCreateStorySheetState();
}

class _SocialCreateStorySheetState extends State<SocialCreateStorySheet> {
  final _captionCtrl = TextEditingController();
  final _picker = ImagePicker();
  final _repo = getIt<SocialRepository>();
  final _profileApi = getIt<ProfileApiService>();

  XFile? _mediaFile;
  bool _isVideo = false;
  bool _isCreating = false;

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  bool get _canPost => _mediaFile != null;

  void _clearMedia() => setState(() {
        _mediaFile = null;
        _isVideo = false;
      });

  Future<void> _pickImage() async {
    if (!await MediaPermissions.ensurePhotos(context)) return;
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 90);
    if (picked == null) return;
    setState(() {
      _mediaFile = picked;
      _isVideo = false;
    });
  }

  Future<void> _pickVideo() async {
    if (!await MediaPermissions.ensureVideoLibrary(context)) return;
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() {
      _mediaFile = picked;
      _isVideo = true;
    });
  }

  Future<void> _takePhoto() async {
    if (!await MediaPermissions.ensureCamera(context)) return;
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (picked == null) return;
    setState(() {
      _mediaFile = picked;
      _isVideo = false;
    });
  }

  Future<void> _create() async {
    if (_isCreating || !_canPost || _mediaFile == null) return;
    setState(() => _isCreating = true);

    try {
      final settings = await _profileApi.getProfileSettings();
      await _repo.createStory(
        file: _mediaFile!,
        caption: _captionCtrl.text.trim().isEmpty ? null : _captionCtrl.text.trim(),
        authorFullName: settings.basic.fullName,
        authorAvatarUrl: settings.basic.avatarUrl,
      );

      if (!mounted) return;
      Navigator.pop(context);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final cubit = context.read<SocialCubit>();
      await cubit.refreshStories();
      messenger.showSnackBar(
        const SnackBar(content: Text('Story đã được đăng (tồn tại 24 giờ)')),
      );
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
      height: screenHeight * 0.72,
      child: Padding(
        padding: EdgeInsets.only(bottom: keyboardHeight),
        child: Column(
          children: [
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
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text(
                    'Tạo story',
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
                        : const Text('Đăng', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '1 ảnh hoặc 1 video · tự xóa sau 24 giờ',
                  style: TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ),
            ),
            const Divider(height: 20),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AspectRatio(
                      aspectRatio: 9 / 16,
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: AppColors.lightGreen.withValues(alpha: 0.2),
                          border: Border.all(color: AppColors.border),
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _mediaFile == null
                            ? const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.add_photo_alternate_outlined, size: 48, color: AppColors.textMuted),
                                    SizedBox(height: 8),
                                    Text('Chọn 1 ảnh hoặc 1 video', style: TextStyle(color: AppColors.textMuted)),
                                  ],
                                ),
                              )
                            : Stack(
                                fit: StackFit.expand,
                                children: [
                                  if (_isVideo)
                                    const ColoredBox(
                                      color: Colors.black87,
                                      child: Center(
                                        child: Icon(Icons.videocam_rounded, size: 64, color: Colors.white70),
                                      ),
                                    )
                                  else
                                    FutureBuilder<Uint8List>(
                                      future: _mediaFile!.readAsBytes(),
                                      builder: (context, snapshot) {
                                        if (!snapshot.hasData) {
                                          return const Center(child: CircularProgressIndicator(strokeWidth: 2));
                                        }
                                        return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                      },
                                    ),
                                  Positioned(
                                    top: 8,
                                    right: 8,
                                    child: IconButton.filled(
                                      style: IconButton.styleFrom(backgroundColor: Colors.black54),
                                      onPressed: _clearMedia,
                                      icon: const Icon(Icons.close, color: Colors.white, size: 20),
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _captionCtrl,
                      maxLines: 2,
                      decoration: const InputDecoration(
                        hintText: 'Thêm chú thích (tuỳ chọn)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: AppColors.cardBackground,
                border: Border(top: BorderSide(color: AppColors.border)),
              ),
              padding: EdgeInsets.fromLTRB(8, 8, 8, 8 + bottomPad),
              child: Row(
                children: [
                  _ToolbarButton(icon: Icons.photo_library_outlined, label: 'Ảnh', onTap: _pickImage),
                  _ToolbarButton(icon: Icons.videocam_outlined, label: 'Video', onTap: _pickVideo),
                  _ToolbarButton(icon: Icons.camera_alt_outlined, label: 'Camera', onTap: _takePhoto),
                ],
              ),
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
            Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primaryGreen)),
          ],
        ),
      ),
    );
  }
}
