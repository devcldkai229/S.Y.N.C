import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:sync_app/core/theme/app_colors.dart';

/// Renders Insight `chart` / `insight_dashboard` display_payload cards.
class CynInsightChartCard extends StatelessWidget {
  const CynInsightChartCard({super.key, required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final type = payload['type']?.toString() ?? '';
    if (type == 'insight_dashboard') {
      return _dashboard(payload);
    }
    return _singleChart(payload);
  }

  Widget _dashboard(Map<String, dynamic> dash) {
    final charts = dash['charts'];
    final verdict = (dash['verdict'] ?? '').toString();
    final confidence = (dash['confidence'] ?? '').toString();
    final factors = dash['factors'];
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Insight Dashboard',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (verdict.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(verdict, style: const TextStyle(fontSize: 12, color: AppColors.textPrimary)),
          ],
          if (confidence.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Độ tin cậy: $confidence',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
          if (factors is List && factors.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Dựa trên: ${factors.take(6).join(' · ')}',
              style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
            ),
          ],
          const SizedBox(height: 10),
          if (charts is List)
            ...charts.whereType<Map>().take(6).map((raw) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _singleChart(Map<String, dynamic>.from(raw), nested: true),
              );
            }),
        ],
      ),
    );
  }

  Widget _singleChart(Map<String, dynamic> chart, {bool nested = false}) {
    final chartType = (chart['chartType'] ?? chart['type'] ?? 'line').toString();
    final title = (chart['title'] ?? 'Biểu đồ').toString();
    final subtitle = (chart['subtitle'] ?? '').toString();
    final summary = (chart['summary'] ?? '').toString();
    final unit = (chart['unit'] ?? '').toString();
    final xLabels = (chart['xLabels'] is List)
        ? (chart['xLabels'] as List).map((e) => e.toString()).toList()
        : <String>[];
    final seriesRaw = chart['series'];
    final series = <_Series>[];
    if (seriesRaw is List) {
      for (final s in seriesRaw.whereType<Map>()) {
        final data = <double?>[];
        final rawData = s['data'];
        if (rawData is List) {
          for (final v in rawData) {
            if (v == null) {
              data.add(null);
            } else if (v is num) {
              data.add(v.toDouble());
            } else {
              data.add(double.tryParse(v.toString()));
            }
          }
        }
        series.add(_Series(
          name: (s['name'] ?? 'Series').toString(),
          data: data,
          dashed: (s['style']?.toString() ?? '') == 'dashed',
        ));
      }
    }

    final body = switch (chartType) {
      'pie' => _pie(series),
      'heatmap' => _heatmap(xLabels, series),
      'bar' || 'stackedBar' => _bar(xLabels, series, stacked: chartType == 'stackedBar'),
      'area' => _line(xLabels, series, isArea: true),
      _ => _line(xLabels, series, isArea: false),
    };

    return Container(
      width: double.infinity,
      padding: nested ? EdgeInsets.zero : const EdgeInsets.all(12),
      decoration: nested
          ? null
          : BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.borderLight),
            ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (subtitle.isNotEmpty)
            Text(subtitle, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          if (unit.isNotEmpty)
            Text('Đơn vị: $unit', style: const TextStyle(fontSize: 10, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          SizedBox(height: 180, child: body),
          if (series.length > 1) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 10,
              children: [
                for (var i = 0; i < series.length; i++)
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _color(i),
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        series[i].name,
                        style: const TextStyle(fontSize: 10, color: AppColors.textMuted),
                      ),
                    ],
                  ),
              ],
            ),
          ],
          if (summary.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(summary, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }

  Widget _line(List<String> labels, List<_Series> series, {required bool isArea}) {
    if (series.isEmpty || series.first.data.isEmpty) {
      return const Center(child: Text('Không có dữ liệu', style: TextStyle(fontSize: 12)));
    }
    final n = series.map((s) => s.data.length).fold<int>(0, math.max);
    double maxY = 1;
    for (final s in series) {
      for (final v in s.data) {
        if (v != null && v > maxY) maxY = v;
      }
    }
    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY * 1.15,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              interval: math.max(1, (n / 4).floorToDouble()),
              getTitlesWidget: (v, _) {
                final i = v.round();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    labels[i],
                    style: const TextStyle(fontSize: 8, color: AppColors.textMuted),
                  ),
                );
              },
            ),
          ),
        ),
        lineBarsData: [
          for (var si = 0; si < series.length; si++)
            LineChartBarData(
              spots: [
                for (var i = 0; i < series[si].data.length; i++)
                  if (series[si].data[i] != null)
                    FlSpot(i.toDouble(), series[si].data[i]!),
              ],
              isCurved: true,
              color: _color(si),
              barWidth: 2.5,
              dotData: const FlDotData(show: false),
              dashArray: series[si].dashed ? [6, 4] : null,
              belowBarData: isArea
                  ? BarAreaData(show: true, color: _color(si).withValues(alpha: 0.15))
                  : BarAreaData(show: false),
            ),
        ],
      ),
    );
  }

  Widget _bar(List<String> labels, List<_Series> series, {required bool stacked}) {
    if (series.isEmpty || series.first.data.isEmpty) {
      return const Center(child: Text('Không có dữ liệu', style: TextStyle(fontSize: 12)));
    }
    final n = series.first.data.length;
    double maxY = 1;
    for (var i = 0; i < n; i++) {
      var sum = 0.0;
      for (final s in series) {
        final v = (i < s.data.length ? (s.data[i] ?? 0) : 0).toDouble();
        if (stacked) {
          sum += v;
        } else if (v > maxY) {
          maxY = v;
        }
      }
      if (stacked && sum > maxY) maxY = sum;
    }
    return BarChart(
      BarChartData(
        maxY: maxY * 1.15,
        gridData: const FlGridData(show: true, drawVerticalLine: false),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, _) => Text(
                v.toStringAsFixed(0),
                style: const TextStyle(fontSize: 9, color: AppColors.textMuted),
              ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                return Text(labels[i], style: const TextStyle(fontSize: 8, color: AppColors.textMuted));
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < n; i++)
            BarChartGroupData(
              x: i,
              barRods: stacked
                  ? [
                      BarChartRodData(
                        toY: series.fold<double>(
                          0,
                          (a, s) => a + (i < s.data.length ? (s.data[i] ?? 0) : 0),
                        ),
                        width: 12,
                        rodStackItems: [
                          for (var si = 0; si < series.length; si++)
                            BarChartRodStackItem(
                              series.take(si).fold<double>(
                                    0,
                                    (a, s) => a + (i < s.data.length ? (s.data[i] ?? 0) : 0),
                                  ),
                              series.take(si + 1).fold<double>(
                                    0,
                                    (a, s) => a + (i < s.data.length ? (s.data[i] ?? 0) : 0),
                                  ),
                              _color(si),
                            ),
                        ],
                        color: Colors.transparent,
                      ),
                    ]
                  : [
                      for (var si = 0; si < series.length; si++)
                        BarChartRodData(
                          toY: i < series[si].data.length ? (series[si].data[i] ?? 0) : 0,
                          width: 8,
                          color: _color(si),
                          borderRadius: BorderRadius.circular(3),
                        ),
                    ],
            ),
        ],
      ),
    );
  }

  Widget _pie(List<_Series> series) {
    if (series.isEmpty) {
      return const Center(child: Text('Không có dữ liệu', style: TextStyle(fontSize: 12)));
    }
    final values = <double>[];
    final names = <String>[];
    for (final s in series) {
      final sum = s.data.whereType<double>().fold<double>(0, (a, b) => a + b);
      if (sum > 0) {
        values.add(sum);
        names.add(s.name);
      }
    }
    if (values.isEmpty) {
      return const Center(child: Text('Không có dữ liệu', style: TextStyle(fontSize: 12)));
    }
    final total = values.fold<double>(0, (a, b) => a + b);
    return PieChart(
      PieChartData(
        sectionsSpace: 2,
        centerSpaceRadius: 28,
        sections: [
          for (var i = 0; i < values.length; i++)
            PieChartSectionData(
              value: values[i],
              color: _color(i),
              radius: 48,
              title: '${(values[i] / total * 100).round()}%',
              titleStyle: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w700),
            ),
        ],
      ),
    );
  }

  Widget _heatmap(List<String> labels, List<_Series> series) {
    final data = series.isNotEmpty ? series.first.data : <double?>[];
    if (data.isEmpty) {
      return const Center(child: Text('Không có dữ liệu', style: TextStyle(fontSize: 12)));
    }
    final maxV = data.whereType<double>().fold<double>(1, math.max);
    return GridView.builder(
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 7,
        mainAxisSpacing: 3,
        crossAxisSpacing: 3,
      ),
      itemCount: data.length.clamp(0, 56),
      itemBuilder: (context, i) {
        final v = data[i] ?? 0;
        final t = (v / maxV).clamp(0.0, 1.0);
        return Container(
          decoration: BoxDecoration(
            color: AppColors.primaryGreen.withValues(alpha: 0.12 + t * 0.75),
            borderRadius: BorderRadius.circular(3),
          ),
        );
      },
    );
  }

  Color _color(int i) {
    const colors = [
      AppColors.primaryGreen,
      Color(0xFF3B82F6),
      Color(0xFFF59E0B),
      Color(0xFFEF4444),
      Color(0xFF8B5CF6),
    ];
    return colors[i % colors.length];
  }
}

