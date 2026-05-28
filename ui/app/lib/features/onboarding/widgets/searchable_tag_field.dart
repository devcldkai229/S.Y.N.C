import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';

/// Searchable multi-select with horizontal chips — shows [popularTags] until the user searches.
class SearchableTagField extends StatefulWidget {
  const SearchableTagField({
    super.key,
    required this.label,
    required this.hint,
    required this.catalog,
    required this.popularTags,
    required this.selected,
    required this.onChanged,
    this.exclusiveNoneTag,
    this.required = false,
  });

  final String label;
  final String hint;
  final List<String> catalog;
  final List<String> popularTags;
  final List<String> selected;
  final ValueChanged<List<String>> onChanged;
  final String? exclusiveNoneTag;
  final bool required;

  @override
  State<SearchableTagField> createState() => _SearchableTagFieldState();
}

class _SearchableTagFieldState extends State<SearchableTagField> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _visibleSuggestions {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) {
      return widget.popularTags;
    }
    return widget.catalog
        .where((t) => t.toLowerCase().contains(q))
        .where((t) => !widget.selected.contains(t))
        .take(12)
        .toList();
  }

  void _toggle(String tag) {
    final next = List<String>.from(widget.selected);
    if (next.contains(tag)) {
      next.remove(tag);
    } else {
      if (widget.exclusiveNoneTag != null && tag == widget.exclusiveNoneTag) {
        next
          ..clear()
          ..add(tag);
      } else {
        if (widget.exclusiveNoneTag != null) {
          next.remove(widget.exclusiveNoneTag);
        }
        next.add(tag);
      }
    }
    widget.onChanged(next);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              widget.label,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            if (widget.required)
              const Text(' *', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.search, size: 20),
            filled: true,
            fillColor: AppColors.cardBackground,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            isDense: true,
          ),
          onChanged: (v) => setState(() => _query = v),
        ),
        if (widget.selected.isNotEmpty) ...[
          const SizedBox(height: 10),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.selected.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final tag = widget.selected[i];
                return InputChip(
                  label: Text(tag, style: const TextStyle(fontSize: 12)),
                  onDeleted: () => _toggle(tag),
                  backgroundColor: AppColors.primaryGreen.withValues(alpha: 0.15),
                  deleteIconColor: AppColors.primaryGreen,
                );
              },
            ),
          ),
        ],
        const SizedBox(height: 10),
        SizedBox(
          height: 38,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: _visibleSuggestions.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) {
              final tag = _visibleSuggestions[i];
              final isSelected = widget.selected.contains(tag);
              return FilterChip(
                label: Text(tag, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                onSelected: (_) => _toggle(tag),
                selectedColor: AppColors.primaryGreen.withValues(alpha: 0.25),
                checkmarkColor: AppColors.primaryGreen,
              );
            },
          ),
        ),
      ],
    );
  }
}
