import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'add_food_page.dart';
import 'meal_block.dart';

class DiaryPage extends StatefulWidget {
  const DiaryPage({super.key, required this.store, required this.onAdd});

  final AppStore store;
  final void Function(String date, MealType meal) onAdd;

  @override
  State<DiaryPage> createState() => _DiaryPageState();
}

class _DiaryPageState extends State<DiaryPage> {
  DateTime _selected = dateOnly(DateTime.now());

  String get _key => dateKey(_selected);

  DateTime get _firstAllowedDate {
    final floor = dateOnly(DateTime.now()).subtract(const Duration(days: 89));
    if (widget.store.logs.isEmpty) return floor;
    final earliest = dateFromKey(widget.store.logs.first.date);
    return earliest.isBefore(floor) ? earliest : floor;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selected,
      firstDate: _firstAllowedDate,
      lastDate: dateOnly(DateTime.now()),
      helpText: 'Chọn ngày',
      cancelText: 'Hủy',
      confirmText: 'Chọn',
    );
    if (picked != null) setState(() => _selected = dateOnly(picked));
  }

  Future<void> _copyYesterday() async {
    final previous = _selected.subtract(const Duration(days: 1));
    final source = widget.store.entriesFor(dateKey(previous));
    if (source.isEmpty) {
      showBuaSnack(context, 'Hôm qua chưa có món nào để sao chép.');
      return;
    }
    final current = widget.store.entriesFor(_key);
    if (current.isNotEmpty) {
      final ok = await confirmAction(
        context,
        title: 'Thay thế ngày này?',
        message:
            'Ngày ${shortDate(_selected)} đã có ${current.length} món. Sao chép hôm qua sẽ thay thế toàn bộ.',
        confirmLabel: 'Thay thế',
        destructive: false,
      );
      if (!ok) return;
    }
    final count = await widget.store.copyDay(from: dateKey(previous), to: _key);
    if (!mounted) return;
    showBuaSnack(context, 'Đã sao chép $count món từ hôm qua.');
  }

  Future<void> _saveCombo(MealType meal, List<LogEntry> entries) async {
    final controller = TextEditingController(text: '${meal.label} của tôi');
    final name = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Lưu bữa quen'),
        content: TextField(
          controller: controller,
          autofocus: true,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(labelText: 'Tên bữa'),
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
    if (name == null || name.trim().isEmpty || !mounted) return;
    await widget.store.saveComboFromEntries(
      name: name,
      meal: meal,
      entries: entries,
    );
    if (!mounted) return;
    showBuaSnack(context, 'Đã lưu “${name.trim()}” vào Bữa quen');
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final profile = widget.store.profile;
        final totals = widget.store.totalsFor(_key);
        final targets = profile?.targets;
        final isToday = _key == widget.store.todayKey;

        return SafeArea(
          bottom: false,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 10, 0),
                child: BuaScreenHeader(
                  eyebrow: 'Nhật ký',
                  title: isToday ? 'Hôm nay' : friendlyDay(_selected),
                  subtitle: longDate(_selected),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (!isToday)
                        TextButton(
                          onPressed: () => setState(
                            () => _selected = dateOnly(DateTime.now()),
                          ),
                          child: const Text('Hôm nay'),
                        ),
                      const SizedBox(width: 4),
                      BuaIconButton(
                        icon: Icons.calendar_month_rounded,
                        tooltip: 'Chọn ngày',
                        onPressed: _pickDate,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              BuaDateStrip(
                selected: _selected,
                days:
                    dateOnly(
                      DateTime.now(),
                    ).difference(_firstAllowedDate).inDays +
                    1,
                onSelected: (value) => setState(() => _selected = value),
              ),
              const SizedBox(height: 4),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                  children: [
                    _summary(context, totals, targets),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _copyYesterday,
                            icon: const Icon(Icons.copy_all_rounded, size: 18),
                            label: const Text('Sao chép hôm qua'),
                            style: OutlinedButton.styleFrom(
                              minimumSize: const Size.fromHeight(42),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        BuaIconButton(
                          icon: Icons.add_rounded,
                          tooltip: 'Thêm món',
                          onPressed: () => widget.onAdd(_key, mealForNow()),
                        ),
                      ],
                    ),
                    for (final meal in MealType.values)
                      Padding(
                        padding: const EdgeInsets.only(top: 14),
                        child: MealBlock(
                          store: widget.store,
                          date: _key,
                          meal: meal,
                          entries: widget.store.entriesForMeal(_key, meal),
                          onAdd: () => widget.onAdd(_key, meal),
                          onEdit: (entry) => editEntryPortion(
                            context,
                            store: widget.store,
                            entry: entry,
                          ),
                          onSaveCombo:
                              widget.store.entriesForMeal(_key, meal).isEmpty
                              ? null
                              : () => _saveCombo(
                                  meal,
                                  widget.store.entriesForMeal(_key, meal),
                                ),
                        ),
                      ),
                    if (widget.store.entriesFor(_key).isEmpty) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Ngày này chưa có món nào. Ghi một bữa hoặc sao chép từ hôm qua để bắt đầu.',
                        textAlign: TextAlign.center,
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 10),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _summary(
    BuildContext context,
    DayTotals totals,
    NutritionTargets? targets,
  ) {
    final targetKcal = targets?.kcal ?? 0;
    final remaining = targetKcal - totals.kcal;
    return PaperCard(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      child: Column(
        children: [
          Row(
            children: [
              _summaryNumber('Đã nạp', fmtKcal(totals.kcal), 'kcal'),
              const SizedBox(width: 8),
              _summaryNumber('Mục tiêu', fmtKcal(targetKcal), 'kcal'),
              const SizedBox(width: 8),
              _summaryNumber(
                remaining < 0 ? 'Vượt' : 'Còn lại',
                fmtKcal(remaining.abs()),
                'kcal',
                color: remaining < 0 ? BuaColors.tomato : BuaColors.leaf,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: MacroBar(
                  label: 'Đạm',
                  value: totals.protein,
                  target: targets?.proteinG ?? 0,
                  color: BuaColors.tomato,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MacroBar(
                  label: 'Tinh bột',
                  value: totals.carb,
                  target: targets?.carbG ?? 0,
                  color: BuaColors.honey,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: MacroBar(
                  label: 'Béo',
                  value: totals.fat,
                  target: targets?.fatG ?? 0,
                  color: BuaColors.leaf,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryNumber(
    String label,
    String value,
    String unit, {
    Color color = BuaColors.ink,
  }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 7.5,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.8,
              color: BuaColors.muted2,
            ),
          ),
          const SizedBox(height: 3),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: numberStyle(20, color: color, weight: FontWeight.w600),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: BuaColors.muted2,
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
