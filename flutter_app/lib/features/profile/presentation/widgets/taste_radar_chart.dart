import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../../../../core/config/theme/app_colors.dart';

class TasteRadarChart extends StatelessWidget {
  final Map<String, double> genreDistribution;

  const TasteRadarChart({super.key, required this.genreDistribution});

  @override
  Widget build(BuildContext context) {
    if (genreDistribution.isEmpty) {
      return Container(
        height: 200,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surfaceDark,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Center(
          child: Text('평점 데이터가 쌓이면 취향 분석이 시작돼요',
              style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 13)),
        ),
      );
    }

    // 상위 8개 장르만 표시
    final sorted = genreDistribution.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(math.min(8, sorted.length)).toList();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surfaceDark,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('취향 분석', style: TextStyle(
              color: AppColors.textPrimaryDark,
              fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          SizedBox(
            height: 240,
            child: RadarChart(
              RadarChartData(
                radarShape: RadarShape.polygon,
                radarBorderData: const BorderSide(color: AppColors.dividerDark, width: 0.5),
                gridBorderData: const BorderSide(color: AppColors.dividerDark, width: 0.5),
                tickBorderData: const BorderSide(color: Colors.transparent),
                tickCount: 3,
                ticksTextStyle: const TextStyle(fontSize: 0),
                titleTextStyle: const TextStyle(
                    color: AppColors.textSecondaryDark, fontSize: 11),
                getTitle: (index, _) {
                  if (index >= top.length) return RadarChartTitle(text: '');
                  return RadarChartTitle(text: _genreLabel(top[index].key));
                },
                dataSets: [
                  RadarDataSet(
                    dataEntries: top.map((e) =>
                        RadarEntry(value: (e.value * 100).clamp(0, 100))).toList(),
                    fillColor: AppColors.primary.withValues(alpha: 0.2),
                    borderColor: AppColors.primary,
                    borderWidth: 2,
                    entryRadius: 3,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _genreLabel(String id) => switch (id) {
    'action'      => '액션',
    'adventure'   => '모험',
    'animation'   => '애니',
    'comedy'      => '코미디',
    'crime'       => '범죄',
    'documentary' => '다큐',
    'drama'       => '드라마',
    'family'      => '가족',
    'fantasy'     => '판타지',
    'history'     => '역사',
    'horror'      => '공포',
    'music'       => '음악',
    'mystery'     => '미스터리',
    'romance'     => '로맨스',
    'sf'          => 'SF',
    'thriller'    => '스릴러',
    'war'         => '전쟁',
    _             => id,
  };
}
