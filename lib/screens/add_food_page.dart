import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';
import 'custom_food_page.dart';

Future<bool?> showPortionSheet(
  BuildContext context, {
  required AppStore store,
  required Food food,
  required String date,
  required MealType meal,
  LogEntry? existing,
}) {
  return showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) => PortionSheet(
      store: store,
      food: food,
      date: date,
      meal: meal,
      existing: existing,
    ),
  );
}

Future<void> editEntryPortion(
  BuildContext context, {
  required AppStore store,
  required LogEntry entry,
}) async {
  final food = store.foodById(entry.foodId);
  if (food != null) {
    await showPortionSheet(
      context,
      store: store,
      food: food,
      date: entry.date,
      meal: entry.meal,
      existing: entry,
    );
    return;
  }

  final controller = TextEditingController(text: fmtGram(entry.grams));
  final grams = await showDialog<double>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Sửa khẩu phần'),
      content: TextField(
        controller: controller,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
        ],
        decoration: const InputDecoration(
          labelText: 'Khối lượng',
          suffixText: 'g',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Hủy'),
        ),
        TextButton(
          onPressed: () {
            final value = double.tryParse(controller.text.replaceAll(',', '.'));
            if (value != null && value > 0) Navigator.pop(context, value);
          },
          child: const Text('Lưu'),
        ),
      ],
    ),
  );
  controller.dispose();
  if (grams != null) {
    await store.updateEntry(entry.copyWith(grams: grams));
  }
}

class PortionSheet extends StatefulWidget {
  const PortionSheet({
    super.key,
    required this.store,
    required this.food,
    required this.date,
    required this.meal,
    this.existing,
  });

  final AppStore store;
  final Food food;
  final String date;
  final MealType meal;
  final LogEntry? existing;

  @override
  State<PortionSheet> createState() => _PortionSheetState();
}

class _PortionSheetState extends State<PortionSheet> {
  late double _grams;
  late final double _step;
  late final TextEditingController _controller;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _grams = widget.existing?.grams ?? widget.food.servingGrams;
    _step = (widget.food.servingGrams / 4).roundToDouble().clamp(5, 100);
    _controller = TextEditingController(text: fmtGram(_grams));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _setGrams(double value) {
    final next = value.clamp(1.0, 3000.0);
    setState(() => _grams = next.roundToDouble());
    _controller.text = fmtGram(_grams);
  }

  double get _kcal => widget.food.kcal100 * _grams / 100;
  double get _protein => widget.food.protein100 * _grams / 100;
  double get _carb => widget.food.carb100 * _grams / 100;
  double get _fat => widget.food.fat100 * _grams / 100;
  double get _portion =>
      widget.food.servingGrams == 0 ? 1 : _grams / widget.food.servingGrams;

