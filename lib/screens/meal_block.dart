import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class MealBlock extends StatelessWidget {
  const MealBlock({
    super.key,
    required this.store,
    required this.date,
    required this.meal,
    required this.entries,
    required this.onAdd,
    required this.onEdit,
    this.onSaveCombo,
  });

  final AppStore store;
  final String date;
  final MealType meal;
  final List<LogEntry> entries;
  final VoidCallback onAdd;
  final ValueChanged<LogEntry> onEdit;
  final VoidCallback? onSaveCombo;

  @override
  Widget build(BuildContext context) {
    final kcal = entries.fold<double>(0, (sum, e) => sum + e.kcal);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Row(
            children: [
              Text(
                meal.labelLong,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 14,
                  letterSpacing: -0.1,
                ),
              ),
              const SizedBox(width: 7),
              if (entries.isNotEmpty)
                Text(
                  '${fmtKcal(kcal)} kcal',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10.5,
                    color: BuaColors.muted2,
                  ),
                ),
              const Spacer(),
              if (entries.isNotEmpty && onSaveCombo != null)
                IconButton(
                  onPressed: onSaveCombo,
                  tooltip: 'Lưu thành bữa quen',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(
                    Icons.bookmark_add_outlined,
                    size: 20,
                    color: BuaColors.leaf,
                  ),
                ),
              IconButton(
                onPressed: onAdd,
                tooltip: 'Thêm món',
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.add_circle_outline_rounded,
                  size: 22,
                  color: BuaColors.ink,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 5),
        if (entries.isEmpty)
          _empty(context)
        else
          PaperCard(
            padding: EdgeInsets.zero,
            radius: 18,
            child: Column(
              children: [
                for (var i = 0; i < entries.length; i++) ...[
                  _row(context, entries[i]),
                  if (i != entries.length - 1)
                    const Divider(height: 1, indent: 58, endIndent: 12),
                ],
              ],
            ),
          ),
      ],
    );
  }

  Widget _empty(BuildContext context) {
    return Material(
      color: BuaColors.paper.withValues(alpha: 0.55),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: BuaColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onAdd,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: const BoxDecoration(
                  color: BuaColors.limeSoft,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.add_rounded,
                  size: 18,
                  color: BuaColors.ink,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Thêm món cho ${meal.labelLong.toLowerCase()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11.5,
                  color: BuaColors.muted,
                ),
              ),
              const Spacer(),
              const Icon(
                Icons.chevron_right_rounded,
                size: 18,
                color: BuaColors.muted2,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _row(BuildContext context, LogEntry entry) {
    final food = store.foodById(entry.foodId);
    final thumb = food != null
        ? FoodThumb(food: food, size: 40)
        : Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: BuaColors.lineSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.restaurant_rounded,
              size: 20,
              color: BuaColors.muted2,
            ),
          );

    return Dismissible(
      key: ValueKey(entry.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        padding: const EdgeInsets.only(right: 18),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: BuaColors.tomato,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      onDismissed: (_) async {
        HapticFeedback.mediumImpact();
        final removed = await store.removeEntry(entry.id);
        if (removed == null || !context.mounted) return;
        showBuaSnack(
          context,
          'Đã xóa ${entry.name}',
          action: SnackBarAction(
            label: 'Hoàn tác',
            onPressed: () => store.restoreEntry(removed),
          ),
        );
      },
      child: InkWell(
        onTap: () => onEdit(entry),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(10, 9, 12, 9),
          child: Row(
            children: [
              thumb,
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontSize: 13,
                        letterSpacing: -0.1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${fmtGram(entry.grams)} g · '
                      '${fmtGram(entry.protein)} đạm · '
                      '${fmtGram(entry.carb)} carb · '
                      '${fmtGram(entry.fat)} béo',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 9.5,
                        color: BuaColors.muted2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    fmtKcal(entry.kcal),
                    style: numberStyle(15.5, weight: FontWeight.w600),
                  ),
                  const Text(
                    'kcal',
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 7.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                      color: BuaColors.muted2,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
