import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key, required this.store});

  final AppStore store;

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final _pageController = PageController();
  final _name = TextEditingController();
  final _age = TextEditingController(text: '24');
  final _height = TextEditingController(text: '170');
  final _weight = TextEditingController(text: '65');
  final _targetWeight = TextEditingController();

  int _step = 0;
  Sex _sex = Sex.male;
  Activity _activity = Activity.moderate;
  Goal _goal = Goal.maintain;
  double _pace = 0.5;
  int _preset = 0;

  static const _presets = [
    (name: 'Cân bằng', p: 30, c: 40, f: 30),
    (name: 'Nhiều đạm', p: 35, c: 35, f: 30),
    (name: 'Ít carb', p: 35, c: 25, f: 40),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    _name.dispose();
    _age.dispose();
    _height.dispose();
    _weight.dispose();
    _targetWeight.dispose();
    super.dispose();
  }

  double? _num(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  String? _validateStepOne() {
    final age = _num(_age);
    final height = _num(_height);
    final weight = _num(_weight);
    if (age == null || age < 12 || age > 100) {
      return 'Tuổi cần nằm trong khoảng 12–100.';
    }
    if (height == null || height < 120 || height > 230) {
      return 'Chiều cao cần nằm trong khoảng 120–230 cm.';
    }
    if (weight == null || weight < 30 || weight > 300) {
      return 'Cân nặng cần nằm trong khoảng 30–300 kg.';
    }
    return null;
  }

  String? _validateStepTwo() {
    if (_goal != Goal.maintain && _targetWeight.text.trim().isNotEmpty) {
      final target = _num(_targetWeight);
      if (target == null || target < 30 || target > 300) {
        return 'Cân nặng mục tiêu không hợp lệ.';
      }
    }
    return null;
  }

  Profile _buildProfile() {
    final preset = _presets[_preset];
    final weight = _num(_weight) ?? 65;
    return Profile(
      name: _name.text.trim(),
      sex: _sex,
      age: (_num(_age) ?? 24).round(),
      heightCm: _num(_height) ?? 170,
      weightKg: weight,
      activity: _activity,
      goal: _goal,
      pace: _goal == Goal.maintain ? 0 : _pace,
      targetWeightKg: _goal == Goal.maintain ? null : _num(_targetWeight),
      proteinPct: preset.p,
      carbPct: preset.c,
      fatPct: preset.f,
    );
  }

  void _next() {
    FocusScope.of(context).unfocus();
    if (_step == 0) {
      final error = _validateStepOne();
      if (error != null) {
        showBuaSnack(context, error);
        return;
      }
    }
    if (_step == 1) {
      final error = _validateStepTwo();
      if (error != null) {
        showBuaSnack(context, error);
        return;
      }
    }
    if (_step == 2) {
      HapticFeedback.mediumImpact();
      widget.store.completeOnboarding(_buildProfile());
      return;
    }
    setState(() => _step++);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeOutCubic,
    );
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step--);
    _pageController.animateToPage(
      _step,
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _step > 0) _back();
      },
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 14, 22, 0),
                child: Row(
                  children: [
                    const Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: BuaLogo(size: 24),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '0${_step + 1} / 03',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: BuaColors.leaf,
                        letterSpacing: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Row(
                  children: List.generate(3, (index) {
                    final active = index <= _step;
                    return Expanded(
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 240),
                        height: 4,
                        margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                        decoration: BoxDecoration(
                          color: active ? BuaColors.ink : BuaColors.line,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    );
                  }),
                ),
              ),
              Expanded(
                child: PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [_bodyStep(), _goalStep(), _resultStep()],
                ),
              ),
              Padding(
                padding: EdgeInsets.fromLTRB(
                  22,
                  8,
                  22,
                  14 + MediaQuery.viewInsetsOf(context).bottom,
                ),
                child: Row(
                  children: [
                    if (_step > 0)
                      SizedBox(
                        width: 52,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: _back,
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.zero,
                            minimumSize: const Size(52, 52),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Icon(Icons.arrow_back_rounded, size: 20),
                        ),
                      ),
                    if (_step > 0) const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: _next,
                        child: Text(
                          _step == 2 ? 'Bắt đầu sử dụng' : 'Tiếp tục',
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

  Widget _pageShell({
    required String eyebrow,
    required String title,
    required Widget child,
  }) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(22, 24, 22, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow.toUpperCase(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: BuaColors.leaf,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(title, style: Theme.of(context).textTheme.displaySmall),
          const SizedBox(height: 22),
          child,
        ],
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool decimal = false,
    bool numeric = true,
    String? suffix,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: BuaColors.muted,
            fontSize: 11.5,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          keyboardType:
              keyboardType ??
              (numeric
                  ? (decimal
                        ? const TextInputType.numberWithOptions(decimal: true)
                        : TextInputType.number)
                  : TextInputType.text),
          inputFormatters: numeric
              ? [
                  decimal
                      ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                      : FilteringTextInputFormatter.digitsOnly,
                ]
              : null,
          style: numeric ? numberStyle(17) : null,
          decoration: InputDecoration(
            hintText: hint,
            suffixText: suffix,
            suffixStyle: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 12,
              color: BuaColors.muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bodyStep() {
    return _pageShell(
      eyebrow: 'Bước 1 · Về bạn',
      title: 'Cho Track Calo biết\nbạn là ai.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _field(
            controller: _name,
            label: 'Tên gọi',
            hint: 'Bảo',
            numeric: false,
            keyboardType: TextInputType.name,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _field(
                  controller: _age,
                  label: 'Tuổi',
                  hint: '24',
                  suffix: 'tuổi',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  controller: _height,
                  label: 'Chiều cao',
                  hint: '170',
                  suffix: 'cm',
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _field(
                  controller: _weight,
                  label: 'Cân nặng',
                  hint: '65',
                  suffix: 'kg',
                  decimal: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            'Giới tính',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: BuaColors.muted,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _choiceCard(
                  selected: _sex == Sex.male,
                  icon: Icons.male_rounded,
                  title: 'Nam',
                  subtitle: 'Dùng công thức Mifflin–St Jeor',
                  onTap: () => setState(() => _sex = Sex.male),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _choiceCard(
                  selected: _sex == Sex.female,
                  icon: Icons.female_rounded,
                  title: 'Nữ',
                  subtitle: 'Dùng công thức Mifflin–St Jeor',
                  onTap: () => setState(() => _sex = Sex.female),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          PaperCard(
            color: BuaColors.limeSoft,
            borderColor: const Color(0xFFDFEBA9),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: BuaColors.ink,
                ),
                const SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'Track Calo dùng số đo này để ước tính nhu cầu calo. Bạn có thể sửa lại bất cứ lúc nào trong mục “Tôi”.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: const Color(0xFF40502F),
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _choiceCard({
    required bool selected,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    String? badge,
  }) {
    final bg = selected ? BuaColors.ink : BuaColors.paper;
    final fg = selected ? BuaColors.paper : BuaColors.ink;
    final sub = selected ? const Color(0xFFBFD6C4) : BuaColors.muted2;
    return Material(
      color: bg,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: BorderSide(
          color: selected ? BuaColors.ink : BuaColors.line,
          width: selected ? 1.6 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    icon,
                    size: 20,
                    color: selected ? BuaColors.lime : BuaColors.leaf,
                  ),
                  const Spacer(),
                  if (badge != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: selected ? BuaColors.lime : BuaColors.limeSoft,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Text(
                        badge,
                        style: const TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                          color: BuaColors.ink,
                        ),
                      ),
                    )
                  else if (selected)
                    const Icon(
                      Icons.check_circle_rounded,
                      size: 16,
                      color: BuaColors.lime,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: fg,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'BeVietnamPro',
                  fontSize: 9.5,
                  height: 1.35,
                  color: sub,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _goalStep() {
    return _pageShell(
      eyebrow: 'Bước 2 · Mục tiêu',
      title: 'Bạn muốn đi\nđến đâu?',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Mức vận động',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: BuaColors.muted,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 8),
          ...Activity.values.map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: _activityTile(activity),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Mục tiêu',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: BuaColors.muted,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 8),
          IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: Goal.values.map((goal) {
                final selected = _goal == goal;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: goal == Goal.gain ? 0 : 8),
                    child: _choiceCard(
                      selected: selected,
                      icon: switch (goal) {
                        Goal.lose => Icons.trending_down_rounded,
                        Goal.maintain => Icons.trending_flat_rounded,
                        Goal.gain => Icons.trending_up_rounded,
                      },
                      title: goal.label,
                      subtitle: goal.hint,
                      onTap: () => setState(() {
                        _goal = goal;
                        if (_goal == Goal.maintain) _targetWeight.clear();
                      }),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          if (_goal != Goal.maintain) ...[
            const SizedBox(height: 16),
            Text(
              'Tốc độ',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: BuaColors.muted,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                for (final pace in const [0.25, 0.5, 0.75])
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: pace == 0.75 ? 0 : 8),
                      child: _paceChip(pace),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _field(
              controller: _targetWeight,
              label: 'Cân nặng mục tiêu (không bắt buộc)',
              hint: '60',
              suffix: 'kg',
              decimal: true,
            ),
          ],
        ],
      ),
    );
  }

  Widget _activityTile(Activity activity) {
    final selected = _activity == activity;
    return Material(
      color: selected ? BuaColors.limeSoft : BuaColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(
          color: selected ? BuaColors.leaf : BuaColors.line,
          width: selected ? 1.5 : 1,
        ),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => setState(() => _activity = activity),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                selected
                    ? Icons.radio_button_checked_rounded
                    : Icons.radio_button_off_rounded,
                size: 18,
                color: selected ? BuaColors.leaf : BuaColors.muted2,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      activity.label,
                      style: Theme.of(
                        context,
                      ).textTheme.titleSmall?.copyWith(fontSize: 12.5),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      activity.hint,
                      style: Theme.of(
                        context,
                      ).textTheme.bodySmall?.copyWith(fontSize: 10),
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

  Widget _paceChip(double pace) {
    final selected = (_pace - pace).abs() < 0.01;
    return GestureDetector(
      onTap: () => setState(() => _pace = pace),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? BuaColors.ink : BuaColors.paper,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: selected ? BuaColors.ink : BuaColors.line),
        ),
        child: Text(
          '${fmtNum(pace, decimals: 2)} kg/tuần',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: selected ? BuaColors.lime : BuaColors.muted,
          ),
        ),
      ),
    );
  }

  Widget _resultStep() {
    final profile = _buildProfile();
    final targets = profile.targets;
    return _pageShell(
      eyebrow: 'Bước 3 · Kế hoạch',
      title: 'Mỗi ngày của bạn\nbắt đầu từ đây.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          PaperCard(
            color: BuaColors.ink,
            borderColor: BuaColors.ink,
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: BuaColors.lime,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'MỤC TIÊU MỖI NGÀY',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: const Color(0xFFBFD6C4),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${targets.kcal.round()}',
                      style: serifStyle(
                        52,
                        color: BuaColors.lime,
                        letterSpacing: -2,
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 8, left: 5),
                      child: Text(
                        'kcal',
                        style: TextStyle(
                          fontFamily: 'BeVietnamPro',
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFFBFD6C4),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                MacroBar(
                  label: 'Đạm',
                  value: targets.proteinG,
                  target: targets.proteinG,
                  color: BuaColors.lime,
                  dark: true,
                  showNumbers: false,
                ),
                const SizedBox(height: 9),
                MacroBar(
                  label: 'Tinh bột',
                  value: targets.carbG,
                  target: targets.carbG,
                  color: const Color(0xFFF2C14E),
                  dark: true,
                  showNumbers: false,
                ),
                const SizedBox(height: 9),
                MacroBar(
                  label: 'Chất béo',
                  value: targets.fatG,
                  target: targets.fatG,
                  color: const Color(0xFFF08A6A),
                  dark: true,
                  showNumbers: false,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    _macroNumber('Đạm', targets.proteinG, 'g'),
                    _macroNumber('Tinh bột', targets.carbG, 'g'),
                    _macroNumber('Béo', targets.fatG, 'g'),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Kiểu macro',
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: BuaColors.muted,
              fontSize: 11.5,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              for (var i = 0; i < _presets.length; i++)
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: i == _presets.length - 1 ? 0 : 8,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _preset = i),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 6,
                        ),
                        decoration: BoxDecoration(
                          color: _preset == i
                              ? BuaColors.limeSoft
                              : BuaColors.paper,
                          borderRadius: BorderRadius.circular(13),
                          border: Border.all(
                            color: _preset == i
                                ? BuaColors.leaf
                                : BuaColors.line,
                            width: _preset == i ? 1.5 : 1,
                          ),
                        ),
                        child: Column(
                          children: [
                            Text(
                              _presets[i].name,
                              style: TextStyle(
                                fontFamily: 'BeVietnamPro',
                                fontSize: 10.5,
                                fontWeight: FontWeight.w700,
                                color: BuaColors.ink,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${_presets[i].p}/${_presets[i].c}/${_presets[i].f}',
                              style: numberStyle(9.5, color: BuaColors.muted),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.favorite_rounded,
                size: 15,
                color: BuaColors.tomato,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Ước tính mang tính tham khảo, không thay thế tư vấn y khoa.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _macroNumber(String label, double grams, String unit) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 8.5,
              color: Color(0xFFBFD6C4),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            '${fmtGram(grams)} $unit',
            style: numberStyle(
              13,
              color: BuaColors.paper,
              weight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