  Future<void> _submit() async {
    if (_saving) return;
    setState(() => _saving = true);
    HapticFeedback.mediumImpact();
    if (widget.existing != null) {
      await widget.store.updateEntry(widget.existing!.copyWith(grams: _grams));
    } else {
      await widget.store.addFood(
        food: widget.food,
        date: widget.date,
        meal: widget.meal,
        grams: _grams,
      );
    }
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.viewInsetsOf(context).bottom;
    return Container(
      decoration: const BoxDecoration(
        color: BuaColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(18, 8, 18, 16 + bottom),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 38,
                height: 4,
                margin: const EdgeInsets.only(bottom: 14),
                decoration: BoxDecoration(
                  color: BuaColors.line,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                FoodThumb(food: widget.food, size: 46),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.food.name,
                        style: serifStyle(24, letterSpacing: -0.6),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${widget.food.servingLabel} · ${fmtGram(widget.food.servingGrams)} g · ${widget.meal.labelLong}',
                        style: Theme.of(
                          context,
                        ).textTheme.bodySmall?.copyWith(fontSize: 10.5),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      fmtKcal(_kcal),
                      style: serifStyle(
                        26,
                        color: BuaColors.tomato,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const Text(
                      'KCAL',
                      style: TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 7.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.9,
                        color: BuaColors.muted2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(7),
              decoration: BoxDecoration(
                color: BuaColors.cream,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: BuaColors.line),
              ),
              child: Row(
                children: [
                  _stepButton(
                    Icons.remove_rounded,
                    () => _setGrams(_grams - _step),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        TextField(
                          controller: _controller,
                          textAlign: TextAlign.center,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(
                              RegExp(r'[0-9.,]'),
                            ),
                          ],
                          style: serifStyle(26, letterSpacing: -0.6),
                          decoration: const InputDecoration(
                            isDense: true,
                            filled: false,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            suffixText: 'g',
                            suffixStyle: TextStyle(
                              fontFamily: 'BeVietnamPro',
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: BuaColors.muted,
                            ),
                          ),
                          onChanged: (text) {
                            final value = double.tryParse(
                              text.replaceAll(',', '.'),
                            );
                            if (value != null && value > 0) {
                              setState(
                                () => _grams = value.clamp(1, 3000).toDouble(),
                              );
                            }
                          },
                          onSubmitted: (text) {
                            final value = double.tryParse(
                              text.replaceAll(',', '.'),
                            );
                            _setGrams(value ?? _grams);
                          },
                        ),
                        Text(
                          '≈ ${fmtNum(_portion, decimals: 2)} khẩu phần',
                          style: Theme.of(
                            context,
                          ).textTheme.bodySmall?.copyWith(fontSize: 9.5),
                        ),
                      ],
                    ),
                  ),
                  _stepButton(
                    Icons.add_rounded,
                    () => _setGrams(_grams + _step),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 9),
            Row(
              children: [
                for (final factor in const [0.5, 1.0, 1.5, 2.0])
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: factor == 2 ? 0 : 6),
                      child: _quickChip(factor),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _macro('Đạm', _protein, BuaColors.tomato),
                const SizedBox(width: 7),
                _macro('Tinh bột', _carb, BuaColors.honey),
                const SizedBox(width: 7),
                _macro('Chất béo', _fat, BuaColors.leaf),
              ],
            ),
            const SizedBox(height: 13),
            FilledButton(
              onPressed: _saving ? null : _submit,
              child: Text(
                widget.existing != null
                    ? 'Cập nhật · ${fmtKcal(_kcal)} kcal'
                    : 'Thêm vào ${widget.meal.label.toLowerCase()} · ${fmtKcal(_kcal)} kcal',
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Có thể nhập gram chính xác bằng cách bấm vào ô khối lượng.',
              textAlign: TextAlign.center,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(fontSize: 9.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: BuaColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(11),
        side: const BorderSide(color: BuaColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, size: 20)),
      ),
    );
  }

  Widget _quickChip(double factor) {
    final target = widget.food.servingGrams * factor;
    final selected = (_grams - target).abs() < 0.6;
    return GestureDetector(
      onTap: () => _setGrams(target),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? BuaColors.ink : BuaColors.paper,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: selected ? BuaColors.ink : BuaColors.line),
        ),
        child: Text(
          factor == 0.5
              ? '½'
              : factor == 1
              ? '1'
              : factor == 1.5
              ? '1½'
              : '2',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? BuaColors.lime : BuaColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _macro(String label, double value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: BuaColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: BuaColors.lineSoft),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 8,
                    fontWeight: FontWeight.w600,
                    color: BuaColors.muted2,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 3),
            Text(
              '${fmtGram(value)} g',
              style: numberStyle(12.5, weight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class AddFoodPage extends StatefulWidget {
  const AddFoodPage({
    super.key,
    required this.store,
    required this.date,
    required this.initialMeal,
  });

  final AppStore store;
  final String date;
  final MealType initialMeal;

  @override
  State<AddFoodPage> createState() => _AddFoodPageState();
}

class _AddFoodPageState extends State<AddFoodPage> {
  late MealType _meal;
  late FoodFilter _filter;
  final _search = TextEditingController();
  int _added = 0;

  @override
  void initState() {
    super.initState();
    _meal = widget.initialMeal;
    _filter = widget.store.recentFoods.isEmpty
        ? FoodFilter.all
        : FoodFilter.recent;
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _pick(Food food) async {
    final added = await showPortionSheet(
      context,
      store: widget.store,
      food: food,
      date: widget.date,
      meal: _meal,
    );
    if (added == true && mounted) {
      setState(() => _added++);
      showBuaSnack(
        context,
        'Đã thêm ${food.name}',
        action: SnackBarAction(
          label: 'Xong',
          onPressed: () => Navigator.of(context).pop(),
        ),
      );
    }
  }

  Future<void> _applyCombo(Combo combo) async {
    final count = await widget.store.applyCombo(combo, widget.date);
    if (!mounted) return;
    if (count == 0) {
      showBuaSnack(context, 'Bữa quen này không còn món nào khả dụng.');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _added += count);
    showBuaSnack(
      context,
      'Đã thêm “${combo.name}” · $count món',
      action: SnackBarAction(
        label: 'Xong',
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Future<void> _deleteCombo(Combo combo) async {
    final ok = await confirmAction(
      context,
      title: 'Xóa bữa quen?',
      message:
          '“${combo.name}” sẽ bị xóa khỏi danh sách. Các bữa đã ghi vẫn được giữ.',
    );
    if (ok) await widget.store.deleteCombo(combo.id);
  }

  Future<void> _createFood() async {
    final created = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (_) => CustomFoodPage(store: widget.store)),
    );
    if (created == true && mounted) {
      setState(() => _filter = FoodFilter.custom);
    }
  }

  Future<void> _deleteCustomFood(Food food) async {
    final ok = await confirmAction(
      context,
      title: 'Xóa món tự tạo?',
      message:
          '“${food.name}” sẽ bị xóa khỏi danh sách. Các bữa đã ghi vẫn giữ dinh dưỡng cũ.',
    );
    if (ok) await widget.store.deleteCustomFood(food.id);
  }

  @override
  Widget build(BuildContext context) {
    final foods = widget.store.searchFoods(_search.text, _filter);
    final combos = widget.store.combos;
    final showCombos = _search.text.trim().isEmpty && combos.isNotEmpty;

    return ScaffoldMessenger(
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 10, 0),
                child: Row(
                  children: [
                    BuaIconButton(
                      icon: Icons.arrow_back_rounded,
                      tooltip: 'Quay lại',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Thêm bữa ăn',
                            style: serifStyle(24, letterSpacing: -0.6),
                          ),
                          Text(
                            _dateLabel(widget.date),
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(fontSize: 10),
                          ),
                        ],
                      ),
                    ),
                    BuaIconButton(
                      icon: Icons.post_add_rounded,
                      tooltip: 'Tạo món',
                      onPressed: _createFood,
                    ),
                    if (_added > 0) ...[
                      const SizedBox(width: 6),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text('Xong ($_added)'),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    for (final meal in MealType.values)
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(
                            right: meal == MealType.snack ? 0 : 6,
                          ),
                          child: _mealChip(meal),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 11),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: 'Tìm món Việt, thương hiệu…',
                    prefixIcon: const Icon(Icons.search_rounded, size: 21),
                    suffixIcon: _search.text.isEmpty
                        ? null
                        : IconButton(
                            onPressed: () => setState(_search.clear),
                            icon: const Icon(Icons.close_rounded, size: 18),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 9),
              SizedBox(
                height: 34,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    _filterChip('Gần đây', FoodFilter.recent),
                    _filterChip('Yêu thích', FoodFilter.favorites),
                    _filterChip('Tất cả', FoodFilter.all),
                    _filterChip('Tự tạo', FoodFilter.custom),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 26),
                  children: [
                    if (showCombos) ...[
                      BuaSectionHeader(title: 'Bữa quen'),
                      const SizedBox(height: 7),
                      SizedBox(
                        height: 102,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: combos.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 8),
                          itemBuilder: (context, index) =>
                              _comboCard(combos[index]),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                    BuaSectionHeader(
                      title: _sectionTitle(),
                      action: _filter == FoodFilter.custom && foods.isNotEmpty
                          ? 'Giữ để xóa'
                          : '${foods.length} món',
                    ),
                    const SizedBox(height: 6),
                    if (foods.isEmpty)
                      BuaEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'Không tìm thấy món phù hợp',
                        message: _filter == FoodFilter.custom
                            ? 'Bạn chưa tạo món riêng nào. Dùng nút “Tạo món” ở trên để thêm.'
                            : 'Thử tìm không dấu, hoặc chuyển sang tab “Tất cả”.',
                        actionLabel: _filter == FoodFilter.custom
                            ? 'Tạo món'
                            : null,
                        onAction: _filter == FoodFilter.custom
                            ? _createFood
                            : null,
                      )
                    else
                      for (final food in foods)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 7),
                          child: GestureDetector(
                            onLongPress: food.custom
                                ? () => _deleteCustomFood(food)
                                : null,
                            child: FoodTile(
                              food: food,
                              onTap: () => _pick(food),
                              isFavorite: widget.store.isFavorite(food.id),
                              onToggleFavorite: () =>
                                  widget.store.toggleFavorite(food.id),
                            ),
                          ),
                        ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _dateLabel(String date) {
    final parsed = dateFromKey(date);
    return '${weekdayName(parsed)} · ${shortDate(parsed)}';
  }

  String _sectionTitle() => switch (_filter) {
    FoodFilter.recent => 'Món gần đây',
    FoodFilter.favorites => 'Món yêu thích',
    FoodFilter.all => 'Tất cả món',
    FoodFilter.custom => 'Món tự tạo',
  };

  Widget _mealChip(MealType meal) {
    final selected = _meal == meal;
    return GestureDetector(
      onTap: () => setState(() => _meal = meal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? BuaColors.ink : BuaColors.paper,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: selected ? BuaColors.ink : BuaColors.line),
        ),
        child: Text(
          meal.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: selected ? BuaColors.lime : BuaColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, FoodFilter filter) {
    final selected = _filter == filter;
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: GestureDetector(
        onTap: () => setState(() => _filter = filter),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? BuaColors.limeSoft : BuaColors.paper,
            borderRadius: BorderRadius.circular(99),
            border: Border.all(
              color: selected ? BuaColors.leaf : BuaColors.line,
              width: selected ? 1.4 : 1,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: selected ? BuaColors.ink : BuaColors.muted,
            ),
          ),
        ),
      ),
    );
  }

  Widget _comboCard(Combo combo) {
    final totals = widget.store.comboFoodTotals(combo);
    return SizedBox(
      width: 178,
      child: GestureDetector(
        onLongPress: () => _deleteCombo(combo),
        child: PaperCard(
          onTap: () => _applyCombo(combo),
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
}
