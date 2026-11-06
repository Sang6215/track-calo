import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class CustomFoodPage extends StatefulWidget {
  const CustomFoodPage({super.key, required this.store});

  final AppStore store;

  @override
  State<CustomFoodPage> createState() => _CustomFoodPageState();
}

class _CustomFoodPageState extends State<CustomFoodPage> {
  final _name = TextEditingController();
  final _servingLabel = TextEditingController(text: '1 phần');
  final _grams = TextEditingController(text: '100');
  final _kcal = TextEditingController();
  final _protein = TextEditingController();
  final _carb = TextEditingController();
  final _fat = TextEditingController();
  String _category = 'protein';
  bool _saving = false;

  @override
  void dispose() {
    for (final c in [
      _name,
      _servingLabel,
      _grams,
      _kcal,
      _protein,
      _carb,
      _fat,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    if (_saving) return;
    final name = _name.text.trim();
    final grams = _num(_grams);
    final kcal = _num(_kcal) ?? 0;
    final protein = _num(_protein) ?? 0;
    final carb = _num(_carb) ?? 0;
    final fat = _num(_fat) ?? 0;

    if (name.isEmpty) {
      showBuaSnack(context, 'Đặt tên cho món trước đã.');
      return;
    }
    if (grams == null || grams <= 0 || grams > 5000) {
      showBuaSnack(context, 'Khối lượng khẩu phần chưa hợp lệ.');
      return;
    }
    if (kcal < 0 || protein < 0 || carb < 0 || fat < 0) {
      showBuaSnack(context, 'Giá trị dinh dưỡng không thể âm.');
      return;
    }

    setState(() => _saving = true);
    final factor = 100 / grams;
    final food = Food(
      id: 'custom_${newId()}',
      name: name,
      category: _category,
      servingLabel: _servingLabel.text.trim().isEmpty
          ? '1 phần'
          : _servingLabel.text.trim(),
      servingGrams: grams,
      kcal100: kcal * factor,
      protein100: protein * factor,
      carb100: carb * factor,
      fat100: fat * factor,
      custom: true,
    );
    await widget.store.addCustomFood(food);
    if (!mounted) return;
    HapticFeedback.lightImpact();
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Row(
                children: [
                  BuaIconButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Quay lại',
                    onPressed: () => Navigator.of(context).pop(false),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Tạo món',
                      style: serifStyle(24, letterSpacing: -0.6),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    PaperCard(
                      color: BuaColors.limeSoft,
                      borderColor: const Color(0xFFDFEBA9),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.restaurant_menu_rounded,
                            size: 20,
                            color: BuaColors.ink,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              'Nhập dinh dưỡng cho đúng khẩu phần bạn hay ăn. Track Calo sẽ tự quy đổi khi bạn đổi số gram.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF40502F),
                                    fontSize: 11,
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Tên món'),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _name,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Ví dụ: Cơm gà của mẹ',
                      ),
                    ),
                    const SizedBox(height: 16),
                    _label('Nhóm món'),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        for (final category in foodCategories)
                          _categoryChip(category),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Khẩu phần'),
                              const SizedBox(height: 6),
                              TextField(
                                controller: _servingLabel,
                                decoration: const InputDecoration(
                                  hintText: '1 bát',
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _label('Khối lượng'),
                              const SizedBox(height: 6),
                              _numField(_grams, 'g'),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _label('Dinh dưỡng cho cả khẩu phần'),
                    const SizedBox(height: 6),
                    _numField(_kcal, 'kcal', hint: '450'),
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        Expanded(child: _macroField(_protein, 'Đạm', 'g')),
                        const SizedBox(width: 8),
                        Expanded(child: _macroField(_carb, 'Tinh bột', 'g')),
                        const SizedBox(width: 8),
                        Expanded(child: _macroField(_fat, 'Chất béo', 'g')),
                      ],
                    ),
                    const SizedBox(height: 18),
                    _preview(),
                    const SizedBox(height: 12),
                    Text(
                      'Món tự tạo chỉ lưu trên máy bạn. Có thể xoá trong mục “Món tự tạo” khi tìm món.',
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 10),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                14 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: const Text('Lưu món'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: Theme.of(
      context,
    ).textTheme.labelMedium?.copyWith(color: BuaColors.muted, fontSize: 11.5),
  );

  Widget _numField(
    TextEditingController controller,
    String suffix, {
    String? hint,
  }) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
      style: numberStyle(16),
      decoration: InputDecoration(
        hintText: hint ?? '0',
        suffixText: suffix,
        suffixStyle: const TextStyle(
          fontFamily: 'BeVietnamPro',
          fontSize: 11,
          color: BuaColors.muted,
        ),
      ),
    );
  }

  Widget _macroField(
    TextEditingController controller,
    String label,
    String suffix,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(fontSize: 10, color: BuaColors.muted),
        ),
        const SizedBox(height: 5),
        _numField(controller, suffix),
      ],
    );
  }

  Widget _categoryChip(String category) {
    final selected = _category == category;
    return GestureDetector(
      onTap: () => setState(() => _category = category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? BuaColors.ink : BuaColors.paper,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: selected ? BuaColors.ink : BuaColors.line),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              categoryIcon(category),
              size: 14,
              color: selected ? BuaColors.lime : categoryColor(category),
            ),
            const SizedBox(width: 5),
            Text(
              categoryLabel(category),
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 9.5,
                fontWeight: FontWeight.w600,
                color: selected ? BuaColors.lime : BuaColors.muted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _preview() {
    final kcal = _num(_kcal) ?? 0;
    final protein = _num(_protein) ?? 0;
    final carb = _num(_carb) ?? 0;
    final fat = _num(_fat) ?? 0;
    final name = _name.text.trim().isEmpty ? 'Món của bạn' : _name.text.trim();
    return PaperCard(
      color: BuaColors.ink,
      borderColor: BuaColors.ink,
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 12),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: BuaColors.lime.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              categoryIcon(_category),
              color: BuaColors.lime,
              size: 21,
            ),
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: BuaColors.paper,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${_servingLabel.text.trim().isEmpty ? '1 phần' : _servingLabel.text.trim()} · ${_grams.text} g',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 9,
                    color: Color(0xFFBFD6C4),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                fmtKcal(kcal),
                style: numberStyle(
                  20,
                  color: BuaColors.lime,
                  weight: FontWeight.w700,
                ),
              ),
              Text(
                '${fmtGram(protein)}P · ${fmtGram(carb)}C · ${fmtGram(fat)}F',
                style: const TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 7.5,
                  color: Color(0xFFBFD6C4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
