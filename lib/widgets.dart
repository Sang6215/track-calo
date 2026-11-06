import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'models.dart';
import 'theme.dart';

IconData categoryIcon(String category) => switch (category) {
  'soup' => Icons.ramen_dining_rounded,
  'rice' => Icons.rice_bowl_rounded,
  'bread' => Icons.bakery_dining_rounded,
  'protein' => Icons.set_meal_rounded,
  'veg' => Icons.eco_rounded,
  'fruit' => Icons.local_florist_rounded,
  'drink' => Icons.local_cafe_rounded,
  'snack' => Icons.cookie_rounded,
  'staple' => Icons.grain_rounded,
  _ => Icons.restaurant_rounded,
};

Color categoryColor(String category) => switch (category) {
  'soup' => const Color(0xFF9A5B08),
  'rice' => BuaColors.leaf,
  'bread' => const Color(0xFF8A5A22),
  'protein' => BuaColors.tomato,
  'veg' => const Color(0xFF3F6B3A),
  'fruit' => const Color(0xFF8A6F3C),
  'drink' => BuaColors.water,
  'snack' => BuaColors.honey,
  'staple' => const Color(0xFF6B6136),
  _ => BuaColors.muted,
};

Color categorySoft(String category) => switch (category) {
  'soup' => const Color(0xFFF8E7C4),
  'rice' => const Color(0xFFE3EEDC),
  'bread' => const Color(0xFFF5E6CC),
  'protein' => const Color(0xFFFBE3D6),
  'veg' => const Color(0xFFE4F0E2),
  'fruit' => const Color(0xFFF0EAD8),
  'drink' => BuaColors.waterSoft,
  'snack' => const Color(0xFFF7E8CF),
  'staple' => const Color(0xFFF1EBDD),
  _ => BuaColors.lineSoft,
};

class BuaLogo extends StatelessWidget {
  const BuaLogo({super.key, this.size = 34, this.light = false});

  final double size;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final color = light ? BuaColors.brandYellow : BuaColors.brandBlue;
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        ExcludeSemantics(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.3),
            child: Image.asset(
              'assets/branding/track-calo-icon.png',
              width: size * 1.4,
              height: size * 1.4,
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        SizedBox(width: size * 0.3),
        Text(
          'Track Calo',
          style: serifStyle(
            size,
            color: color,
            letterSpacing: -1.1,
            weight: 560,
          ),
        ),
      ],
    );
  }
}

class BuaIconButton extends StatelessWidget {
  const BuaIconButton({
    super.key,
    required this.icon,
    required this.onPressed,
    this.tooltip,
    this.dark = false,
    this.size = 44,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String? tooltip;
  final bool dark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final child = Material(
      color: dark ? Colors.white.withValues(alpha: 0.08) : BuaColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(13),
        side: BorderSide(
          color: dark ? Colors.white.withValues(alpha: 0.16) : BuaColors.line,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Opacity(
          opacity: onPressed == null ? 0.45 : 1,
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(
              icon,
              size: size * 0.48,
              color: dark ? BuaColors.paper : BuaColors.ink,
            ),
          ),
        ),
      ),
    );
    if (tooltip == null) return child;
    return Tooltip(message: tooltip!, child: child);
  }
}

class BuaScreenHeader extends StatelessWidget {
  const BuaScreenHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: BuaColors.leaf,
                  letterSpacing: 1.6,
                ),
              ),
              const SizedBox(height: 4),
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

class PaperCard extends StatelessWidget {
  const PaperCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color = BuaColors.paper,
    this.borderColor = BuaColors.line,
    this.radius = 20,
    this.onTap,
    this.clip = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color color;
  final Color borderColor;
  final double radius;
  final VoidCallback? onTap;
  final bool clip;

  @override
  Widget build(BuildContext context) {
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radius),
      side: BorderSide(color: borderColor),
    );
    return Material(
      color: color,
      shape: shape,
      clipBehavior: clip || onTap != null ? Clip.antiAlias : Clip.none,
      child: InkWell(
        onTap: onTap,
        customBorder: shape,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class BuaSectionHeader extends StatelessWidget {
  const BuaSectionHeader({
    super.key,
    required this.title,
    this.action,
    this.onAction,
  });

  final String title;
  final String? action;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontSize: 14.5,
                letterSpacing: -0.1,
              ),
            ),
          ),
          if (action != null)
            if (onAction != null)
              TextButton(
                onPressed: onAction,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  minimumSize: const Size(0, 36),
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(action!),
                    const SizedBox(width: 2),
                    const Icon(Icons.chevron_right_rounded, size: 17),
                  ],
                ),
              )
            else
              Padding(
                padding: const EdgeInsets.only(right: 2),
                child: Text(
                  action!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10,
                    color: BuaColors.muted2,
                  ),
                ),
              ),
        ],
      ),
    );
  }
}

class FoodThumb extends StatelessWidget {
  const FoodThumb({super.key, required this.food, this.size = 46});

