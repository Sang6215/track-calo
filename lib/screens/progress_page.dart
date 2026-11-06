import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class ProgressPage extends StatelessWidget {
  const ProgressPage({super.key, required this.store});

  final AppStore store;

  Future<void> _addWeight(BuildContext context) async {
    final latest = store.latestWeight?.kg ?? store.profile?.weightKg ?? 60;
    final controller = TextEditingController(text: fmtKg(latest));
    final result = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ghi cân nặng'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              longDate(DateTime.now()),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
              ],
              style: numberStyle(24),
              decoration: const InputDecoration(suffixText: 'kg'),
              onSubmitted: (value) {
                final kg = double.tryParse(value.replaceAll(',', '.'));
                if (kg != null && kg >= 30 && kg <= 300) {
                  Navigator.pop(context, kg);
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () {
              final kg = double.tryParse(controller.text.replaceAll(',', '.'));
              if (kg != null && kg >= 30 && kg <= 300) {
                Navigator.pop(context, kg);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (result == null) return;
    await store.addWeight(store.todayKey, result);
    if (context.mounted) {
      HapticFeedback.lightImpact();
      showBuaSnack(context, 'Đã ghi ${fmtKg(result)} kg');
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final profile = store.profile;
        if (profile == null) return const SizedBox.shrink();
        final targets = profile.targets;
        final latest = store.latestWeight;
        final delta = store.weightDelta;
        final averageKcal = store.averageKcalLastSeven;
        final averageProtein = store.averageProteinLastSeven;
        final days = store.lastSevenDays;
        final hasWeekData = days.any((d) => d.totals.kcal > 0);

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              BuaScreenHeader(
                eyebrow: 'Tiến độ',
                title: 'Nhìn lại\nđể đi tiếp.',
                subtitle: 'Cân nặng, calo và những ngày bạn đã ghi.',
                trailing: BuaIconButton(
                  icon: Icons.monitor_weight_rounded,
                  tooltip: 'Ghi cân nặng',
                  onPressed: () => _addWeight(context),
                ),
              ),
              const SizedBox(height: 16),
              _weightCard(context, profile, latest, delta),
              const SizedBox(height: 10),
              _calorieCard(context, days, targets, averageKcal, hasWeekData),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: BuaStatTile(
                      label: 'Chuỗi ngày',
                      value: '${store.streak}',
                      unit: 'ngày',
                      color: BuaColors.leaf,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: BuaStatTile(
                      label: 'Ngày đã ghi',
                      value: '${store.loggedDayCount}',
                      unit: 'ngày',
                    ),
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: BuaStatTile(
                      label: 'Đạm TB',
                      value: averageProtein == null
                          ? '—'
                          : fmtGram(averageProtein),
                      unit: averageProtein == null ? null : 'g',
                      color: BuaColors.tomato,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (averageProtein != null &&
                  averageProtein < targets.proteinG * 0.8)
                _insight(
                  context,
                  icon: Icons.eco_rounded,
                  title: 'Đạm đang hơi thấp',
                  message:
                      'Trung bình ${fmtGram(averageProtein)} g/ngày, dưới mục tiêu ${fmtGram(targets.proteinG)} g. Thêm một phần ức gà hoặc trứng vào bữa sáng là đủ.',
                  color: BuaColors.limeSoft,
                  border: const Color(0xFFDFEBA9),
                ),
              if (delta != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _insight(
                    context,
                    icon: delta <= 0
                        ? Icons.trending_down_rounded
                        : Icons.trending_up_rounded,
                    title: delta.abs() < 0.05
                        ? 'Cân nặng ổn định'
                        : '${delta < 0 ? 'Giảm' : 'Tăng'} ${fmtKg(delta.abs())} kg',
                    message: delta.abs() < 0.05
                        ? 'Hai lần ghi gần nhất không đổi. Duy trì đều là tốt.'
                        : 'So với lần ghi trước. Xu hướng quan trọng hơn con số của một ngày.',
                    color: BuaColors.paper,
                    border: BuaColors.line,
                  ),
                ),
              if (!hasWeekData)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _insight(
                    context,
                    icon: Icons.insights_rounded,
                    title: 'Chưa đủ dữ liệu',
                    message:
                        'Ghi vài ngày để Track Calo thấy được nhịp ăn của bạn và đưa ra gợi ý sát hơn.',
                    color: BuaColors.paper,
                    border: BuaColors.line,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _weightCard(
    BuildContext context,
    Profile profile,
    WeightEntry? latest,
    double? delta,
  ) {
    final allEntries = store.weightSeries;
    final entries = allEntries.length > 30
        ? allEntries.sublist(allEntries.length - 30)
        : allEntries;
    final target = profile.targetWeightKg;
    final start = allEntries.isNotEmpty
        ? allEntries.first.kg
        : profile.weightKg;
    final current = latest?.kg ?? profile.weightKg;

    return PaperCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CÂN NẶNG',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 8,
                        letterSpacing: 1.1,
                        color: BuaColors.muted2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          fmtKg(current),
                          style: serifStyle(34, letterSpacing: -1),
                        ),
                        const Padding(
                          padding: EdgeInsets.only(bottom: 4, left: 3),
                          child: Text(
                            'kg',
                            style: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: BuaColors.muted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (delta != null)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: BuaColors.limeSoft,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '${delta > 0 ? '+' : '−'}${fmtKg(delta.abs())} kg',
                    style: numberStyle(
                      10,
                      color: BuaColors.leaf,
                      weight: FontWeight.w700,
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              TextButton(
                onPressed: () => _addWeight(context),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 34),
                ),
                child: const Text('Ghi'),
              ),
            ],
          ),
          if (target != null) ...[
            const SizedBox(height: 5),
            Row(
              children: [
                Text(
                  '${fmtKg(start)} → ${fmtKg(target)} kg',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 9.5),
                ),
                const Spacer(),
                Text(
                  '${((start - current) / (start - target) * 100).clamp(0, 100).round()}%',
                  style: numberStyle(9.5, color: BuaColors.leaf),
                ),
              ],
            ),
            const SizedBox(height: 5),
            LayoutBuilder(
              builder: (context, constraints) {
                final progress = start == target
                    ? 1.0
                    : ((start - current) / (start - target)).clamp(0.0, 1.0);
                return Stack(
                  children: [
                    Container(
                      height: 5,
                      decoration: BoxDecoration(
                        color: BuaColors.lineSoft,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    Container(
                      height: 5,
                      width: constraints.maxWidth * progress,
                      decoration: BoxDecoration(
                        color: BuaColors.lime,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
          const SizedBox(height: 8),
          if (entries.isEmpty)
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: BuaColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.show_chart_rounded,
                      color: BuaColors.muted2,
                      size: 22,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Ghi cân nặng để thấy xu hướng',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            )
          else if (entries.length == 1)
            Container(
              height: 100,
              decoration: BoxDecoration(
                color: BuaColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: BuaColors.lime,
                        shape: BoxShape.circle,
                        border: Border.all(color: BuaColors.leaf, width: 2),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Mốc đầu tiên · ghi thêm để thấy xu hướng',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            )
          else
            SizedBox(
              height: 108,
              child: CustomPaint(
                painter: _WeightChartPainter(entries),
                child: const SizedBox.expand(),
              ),
            ),
          if (entries.length >= 2) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Text(
                  shortDate(dateFromKey(entries.first.date)),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 8),
                ),
                const Spacer(),
                Text(
                  shortDate(dateFromKey(entries.last.date)),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 8),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _calorieCard(
    BuildContext context,
    List<DaySummary> days,
    NutritionTargets targets,
    double? averageKcal,
    bool hasData,
  ) {
    return PaperCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'CALO 7 NGÀY',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 8,
                  letterSpacing: 1.1,
                  color: BuaColors.muted2,
                ),
              ),
              const Spacer(),
              if (averageKcal != null)
                Text(
                  'TB ${fmtKcal(averageKcal)} kcal',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 9,
                    color: BuaColors.leaf,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          if (!hasData)
            Container(
              height: 92,
              decoration: BoxDecoration(
                color: BuaColors.cream,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Center(
                child: Text(
                  'Chưa có bữa nào trong 7 ngày',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ),
            )
          else
            _WeeklyBars(days: days, target: targets.kcal),
          const SizedBox(height: 7),
          Row(
            children: [
              _legendDot(BuaColors.leaf, 'Trong mục tiêu'),
              const SizedBox(width: 10),
              _legendDot(BuaColors.tomato, 'Vượt'),
              const SizedBox(width: 10),
              _legendDot(BuaColors.lime, 'Hôm nay'),
              const Spacer(),
              Text(
                'Mục tiêu ${fmtKcal(targets.kcal)}',
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontSize: 8.5),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 3),
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 7.5,
            color: BuaColors.muted,
          ),
        ),
      ],
    );
  }

  Widget _insight(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String message,
    required Color color,
    required Color border,
  }) {
    return Container(
      padding: const EdgeInsets.fromLTRB(11, 10, 11, 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
              color: BuaColors.ink.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 15, color: BuaColors.ink),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: BuaColors.ink,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 9.5,
                    height: 1.45,
                    color: Color(0xFF40502F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeeklyBars extends StatelessWidget {
  const _WeeklyBars({required this.days, required this.target});

  final List<DaySummary> days;
  final double target;

  @override
  Widget build(BuildContext context) {
    final maxKcal = days.fold<double>(
      0,
      (max, d) => math.max(max, d.totals.kcal),
    );
    final maxY = math.max(math.max(maxKcal, target) * 1.18, 1.0);
    final todayKey = dateKey(DateTime.now());

    return SizedBox(
      height: 112,
      child: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final height = constraints.maxHeight;
                final targetY = height * (1 - target / maxY);
                return Stack(
                  children: [
                    Positioned(
                      left: 0,
                      right: 0,
                      top: targetY,
                      child: CustomPaint(
                        painter: _DashedLinePainter(color: BuaColors.muted2),
                        child: const SizedBox(
                          height: 1,
                          width: double.infinity,
                        ),
                      ),
                    ),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        for (final day in days)
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 4,
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: Container(
                                  height: day.totals.kcal <= 0
                                      ? 2
                                      : math.max(
                                          4.0,
                                          height * day.totals.kcal / maxY,
                                        ),
                                  decoration: BoxDecoration(
                                    color: day.totals.kcal <= 0
                                        ? BuaColors.line
                                        : day.key == todayKey
                                        ? BuaColors.lime
                                        : day.totals.kcal > target
                                        ? BuaColors.tomato
                                        : BuaColors.leaf,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(6),
                                      bottom: Radius.circular(3),
                                    ),
                                    border: day.key == todayKey
                                        ? Border.all(
                                            color: const Color(0xFFC9E25C),
                                          )
                                        : null,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              for (final day in days)
                Expanded(
                  child: Text(
                    weekdayShort(day.date),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 8,
                      fontWeight: day.key == todayKey
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: day.key == todayKey
                          ? BuaColors.ink
                          : BuaColors.muted2,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  const _DashedLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.5)
      ..strokeWidth = 1;
    const dash = 4.0;
    const gap = 4.0;
    var x = 0.0;
    while (x < size.width) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(math.min(x + dash, size.width), 0),
        paint,
      );
      x += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter old) => old.color != color;
}

class _WeightChartPainter extends CustomPainter {
  const _WeightChartPainter(this.entries);

  final List<WeightEntry> entries;

  @override
  void paint(Canvas canvas, Size size) {
    if (entries.isEmpty) return;
    final values = entries.map((e) => e.kg).toList();
    var min = values.reduce((a, b) => a < b ? a : b);
    var max = values.reduce((a, b) => a > b ? a : b);
    if ((max - min).abs() < 0.6) {
      min -= 0.4;
      max += 0.4;
    }
    final range = math.max(max - min, 0.8);
    const pad = 8.0;
    final width = size.width - pad * 2;
    final height = size.height - pad * 2;

    Offset point(int index) {
      final x = entries.length == 1
          ? pad + width / 2
          : pad + width * index / (entries.length - 1);
      final y = pad + height * (1 - (values[index] - min) / range);
      return Offset(x, y);
    }

    final path = Path();
    final fill = Path();
    for (var i = 0; i < entries.length; i++) {
      final p = point(i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
        fill.moveTo(p.dx, size.height - pad);
        fill.lineTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
        fill.lineTo(p.dx, p.dy);
      }
    }
    if (entries.length > 1) {
      fill.lineTo(point(entries.length - 1).dx, size.height - pad);
      fill.close();
    }

    if (entries.length > 1) {
      canvas.drawPath(
        fill,
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              BuaColors.leaf.withValues(alpha: 0.20),
              BuaColors.leaf.withValues(alpha: 0),
            ],
          ).createShader(Rect.fromLTWH(0, 0, size.width, size.height)),
      );
    }

    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..color = BuaColors.leaf,
    );

    for (final index in entries.length > 1 ? [entries.length - 1] : [0]) {
      final p = point(index);
      canvas.drawCircle(p, 4.5, Paint()..color = BuaColors.lime);
      canvas.drawCircle(
        p,
        4.5,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2
          ..color = BuaColors.leaf,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _WeightChartPainter old) =>
      old.entries.length != entries.length ||
      (old.entries.isNotEmpty &&
          entries.isNotEmpty &&
          old.entries.last.kg != entries.last.kg);
}
