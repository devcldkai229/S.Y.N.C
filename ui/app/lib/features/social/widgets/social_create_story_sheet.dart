import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:sync_app/core/locale/l10n_extensions.dart';
import 'package:sync_app/core/permissions/media_permissions.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';
import 'package:sync_app/features/social/cubit/social_cubit.dart';
import 'package:sync_app/shared/widgets/sync_avatar.dart';

class _PickedMedia {
  const _PickedMedia({required this.file, required this.isVideo});

  final XFile file;
  final bool isVideo;
}

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

  final List<_PickedMedia> _media = [];
  bool _isCreating = false;
  bool _loadingProfile = true;
  String _displayName = '';
  String? _avatarUrl;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    try {
      final settings = await _profileApi.getProfileSettings();
      if (!mounted) return;
      setState(() {
        _displayName = settings.basic.fullName;
        _avatarUrl = settings.basic.avatarUrl;
        _loadingProfile = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loadingProfile = false);
    }
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    super.dispose();
  }

  bool get _canPost => _media.isNotEmpty;

  void _removeAt(int index) => setState(() => _media.removeAt(index));

  Future<void> _pickImages() async {
    if (!await MediaPermissions.ensurePhotos(context)) return;
    final picked = await _picker.pickMultiImage(imageQuality: 90);
    if (picked.isEmpty) return;
    setState(() {
      _media.addAll(picked.map((f) => _PickedMedia(file: f, isVideo: false)));
    });
  }

  Future<void> _pickVideo() async {
    if (!await MediaPermissions.ensureVideoLibrary(context)) return;
    final picked = await _picker.pickVideo(source: ImageSource.gallery);
    if (picked == null) return;
    setState(() => _media.add(_PickedMedia(file: picked, isVideo: true)));
  }

  Future<void> _takePhoto() async {
    if (!await MediaPermissions.ensureCamera(context)) return;
    final picked = await _picker.pickImage(source: ImageSource.camera, imageQuality: 90);
    if (picked == null) return;
    setState(() => _media.add(_PickedMedia(file: picked, isVideo: false)));
  }

  Future<void> _create() async {
    if (_isCreating || !_canPost) return;
    setState(() => _isCreating = true);

    try {
      final settings = await _profileApi.getProfileSettings();
      final caption =
          _captionCtrl.text.trim().isEmpty ? null : _captionCtrl.text.trim();
      final name = settings.basic.fullName;
      final avatar = settings.basic.avatarUrl;

      var created = 0;
      for (final item in List<_PickedMedia>.from(_media)) {
        await _repo.createStory(
          file: item.file,
          caption: caption,
          authorFullName: name,
          authorAvatarUrl: avatar,
        );
        created += 1;
      }

      if (!mounted) return;
      Navigator.pop(context);
      if (!context.mounted) return;
      final messenger = ScaffoldMessenger.of(context);
      final l10n = context.l10n;
      final cubit = context.read<SocialCubit>();
      await cubit.refreshStories();
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.socialStoriesCreated(created))),
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
    final l10n = context.l10n;
    final keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final bottomPad = MediaQuery.of(context).padding.bottom;
    final name = _displayName.trim().isEmpty ? '…' : _displayName;

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
                  if (_loadingProfile)
                    const SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    SyncAvatar(
                      name: name,
                      imageUrl: _avatarUrl,
                      radius: 18,
                    ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.socialCreateStory,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton(
                    onPressed: (_canPost && !_isCreating) ? _create : null,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primaryGreen,
                      disabledBackgroundColor:
                          AppColors.primaryGreen.withValues(alpha: 0.35),
                      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                    ),
                    child: _isCreating
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            l10n.socialPostStory,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 14,
                            ),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  l10n.socialPickMediaHint,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
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
                    if (_media.isEmpty)
                      AspectRatio(
                        aspectRatio: 9 / 16,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            color: AppColors.lightGreen.withValues(alpha: 0.2),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 48,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  l10n.socialPickMediaEmpty,
                                  style: const TextStyle(color: AppColors.textMuted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      )
                    else
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _media.length,
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 9 / 16,
                        ),
                        itemBuilder: (context, index) {
                          final item = _media[index];
                          return _MediaPreviewTile(
                            item: item,
                            onRemove: () => _removeAt(index),
                          );
                        },
                      ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _captionCtrl,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: l10n.socialStoryCaptionHint,
                        border: const OutlineInputBorder(),
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
                  _ToolbarButton(
                    icon: Icons.photo_library_outlined,
                    label: l10n.socialStoryPhoto,
                    onTap: _pickImages,
                  ),
                  _ToolbarButton(
                    icon: Icons.videocam_outlined,
                    label: l10n.socialStoryVideo,
                    onTap: _pickVideo,
                  ),
                  _ToolbarButton(
                    icon: Icons.camera_alt_outlined,
                    label: l10n.socialStoryCamera,
                    onTap: _takePhoto,
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

class _MediaPreviewTile extends StatelessWidget {
  const _MediaPreviewTile({required this.item, required this.onRemove});

  final _PickedMedia item;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (item.isVideo)
            const ColoredBox(
              color: Colors.black87,
              child: Center(
                child: Icon(Icons.videocam_rounded, size: 36, color: Colors.white70),
              ),
            )
          else
            FutureBuilder<Uint8List>(
              future: item.file.readAsBytes(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(
                    child: CircularProgressIndicator(strokeWidth: 2),
                  );
                }
                return Image.memory(snapshot.data!, fit: BoxFit.cover);
              },
            ),
          Positioned(
            top: 4,
            right: 4,
            child: IconButton.filled(
              style: IconButton.styleFrom(
                backgroundColor: Colors.black54,
                padding: const EdgeInsets.all(4),
                minimumSize: const Size(28, 28),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: onRemove,
              icon: const Icon(Icons.close, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

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
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primaryGreen,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