class _Series {
  _Series({required this.name, required this.data, this.dashed = false});
  final String name;
  final List<double?> data;
  final bool dashed;
}

class CynPremiumUpsellCard extends StatelessWidget {
  const CynPremiumUpsellCard({
    super.key,
    required this.payload,
    this.onUpgrade,
  });

  final Map<String, dynamic> payload;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final title = (payload['title'] ?? 'Nâng Premium').toString();
    final body = (payload['body'] ?? '').toString();
    final cta = (payload['cta'] ?? 'Nâng cấp Premium').toString();
    final feature = (payload['feature'] ?? '').toString();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.primaryGreen.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          if (feature.isNotEmpty) ...[
            const SizedBox(height: 2),
            Text(feature, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          ],
          if (body.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(body, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: onUpgrade,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: Text(cta),
            ),
          ),
        ],
      ),
    );
  }
}

class CynWeeklyReportCard extends StatelessWidget {
  const CynWeeklyReportCard({super.key, required this.payload});

  final Map<String, dynamic> payload;

  @override
  Widget build(BuildContext context) {
    final data = payload['data'];
    final map = data is Map ? Map<String, dynamic>.from(data) : payload;
    final summary = (map['summary'] ?? map['headline'] ?? map.toString()).toString();
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Báo cáo tuần',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            summary.length > 400 ? '${summary.substring(0, 400)}…' : summary,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
          ),
        ],
      ),
    );
  }
}
