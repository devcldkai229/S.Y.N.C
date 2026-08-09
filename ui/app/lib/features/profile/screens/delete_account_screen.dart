import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sync_app/core/constants/app_routes.dart';
import 'package:sync_app/core/theme/app_colors.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/auth/services/auth_service.dart';
import 'package:sync_app/features/profile/services/profile_api_service.dart';

/// In-app account deletion (Google Play / privacy requirement).
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  bool _understood = false;
  bool _submitting = false;
  String? _error;

  Future<void> _confirmAndDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          'Xác nhận xoá tài khoản',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
        content: const Text(
          'Hành động này không thể hoàn tác ngay. Tài khoản sẽ bị vô hiệu hoá, '
          'dữ liệu cá nhân được ẩn danh, và mọi phiên đăng nhập bị thu hồi.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Huỷ', style: TextStyle(color: AppColors.textMuted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              'Xoá vĩnh viễn',
              style: TextStyle(color: Colors.red.shade600, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      await getIt<ProfileApiService>().deleteAccount();
      await getIt<AuthService>().logout();
      if (!mounted) return;
      context.go(AppRoutes.login);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tài khoản đã được xoá.')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        title: const Text(
          'Xoá tài khoản',
          style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.textPrimary),
        ),
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.red.shade100),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.red.shade600),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Xoá tài khoản sẽ dừng mọi quyền truy cập SYNC trên thiết bị này '
                      'và các thiết bị đã đăng nhập.',
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.4,
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Sẽ bị xoá / ẩn danh',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const _Bullet('Họ tên, email, số điện thoại, ảnh đại diện'),
            const _Bullet('Phiên đăng nhập và thiết bị đã lưu'),
            const _Bullet('Tuỳ chọn AI và hồ sơ fitness gắn với tài khoản'),
            const SizedBox(height: 20),
            const Text(
              'Có thể giữ lại (theo luật / vận hành)',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 10),
            const _Bullet('Hoá đơn / giao dịch ở dạng tối thiểu'),
            const _Bullet('Bản ghi ẩn danh phục vụ chống gian lận'),
            const SizedBox(height: 24),
            CheckboxListTile(
              value: _understood,
              onChanged: _submitting
                  ? null
                  : (v) => setState(() => _understood = v ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              activeColor: AppColors.primaryGreen,
              title: const Text(
                'Tôi hiểu dữ liệu cá nhân sẽ bị xoá/ẩn danh và không thể đăng nhập lại bằng tài khoản này.',
                style: TextStyle(fontSize: 14, height: 1.35),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: Colors.red.shade600, fontSize: 13)),
            ],
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: (_understood && !_submitting) ? _confirmAndDelete : null,
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.red.shade500,
                  disabledBackgroundColor: AppColors.border,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(
                  _submitting ? 'Đang xoá…' : 'Xoá tài khoản',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('•  ', style: TextStyle(color: AppColors.textMuted)),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textMuted),
            ),
          ),
        ],
      ),
    );
  }
}
