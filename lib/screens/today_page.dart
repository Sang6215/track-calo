import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'add_food_page.dart';
import 'meal_block.dart';

class TodayPage extends StatelessWidget {
  const TodayPage({
    super.key,
    required this.store,
    required this.onAdd,
    required this.onOpenDiary,
    required this.onOpenSettings,
  });

  final AppStore store;
  final ValueChanged<MealType> onAdd;
  final VoidCallback onOpenDiary;
  final VoidCallback onOpenSettings;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final profile = store.profile;
        if (profile == null) return const SizedBox.shrink();
        final now = DateTime.now();
        final totals = store.totalsFor(store.todayKey);
        final targets = profile.targets;
        final waterCups = store.waterFor(store.todayKey);

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 28),
            children: [
              BuaScreenHeader(
                eyebrow: '${weekdayName(now)} · ${shortDate(now)}',
                title: profile.name.trim().isEmpty
                    ? 'Hôm nay ăn gì?'
                    : 'Chào ${profile.name.trim()},',
                subtitle:
                    '${greetingForNow()} · Mục tiêu ${fmtKcal(targets.kcal)} kcal',
                trailing: GestureDetector(
                  onTap: onOpenSettings,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: BuaColors.ink,
                      shape: BoxShape.circle,
                      border: Border.all(color: BuaColors.paper, width: 2),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      _initials(profile.name),
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: BuaColors.lime,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _hero(context, totals, targets, store.streak),
              const SizedBox(height: 10),
              _water(context, waterCups, store.waterGoalCups),
              if (store.combos.isNotEmpty) ...[
                const SizedBox(height: 18),
                BuaSectionHeader(title: 'Bữa quen'),
                const SizedBox(height: 7),
                SizedBox(
                  height: 100,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: store.combos.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 8),
                    itemBuilder: (context, index) =>
                        _comboCard(context, store.combos[index]),
                  ),
                ),
              ],
              const SizedBox(height: 18),
              BuaSectionHeader(
                title: 'Bữa hôm nay',
                action: 'Nhật ký',
                onAction: onOpenDiary,
              ),
              for (final meal in MealType.values)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: MealBlock(
                    store: store,
                    date: store.todayKey,
                    meal: meal,
                    entries: store.entriesForMeal(store.todayKey, meal),
                    onAdd: () => onAdd(meal),
                    onEdit: (entry) =>
                        editEntryPortion(context, store: store, entry: entry),
                    onSaveCombo:
                        store.entriesForMeal(store.todayKey, meal).isEmpty
                        ? null
                        : () => _saveCombo(
                            context,
                            meal,
                            store.entriesForMeal(store.todayKey, meal),
                          ),
                  ),
                ),
              const SizedBox(height: 16),
              _insight(context, totals, targets),
              if (store.combos.isEmpty && store.logs.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  'Mẹo: bấm biểu tượng bookmark ở một bữa đã ghi để lưu thành “Bữa quen” cho lần sau.',
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 9.5),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((e) => e.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'B';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }

  Widget _hero(
    BuildContext context,
    DayTotals totals,
    NutritionTargets targets,
    int streak,
  ) {
    final over = totals.kcal > targets.kcal;
    final remaining = (targets.kcal - totals.kcal).abs();
    final progress = targets.kcal <= 0 ? 0.0 : totals.kcal / targets.kcal;
    final percent = (progress * 100).round();

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E5138), Color(0xFF12372A), Color(0xFF0F2E23)],
        ),
      ),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Stack(
        children: [
          Positioned(
            right: -60,
            bottom: -80,
            child: Container(
              width: 190,
              height: 190,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    BuaColors.lime.withValues(alpha: 0.18),
                    BuaColors.lime.withValues(alpha: 0),
                  ],
                ),
              ),
            ),
          ),
          Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Ngân sách calo hôm nay',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFC7DCCB),
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: BuaColors.lime.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(
                        color: BuaColors.lime.withValues(alpha: 0.25),
                      ),
                    ),
                    child: Text(
                      over ? 'Vượt $percent%' : 'Đã dùng $percent%',
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: BuaColors.lime,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  CalorieRing(
                    progress: progress,
                    size: 128,
                    stroke: 11,
                    color: over ? BuaColors.over : BuaColors.lime,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          fmtKcal(remaining),
                          style: serifStyle(
                            36,
                            color: over ? BuaColors.over : BuaColors.lime,
                            letterSpacing: -1.2,
                          ),
                        ),
                        Text(
                          over ? 'kcal vượt' : 'kcal còn lại',
                          style: const TextStyle(
                            fontFamily: 'BeVietnamPro',
                            fontSize: 8.5,
                            color: Color(0xFFBFD6C4),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      children: [
                        MacroBar(
                          label: 'Đạm',
                          value: totals.protein,
                          target: targets.proteinG,
                          color: BuaColors.lime,
                          dark: true,
                        ),
                        const SizedBox(height: 9),
                        MacroBar(
                          label: 'Tinh bột',
                          value: totals.carb,
                          target: targets.carbG,
                          color: const Color(0xFFF2C14E),
                          dark: true,
                        ),
                        const SizedBox(height: 9),
                        MacroBar(
                          label: 'Chất béo',
                          value: totals.fat,
                          target: targets.fatG,
                          color: const Color(0xFFF08A6A),
                          dark: true,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.only(top: 9),
                decoration: BoxDecoration(
                  border: Border(
                    top: BorderSide(
                      color: Colors.white.withValues(alpha: 0.12),
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text.rich(
                        TextSpan(
                          children: [
                            const TextSpan(text: 'Đã nạp '),
                            TextSpan(
                              text: fmtKcal(totals.kcal),
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                                color: BuaColors.paper,
                              ),
                            ),
                            TextSpan(text: ' / ${fmtKcal(targets.kcal)} kcal'),
                          ],
                        ),
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 8.5,
                          color: Color(0xFFBFD6C4),
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.local_fire_department_rounded,
                      size: 14,
                      color: BuaColors.lime,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$streak ngày',
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 8.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFBFD6C4),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _water(BuildContext context, int cups, int goal) {
    final liters = cups * 0.25;
    final goalLiters = goal * 0.25;
    final drops = math.min(goal, 10);
    return PaperCard(
      radius: 16,
      padding: const EdgeInsets.fromLTRB(11, 9, 8, 9),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: const BoxDecoration(
              color: BuaColors.waterSoft,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.water_drop_rounded,
              size: 16,
              color: BuaColors.water,
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nước',
                  style: TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: BuaColors.ink,
                  ),
                ),
                const SizedBox(height: 1),
                Text(
                  '${fmtNum(liters, decimals: 1)} / ${fmtNum(goalLiters, decimals: 1)} L · còn ${math.max(0, goal - cups)} ly',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 9),
                ),
              ],
            ),
          ),
          if (goal <= 10)
            Row(
              children: List.generate(drops, (index) {
                final filled = index < cups;
                return GestureDetector(
                  onTap: () => store.setWater(
                    store.todayKey,
                    index + 1 == cups ? index : index + 1,
                  ),
                  child: Container(
                    width: 6,
                    height: 13,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      color: filled ? BuaColors.water : BuaColors.lineSoft,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                );
              }),
            )
          else
            SizedBox(
              width: 84,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: goal == 0 ? 0 : (cups / goal).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: BuaColors.lineSoft,
                  valueColor: const AlwaysStoppedAnimation(BuaColors.water),
                ),
              ),
            ),
          const SizedBox(width: 4),
          BuaIconButton(
            icon: Icons.add_rounded,
            size: 44,
            tooltip: 'Thêm 1 ly',
            onPressed: cups >= goal
                ? null
                : () => store.setWater(store.todayKey, cups + 1),
          ),
        ],
      ),
    );
  }

  Widget _comboCard(BuildContext context, Combo combo) {
    final totals = store.comboFoodTotals(combo);
    return SizedBox(
      width: 176,
      child: GestureDetector(
        onLongPress: () => _deleteCombo(context, combo),
        child: PaperCard(
          onTap: () => _applyCombo(context, combo),
          radius: 16,
          padding: const EdgeInsets.fromLTRB(11, 9, 11, 9),
          color: BuaColors.ink,
          borderColor: BuaColors.ink,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.bookmark_rounded,
                    size: 15,
                    color: BuaColors.lime,
                  ),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      combo.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: BuaColors.paper,
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                '${fmtKcal(totals.kcal)} kcal',
                style: numberStyle(
                  17,
                  color: BuaColors.lime,
                  weight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: [
                  Text(
                    '${combo.items.length} món · ${combo.meal.label}',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 8,
                      color: Color(0xFFBFD6C4),
                    ),
                  ),
                  const Spacer(),
                  const Icon(
                    Icons.add_circle_rounded,
                    size: 16,
                    color: BuaColors.lime,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _applyCombo(BuildContext context, Combo combo) async {
    final count = await store.applyCombo(combo, store.todayKey);
    if (!context.mounted) return;
    if (count == 0) {
      showBuaSnack(context, 'Bữa quen này không còn món khả dụng.');
      return;
    }
    HapticFeedback.mediumImpact();
    showBuaSnack(context, 'Đã thêm “${combo.name}” · $count món');
  }

  Future<void> _deleteCombo(BuildContext context, Combo combo) async {
    final ok = await confirmAction(
      context,
      title: 'Xóa bữa quen?',
      message:
          '“${combo.name}” sẽ bị xóa khỏi danh sách. Các bữa đã ghi vẫn được giữ.',
    );
    if (ok) await store.deleteCombo(combo.id);
  }

  Future<void> _saveCombo(
    BuildContext context,
    MealType meal,
    List<LogEntry> entries,
  ) async {
    final controller = TextEditingController(text: '${meal.label} của tôi');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lưu bữa quen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            labelText: 'Tên bữa',
            hintText: 'Sáng của tôi',
          ),
          onSubmitted: (value) => Navigator.pop(context, value),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (name == null || name.trim().isEmpty || !context.mounted) return;
    await store.saveComboFromEntries(name: name, meal: meal, entries: entries);
    if (!context.mounted) return;
    showBuaSnack(context, 'Đã lưu “${name.trim()}” vào Bữa quen');
  }

  Widget _insight(
    BuildContext context,
    DayTotals totals,
    NutritionTargets targets,
  ) {
    final over = totals.kcal - targets.kcal;
    final proteinLeft = targets.proteinG - totals.protein;
    final kcalLeft = targets.kcal - totals.kcal;

    late final IconData icon;
    late final Color bg;
    late final Color border;
    late final InlineSpan message;

    if (totals.kcal == 0) {
      icon = Icons.wb_sunny_rounded;
      bg = BuaColors.limeSoft;
      border = const Color(0xFFDFEBA9);
      message = const TextSpan(
        text: 'Bắt đầu bằng bữa sáng — chỉ mất khoảng 10 giây để ghi lại.',
      );
    } else if (over > 0) {
      icon = Icons.trending_up_rounded;
      bg = BuaColors.tomatoSoft;
      border = const Color(0xFFF3C8B4);
      message = TextSpan(
        children: [
          const TextSpan(text: 'Hôm nay vượt '),
          TextSpan(
            text: '${fmtKcal(over)} kcal',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: '. Bữa tối nhẹ với rau và cá là vừa.'),
        ],
      );
    } else if (proteinLeft >= 20) {
      icon = Icons.eco_rounded;
      bg = BuaColors.limeSoft;
      border = const Color(0xFFDFEBA9);
      message = TextSpan(
        children: [
          const TextSpan(text: 'Còn thiếu '),
          TextSpan(
            text: '${fmtGram(proteinLeft)} g đạm',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: ' — thêm ức gà 150 g hoặc một hộp sữa chua.'),
        ],
      );
    } else if (kcalLeft < 250) {
      icon = Icons.flag_rounded;
      bg = BuaColors.limeSoft;
      border = const Color(0xFFDFEBA9);
      message = TextSpan(
        children: [
          const TextSpan(text: 'Sắp đạt mục tiêu — còn '),
          TextSpan(
            text: '${fmtKcal(kcalLeft)} kcal',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: '.'),
        ],
      );
    } else {
      icon = Icons.bolt_rounded;
      bg = BuaColors.limeSoft;
      border = const Color(0xFFDFEBA9);
      message = TextSpan(
        children: [
          const TextSpan(text: 'Còn '),
          TextSpan(
            text: '${fmtKcal(kcalLeft)} kcal',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const TextSpan(text: '. Một bữa nhẹ với rau và đạm là vừa.'),
        ],
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
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
            child: Text.rich(
              message,
              style: const TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 10,
                height: 1.45,
                color: Color(0xFF40502F),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
