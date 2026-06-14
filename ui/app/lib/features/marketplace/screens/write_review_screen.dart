import 'package:flutter/material.dart';
import 'package:sync_app/core/utils/injection.dart';
import 'package:sync_app/features/marketplace/data/marketplace_remote_data_source.dart';
import 'package:sync_app/features/marketplace/theme/marketplace_theme.dart';
import 'package:sync_app/features/marketplace/widgets/rating_stars.dart';

class WriteReviewScreen extends StatefulWidget {
  const WriteReviewScreen({
    super.key,
    required this.targetType,
    required this.targetId,
    this.orderId,
  });

  final String targetType;
  final String targetId;
  final String? orderId;

  @override
  State<WriteReviewScreen> createState() => _WriteReviewScreenState();
}

class _WriteReviewScreenState extends State<WriteReviewScreen> {
  final _api = getIt<MarketplaceRemoteDataSource>();
  final _comment = TextEditingController();
  int _rating = 5;
  bool _saving = false;

  Future<void> _submit() async {
    setState(() => _saving = true);
    try {
      await _api.createReview({
        'targetType': widget.targetType,
        'targetId': widget.targetId,
        'rating': _rating,
        'comment': _comment.text.trim(),
        if (widget.orderId != null) 'orderId': widget.orderId,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Viết đánh giá')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (i) {
                final star = i + 1;
                return IconButton(
                  onPressed: () => setState(() => _rating = star),
                  icon: Icon(
                    star <= _rating ? Icons.star_rounded : Icons.star_outline,
                    color: const Color(0xFFF5A623),
                  ),
                );
              }),
            ),
            RatingStars(rating: _rating.toDouble()),
            const SizedBox(height: 12),
            TextField(
              controller: _comment,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Nhận xét của bạn',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: _saving ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: MarketplaceTheme.primary),
              child: const Text('Gửi đánh giá'),
            ),
          ],
        ),
      ),
    );
  }
}
