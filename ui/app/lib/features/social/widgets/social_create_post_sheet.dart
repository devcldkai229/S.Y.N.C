import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/data/repositories/social_repository.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';
import 'package:sync_app/features/social/cubit/social_cubit.dart';

class SocialCreatePostSheet extends StatefulWidget {
  const SocialCreatePostSheet({super.key});

  static Future<void> show(BuildContext context) {
    final cubit = context.read<SocialCubit>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.cardBackground,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
  final _filePathCtrl = TextEditingController();

  final _repo = getIt<SocialRepository>();
  final _profileApi = getIt<ProfileApiService>();

  final List<String> _filePaths = [];
  bool _isCreating = false;

  @override
  void dispose() {
    _contentCtrl.dispose();
    _filePathCtrl.dispose();
    super.dispose();
  }

  void _addFilePath() {
    final p = _filePathCtrl.text.trim();
    if (p.isEmpty) return;

    final exists = File(p).existsSync();
    if (!exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('File not found: $p')),
      );
      return;
    }

    setState(() {
      _filePaths.add(p);
      _filePathCtrl.clear();
    });
  }

  Future<void> _create() async {
    if (_isCreating) return;

    final content = _contentCtrl.text.trim();
    if (content.isEmpty && _filePaths.isEmpty) return;
    setState(() => _isCreating = true);

    try {
      final settings = await _profileApi.getProfileSettings();
      final authorFullName = settings.basic.fullName;
      final authorAvatarUrl = settings.basic.avatarUrl;

      final mediaUrls = _filePaths.isEmpty ? <String>[] : await _repo.uploadMediaFiles(_filePaths);

      await _repo.createPost(
        content: content,
        mediaUrls: mediaUrls,
        isPublic: true,
        authorFullName: authorFullName,
        authorAvatarUrl: authorAvatarUrl,
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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'Create post',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _contentCtrl,
              decoration: const InputDecoration(
                hintText: 'What do you want to share?',
                border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
              ),
              maxLines: 4,
            ),
            const SizedBox(height: 16),
            const Text(
              'Media (local file path → upload to MinIO)',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _filePathCtrl,
                    decoration: const InputDecoration(
                      hintText: r'e.g. C:\path\video.mp4 or C:\path\image.png',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(14)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filled(
                  onPressed: _addFilePath,
                  style: IconButton.styleFrom(backgroundColor: AppColors.primaryGreen),
                  icon: const Icon(Icons.add_rounded, color: Colors.white),
                )
              ],
            ),
            if (_filePaths.isNotEmpty) ...[
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _filePaths
                    .map(
                      (p) => Chip(
                        label: Text(p.split(RegExp(r'[\\/]+')).last),
                        backgroundColor: AppColors.lightGreen.withValues(alpha: 0.12),
                        deleteIcon: const Icon(Icons.close, size: 16),
                        onDeleted: () {
                          setState(() {
                            _filePaths.remove(p);
                          });
                        },
                      ),
                    )
                    .toList(),
              ),
            ],
            const SizedBox(height: 18),
            ElevatedButton(
              onPressed: _isCreating ? null : _create,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _isCreating
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Post',
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
            ),
          ],
        ),
      ),
    );
  }
}