  final Food food;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: categorySoft(food.category),
        borderRadius: BorderRadius.circular(size * 0.3),
        border: Border.all(
          color: categoryColor(food.category).withValues(alpha: 0.12),
        ),
      ),
      child: Icon(
        categoryIcon(food.category),
        color: categoryColor(food.category),
        size: size * 0.5,
      ),
    );
  }
}

class FoodTile extends StatelessWidget {
  const FoodTile({
    super.key,
    required this.food,
    required this.onTap,
    required this.isFavorite,
    required this.onToggleFavorite,
    this.trailing,
    this.subtitle,
  });

  final Food food;
  final VoidCallback onTap;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;
  final Widget? trailing;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      onTap: onTap,
      padding: const EdgeInsets.fromLTRB(10, 9, 8, 9),
      radius: 17,
      child: Row(
        children: [
          FoodThumb(food: food, size: 44),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  food.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontSize: 13.5,
                    letterSpacing: -0.1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle ??
                      '${food.servingLabel} · ${fmtKcal(food.kcalPerServing)} kcal · '
                          '${fmtGram(food.proteinPerServing)} đạm',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 10.5,
                    color: BuaColors.muted2,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          if (trailing != null)
            trailing!
          else ...[
            IconButton(
              onPressed: onToggleFavorite,
              visualDensity: VisualDensity.compact,
              tooltip: isFavorite ? 'Bỏ yêu thích' : 'Yêu thích',
              icon: Icon(
                isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                size: 21,
                color: isFavorite ? BuaColors.honey : BuaColors.muted2,
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 5),
              decoration: BoxDecoration(
                color: BuaColors.limeSoft,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                fmtKcal(food.kcalPerServing),
                style: numberStyle(
                  12,
                  color: BuaColors.ink,
                  weight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class CalorieRing extends StatelessWidget {
  const CalorieRing({
    super.key,
    required this.progress,
    required this.child,
    this.size = 132,
    this.stroke = 11,
    this.color = BuaColors.lime,
    this.trackColor = const Color(0x22FFFFFF),
  });

  final double progress;
  final Widget child;
  final double size;
  final double stroke;
  final Color color;
  final Color trackColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: progress.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 850),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) => SizedBox(
        width: size,
        height: size,
        child: CustomPaint(
          painter: _RingPainter(
            progress: value,
            color: color,
            trackColor: trackColor,
            stroke: stroke,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  const _RingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
    required this.stroke,
  });

  final double progress;
  final Color color;
  final Color trackColor;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = (size.shortestSide - stroke) / 2;
    final track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);
    if (progress <= 0) return;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      2 * math.pi * progress,
      false,
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant _RingPainter old) =>
      old.progress != progress || old.color != color;
}

class MacroBar extends StatelessWidget {
  const MacroBar({
    super.key,
    required this.label,
    required this.value,
    required this.target,
    required this.color,
    this.dark = false,
    this.height = 5,
    this.unit = 'g',
    this.showNumbers = true,
  });

  final String label;
  final double value;
  final double target;
  final Color color;
  final bool dark;
  final double height;
  final String unit;
  final bool showNumbers;

  @override
  Widget build(BuildContext context) {
    final ratio = target <= 0 ? 0.0 : (value / target).clamp(0.0, 1.0);
    final labelColor = dark ? const Color(0xFFD7E6DA) : BuaColors.muted;
    final numberColor = dark ? BuaColors.paper : BuaColors.ink;
    final trackColor = dark
        ? Colors.white.withValues(alpha: 0.14)
        : BuaColors.lineSoft;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: dark ? 9.5 : 11.5,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
            if (showNumbers)
              Text(
                '${fmtGram(value)} / ${fmtGram(target)} $unit',
                style: numberStyle(
                  dark ? 9.5 : 11,
                  color: numberColor,
                  weight: FontWeight.w700,
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        LayoutBuilder(
          builder: (context, constraints) => TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, animated, _) => Stack(
              children: [
                Container(
                  height: height,
                  decoration: BoxDecoration(
                    color: trackColor,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
                Container(
                  height: height,
                  width: constraints.maxWidth * animated,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(height),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class BuaEmptyState extends StatelessWidget {
  const BuaEmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.ramen_dining_rounded,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: BuaColors.limeSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: BuaColors.ink, size: 28),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            Text(
              message,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: 14),
              TextButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

class BuaBottomBar extends StatelessWidget {
  const BuaBottomBar({
    super.key,
    required this.index,
    required this.onSelect,
    required this.onAdd,
  });

  final int index;
  final ValueChanged<int> onSelect;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: BuaColors.paper,
        border: Border(top: BorderSide(color: BuaColors.line)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              _tab(0, Icons.home_rounded, 'Hôm nay'),
              _tab(1, Icons.menu_book_rounded, 'Nhật ký'),
              Expanded(
                child: Center(
                  child: Transform.translate(
                    offset: const Offset(0, -13),
                    child: Material(
                      color: BuaColors.lime,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                        side: const BorderSide(color: Color(0xFFC9E25C)),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: onAdd,
                        child: const SizedBox(
                          width: 50,
                          height: 50,
                          child: Icon(
                            Icons.add_rounded,
                            color: BuaColors.ink,
                            size: 26,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              _tab(2, Icons.insights_rounded, 'Tiến độ'),
              _tab(3, Icons.person_rounded, 'Tôi'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _tab(int target, IconData icon, String label) {
    final active = index == target;
    return Expanded(
      child: InkResponse(
        onTap: () => onSelect(target),
        radius: 32,
        child: SizedBox(
          height: 58,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 22,
                color: active ? BuaColors.ink : BuaColors.muted2,
              ),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: active ? BuaColors.ink : BuaColors.muted2,
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 3,
                height: 3,
                decoration: BoxDecoration(
                  color: active ? BuaColors.tomato : Colors.transparent,
                  shape: BoxShape.circle,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class BuaDateStrip extends StatefulWidget {
  const BuaDateStrip({
    super.key,
    required this.selected,
    required this.onSelected,
    this.days = 90,
  });

  final DateTime selected;
  final ValueChanged<DateTime> onSelected;
  final int days;

  @override
  State<BuaDateStrip> createState() => _BuaDateStripState();
}

class _BuaDateStripState extends State<BuaDateStrip> {
  static const double _itemWidth = 54;
  static const double _gap = 8;
  late final ScrollController _controller;
  late List<DateTime> _dates;

  @override
  void initState() {
    super.initState();
    _dates = _buildDates();
    final todayIndex = _dates.length - 1;
    final selectedIndex = _indexOf(widget.selected);
    final initial = selectedIndex == todayIndex
        ? math.max(0.0, (todayIndex - 3) * (_itemWidth + _gap))
        : math.max(0.0, (selectedIndex - 2) * (_itemWidth + _gap));
    _controller = ScrollController(initialScrollOffset: initial);
  }

  @override
  void didUpdateWidget(covariant BuaDateStrip oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.days != widget.days) {
      _dates = _buildDates();
    }
    if (dateKey(oldWidget.selected) != dateKey(widget.selected) &&
        _controller.hasClients) {
      final index = _indexOf(widget.selected);
      _controller.animateTo(
        math.max(0.0, (index - 2) * (_itemWidth + _gap)),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
      );
    }
  }

  List<DateTime> _buildDates() {
    final today = dateOnly(DateTime.now());
    return List.generate(
      widget.days,
      (i) => today.subtract(Duration(days: widget.days - 1 - i)),
    );
  }

  int _indexOf(DateTime date) {
    final key = dateKey(date);
    final index = _dates.indexWhere((d) => dateKey(d) == key);
    return index < 0 ? _dates.length - 1 : index;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final today = dateKey(DateTime.now());
    return SizedBox(
      height: 70,
      child: ListView.separated(
        controller: _controller,
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: _dates.length,
        separatorBuilder: (_, _) => const SizedBox(width: _gap),
        itemBuilder: (context, index) {
          final date = _dates[index];
          final selected = dateKey(date) == dateKey(widget.selected);
          final isToday = dateKey(date) == today;
          return GestureDetector(
            onTap: () => widget.onSelected(date),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: _itemWidth,
              padding: const EdgeInsets.symmetric(vertical: 7),
              decoration: BoxDecoration(
                color: selected ? BuaColors.ink : BuaColors.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: selected
                      ? BuaColors.ink
                      : isToday
                      ? BuaColors.leaf
                      : BuaColors.line,
                  width: isToday && !selected ? 1.4 : 1,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    weekdayShort(date),
                    style: TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: selected
                          ? BuaColors.lime
                          : isToday
                          ? BuaColors.leaf
                          : BuaColors.muted2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${date.day}',
                    style: serifStyle(
                      20,
                      color: selected ? BuaColors.paper : BuaColors.ink,
                      letterSpacing: -0.4,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class BuaStatTile extends StatelessWidget {
  const BuaStatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.color = BuaColors.ink,
  });

  final String label;
  final String value;
  final String? unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return PaperCard(
      radius: 16,
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontSize: 8,
              letterSpacing: 0.8,
              color: BuaColors.muted2,
            ),
          ),
          const SizedBox(height: 4),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: numberStyle(20, color: color, weight: FontWeight.w600),
                ),
                if (unit != null)
                  TextSpan(
                    text: ' $unit',
                    style: const TextStyle(
                      fontFamily: 'BeVietnamPro',
                      fontSize: 9,
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

Future<bool> confirmAction(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Xóa',
  bool destructive = true,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          style: TextButton.styleFrom(
            foregroundColor: destructive ? BuaColors.tomato : BuaColors.ink,
          ),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showBuaSnack(
  BuildContext context,
  String message, {
  SnackBarAction? action,
}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}
