import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';

import '../models.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, required this.store});

  final AppStore store;

  Future<void> _export(BuildContext context) async {
    try {
      final file = await store.writeExportFile();
      if (!context.mounted) return;
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(file.path)],
          text: 'Bản sao lưu dữ liệu Track Calo',
        ),
      );
      if (context.mounted) {
        showBuaSnack(
          context,
          'Đã tạo bản sao lưu ${file.uri.pathSegments.last}.',
        );
      }
    } catch (error) {
      if (context.mounted) {
        showBuaSnack(context, 'Chưa xuất được bản sao lưu. Thử lại sau.');
      }
    }
  }

  Future<void> _import(BuildContext context) async {
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: ['json'],
        dialogTitle: 'Chọn tệp sao lưu Track Calo',
      );
      if (picked == null || !context.mounted) return;

      final ok = await confirmAction(
        context,
        title: 'Nhập bản sao lưu?',
        message:
            'Dữ liệu hiện tại sẽ được thay thế bằng nội dung trong “${picked.name}”. Nên xuất một bản sao lưu trước khi tiếp tục.',
        confirmLabel: 'Nhập',
        destructive: true,
      );
      if (!ok) return;

      final bytes = await picked.readAsBytes();
      await store.importJson(utf8.decode(bytes));
      if (context.mounted) {
        showBuaSnack(context, 'Đã nhập dữ liệu từ bản sao lưu.');
      }
    } on FormatException {
      if (context.mounted) {
        showBuaSnack(context, 'Tệp không phải bản sao lưu Track Calo hợp lệ.');
      }
    } catch (_) {
      if (context.mounted) {
        showBuaSnack(
          context,
          'Không nhập được tệp này. Thử lại với tệp JSON khác.',
        );
      }
    }
  }

  Future<void> _reset(BuildContext context) async {
    final ok = await confirmAction(
      context,
      title: 'Xóa toàn bộ dữ liệu?',
      message:
          'Hồ sơ, nhật ký, bữa quen và cân nặng sẽ bị xóa khỏi máy. Hãy xuất bản sao lưu nếu cần giữ lại.',
      confirmLabel: 'Xóa hết',
    );
    if (!ok) return;
    await store.resetAll();
  }

  Future<void> _editKcal(BuildContext context, Profile profile) async {
    final controller = TextEditingController(text: '${profile.targetKcal}');
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mục tiêu calo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tự động tính từ TDEE: ${profile.calculatedKcal} kcal. Có thể đặt mục tiêu riêng nếu bạn muốn.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: numberStyle(22),
              decoration: const InputDecoration(suffixText: 'kcal'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Hủy'),
          ),
          if (profile.manualKcal != null)
            TextButton(
              onPressed: () => Navigator.pop(context, 0),
              child: const Text('Tự động'),
            ),
          TextButton(
            onPressed: () {
              final kcal = int.tryParse(controller.text);
              if (kcal != null && kcal >= 800 && kcal <= 6000) {
                Navigator.pop(context, kcal);
              }
            },
            child: const Text('Lưu'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    if (value == 0) {
      await store.updateProfile(profile.copyWith(clearManualKcal: true));
    } else {
      await store.updateProfile(profile.copyWith(manualKcal: value));
    }
  }

  Future<void> _editProfile(BuildContext context, Profile profile) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => ProfileEditPage(store: store, profile: profile),
      ),
    );
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

        return SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 30),
            children: [
              BuaScreenHeader(
                eyebrow: 'Tôi',
                title: profile.name.trim().isEmpty
                    ? 'Của bạn'
                    : profile.name.trim(),
                subtitle: 'Dữ liệu ở lại trên máy này.',
                trailing: BuaIconButton(
                  icon: Icons.edit_rounded,
                  tooltip: 'Sửa hồ sơ',
                  onPressed: () => _editProfile(context, profile),
                ),
              ),
              const SizedBox(height: 16),
              _profileCard(context, profile, targets, latest),
              const SizedBox(height: 18),
              const BuaSectionHeader(title: 'Mục tiêu'),
              const SizedBox(height: 8),
              PaperCard(
                padding: const EdgeInsets.fromLTRB(14, 8, 10, 8),
                child: Column(
                  children: [
                    _targetRow(
                      context,
                      label: 'Mục tiêu calo',
                      value: '${fmtKcal(targets.kcal)} kcal',
                      hint:
                          'BMR ${fmtKcal(profile.bmr)} · TDEE ${fmtKcal(profile.tdee)}${profile.manualKcal != null ? ' · đang đặt tay' : ''}',
                      onTap: () => _editKcal(context, profile),
                      action: 'Chỉnh',
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Kiểu macro',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontSize: 12.5),
                              ),
                              const Spacer(),
                              Text(
                                '${profile.proteinPct}/${profile.carbPct}/${profile.fatPct}',
                                style: numberStyle(
                                  9.5,
                                  color: BuaColors.muted2,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              for (final preset in const [
                                (name: 'Cân bằng', p: 30, c: 40, f: 30),
                                (name: 'Nhiều đạm', p: 35, c: 35, f: 30),
                                (name: 'Ít carb', p: 35, c: 25, f: 40),
                              ])
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.only(
                                      right: preset.name == 'Ít carb' ? 0 : 6,
                                    ),
                                    child: _macroPreset(
                                      context,
                                      profile,
                                      preset.name,
                                      preset.p,
                                      preset.c,
                                      preset.f,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Đạm ${fmtGram(targets.proteinG)} g · Tinh bột ${fmtGram(targets.carbG)} g · Béo ${fmtGram(targets.fatG)} g',
                            style: Theme.of(
                              context,
                            ).textTheme.bodySmall?.copyWith(fontSize: 9.5),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.water_drop_rounded,
                            size: 18,
                            color: BuaColors.water,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Mục tiêu nước',
                                  style: Theme.of(context).textTheme.titleSmall
                                      ?.copyWith(fontSize: 12.5),
                                ),
                                Text(
                                  '${store.waterGoalCups} ly · ${fmtNum(store.waterGoalCups * 0.25, decimals: 1)} lít',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(fontSize: 9.5),
                                ),
                              ],
                            ),
                          ),
                          _stepButton(
                            Icons.remove_rounded,
                            store.waterGoalCups <= 4
                                ? null
                                : () => store.setWaterGoal(
                                    store.waterGoalCups - 1,
                                  ),
                          ),
                          const SizedBox(width: 7),
                          _stepButton(
                            Icons.add_rounded,
                            store.waterGoalCups >= 20
                                ? null
                                : () => store.setWaterGoal(
                                    store.waterGoalCups + 1,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              const BuaSectionHeader(title: 'Dữ liệu'),
              const SizedBox(height: 8),
              PaperCard(
                padding: EdgeInsets.zero,
                child: Column(
                  children: [
                    _dataRow(
                      context,
                      icon: Icons.ios_share_rounded,
                      title: 'Xuất bản sao lưu',
                      subtitle:
                          'Chia sẻ tệp JSON qua Drive, Zalo hoặc máy tính',
                      onTap: () => _export(context),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _dataRow(
                      context,
                      icon: Icons.file_open_rounded,
                      title: 'Nhập bản sao lưu',
                      subtitle: 'Khôi phục từ tệp JSON đã xuất',
                      onTap: () => _import(context),
                    ),
                    const Divider(height: 1, indent: 16, endIndent: 16),
                    _dataRow(
                      context,
                      icon: Icons.shield_outlined,
                      title: 'Tự động sao lưu',
                      subtitle:
                          'Mỗi ngày, giữ 7 bản gần nhất${store.lastSaved == null ? '' : ' · lần cuối ${_savedLabel(store.lastSaved!)}'}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 9),
              Text(
                store.backupDirectoryPath == null
                    ? 'Dữ liệu được lưu cục bộ trên thiết bị.'
                    : 'Sao lưu tự động nằm trong bộ nhớ ứng dụng và sẽ mất khi gỡ app. Hãy xuất tệp JSON khi cài lại máy.\n${store.backupDirectoryPath}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 8.5,
                  color: BuaColors.muted2,
                ),
              ),
              const SizedBox(height: 18),
              OutlinedButton.icon(
                onPressed: () => _reset(context),
                icon: const Icon(Icons.delete_outline_rounded, size: 19),
                label: const Text('Xóa toàn bộ dữ liệu'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BuaColors.tomato,
                  side: const BorderSide(color: Color(0xFFE8B9A5)),
                ),
              ),
              const SizedBox(height: 22),
              Center(
                child: Column(
                  children: [
                    const BuaLogo(size: 26, light: false),
                    const SizedBox(height: 8),
                    Text(
                      'Track Calo 1.0.2 · dành cho sử dụng cá nhân',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 9,
                        color: BuaColors.muted2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Dữ liệu dinh dưỡng là ước tính, không thay thế tư vấn y khoa.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        fontSize: 8.5,
                        color: BuaColors.muted2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _profileCard(
    BuildContext context,
    Profile profile,
    NutritionTargets targets,
    WeightEntry? latest,
  ) {
    final initials = _initials(profile.name);
    return Container(
      padding: const EdgeInsets.fromLTRB(15, 14, 12, 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1E5138), Color(0xFF12372A)],
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: const BoxDecoration(
                  color: BuaColors.lime,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: BuaColors.ink,
                  ),
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.name.trim().isEmpty ? 'Bạn' : profile.name.trim(),
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: BuaColors.paper,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${profile.goal.label} · ${profile.activity.label}',
                      style: const TextStyle(
                        fontFamily: 'BeVietnamPro',
                        fontSize: 9.5,
                        color: Color(0xFFBFD6C4),
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton(
                onPressed: () => _editProfile(context, profile),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BuaColors.lime,
                  side: BorderSide(
                    color: BuaColors.lime.withValues(alpha: 0.45),
                  ),
                  minimumSize: const Size(0, 34),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  textStyle: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Sửa'),
              ),
            ],
          ),
          const SizedBox(height: 13),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.12)),
              ),
            ),
            child: Row(
              children: [
                _profileStat('TDEE', fmtKcal(profile.tdee), 'kcal'),
                _profileStat('Mục tiêu', fmtKcal(targets.kcal), 'kcal'),
                _profileStat(
                  'Hiện tại',
                  latest == null ? '—' : fmtKg(latest.kg),
                  'kg',
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _profileStat(String label, String value, String unit) {
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
              color: Color(0xFFBFD6C4),
            ),
          ),
          const SizedBox(height: 3),
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: numberStyle(
                    16,
                    color: BuaColors.paper,
                    weight: FontWeight.w600,
                  ),
                ),
                TextSpan(
                  text: ' $unit',
                  style: const TextStyle(
                    fontFamily: 'BeVietnamPro',
                    fontSize: 7.5,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFBFD6C4),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _targetRow(
    BuildContext context, {
    required String label,
    required String value,
    required String hint,
    required String action,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 9),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    hint,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 9.5),
                  ),
                ],
              ),
            ),
            Text(
              value,
              style: numberStyle(
                14,
                color: BuaColors.leaf,
                weight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 4),
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                minimumSize: const Size(0, 34),
              ),
              child: Text(action),
            ),
          ],
        ),
      ),
    );
  }

  Widget _macroPreset(
    BuildContext context,
    Profile profile,
    String name,
    int p,
    int c,
    int f,
  ) {
    final selected =
        profile.proteinPct == p && profile.carbPct == c && profile.fatPct == f;
    return GestureDetector(
      onTap: () => store.updateProfile(
        profile.copyWith(proteinPct: p, carbPct: c, fatPct: f),
      ),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: selected ? BuaColors.limeSoft : BuaColors.paper,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(
            color: selected ? BuaColors.leaf : BuaColors.line,
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              name,
              style: TextStyle(
                fontFamily: 'BeVietnamPro',
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                color: selected ? BuaColors.ink : BuaColors.muted,
              ),
            ),
            const SizedBox(height: 1),
            Text('$p/$c/$f', style: numberStyle(8.5, color: BuaColors.muted2)),
          ],
        ),
      ),
    );
  }

  Widget _dataRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 11, 10, 11),
        child: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: const BoxDecoration(
                color: BuaColors.limeSoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: BuaColors.ink),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(
                      context,
                    ).textTheme.titleSmall?.copyWith(fontSize: 12.5),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    subtitle,
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(fontSize: 9.5),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(
                Icons.chevron_right_rounded,
                size: 19,
                color: BuaColors.muted2,
              ),
          ],
        ),
      ),
    );
  }

  Widget _stepButton(IconData icon, VoidCallback? onPressed) {
    return Material(
      color: BuaColors.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
        side: const BorderSide(color: BuaColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: SizedBox(
          width: 36,
          height: 36,
          child: Icon(
            icon,
            size: 18,
            color: onPressed == null ? BuaColors.muted2 : BuaColors.ink,
          ),
        ),
      ),
    );
  }

  String _savedLabel(DateTime time) =>
      '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

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
}

class ProfileEditPage extends StatefulWidget {
  const ProfileEditPage({
    super.key,
    required this.store,
    required this.profile,
  });

  final AppStore store;
  final Profile profile;

  @override
  State<ProfileEditPage> createState() => _ProfileEditPageState();
}

class _ProfileEditPageState extends State<ProfileEditPage> {
  late final TextEditingController _name;
  late final TextEditingController _age;
  late final TextEditingController _height;
  late final TextEditingController _weight;
  late final TextEditingController _targetWeight;
  late Activity _activity;
  late Goal _goal;
  late double _pace;

  @override
  void initState() {
    super.initState();
    final profile = widget.profile;
    _name = TextEditingController(text: profile.name);
    _age = TextEditingController(text: '${profile.age}');
    _height = TextEditingController(
      text: fmtNum(
        profile.heightCm,
        decimals: profile.heightCm % 1 == 0 ? 0 : 1,
      ),
    );
    _weight = TextEditingController(
      text: fmtNum(profile.weightKg, decimals: 1),
    );
    _targetWeight = TextEditingController(
      text: profile.targetWeightKg == null
          ? ''
          : fmtNum(profile.targetWeightKg!, decimals: 1),
    );
    _activity = profile.activity;
    _goal = profile.goal;
    _pace = profile.pace == 0 ? 0.5 : profile.pace;
  }

  @override
  void dispose() {
    for (final c in [_name, _age, _height, _weight, _targetWeight]) {
      c.dispose();
    }
    super.dispose();
  }

  double? _num(TextEditingController controller) =>
      double.tryParse(controller.text.trim().replaceAll(',', '.'));

  Future<void> _save() async {
    final age = _num(_age);
    final height = _num(_height);
    final weight = _num(_weight);
    final target = _num(_targetWeight);
    if (age == null || age < 12 || age > 100) {
      showBuaSnack(context, 'Tuổi cần nằm trong khoảng 12–100.');
      return;
    }
    if (height == null || height < 120 || height > 230) {
      showBuaSnack(context, 'Chiều cao cần nằm trong khoảng 120–230 cm.');
      return;
    }
    if (weight == null || weight < 30 || weight > 300) {
      showBuaSnack(context, 'Cân nặng cần nằm trong khoảng 30–300 kg.');
      return;
    }
    if (_goal != Goal.maintain &&
        _targetWeight.text.trim().isNotEmpty &&
        (target == null || target < 30 || target > 300)) {
      showBuaSnack(context, 'Cân nặng mục tiêu không hợp lệ.');
      return;
    }

    await widget.store.updateProfile(
      widget.profile.copyWith(
        name: _name.text.trim(),
        age: age.round(),
        heightCm: height,
        weightKg: weight,
        activity: _activity,
        goal: _goal,
        pace: _goal == Goal.maintain ? 0 : _pace,
        targetWeightKg: _goal == Goal.maintain ? null : target,
        clearTargetWeight: _goal == Goal.maintain || target == null,
      ),
    );
    if (mounted) Navigator.of(context).pop(true);
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
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Text(
                      'Hồ sơ & mục tiêu',
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
                    _field('Tên gọi', _name, text: true),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _field('Tuổi', _age, suffix: 'tuổi')),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _field('Chiều cao', _height, suffix: 'cm'),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _field(
                            'Cân nặng',
                            _weight,
                            suffix: 'kg',
                            decimal: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mức vận động',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: BuaColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<Activity>(
                      initialValue: _activity,
                      decoration: const InputDecoration(),
                      items: Activity.values
                          .map(
                            (activity) => DropdownMenuItem(
                              value: activity,
                              child: Text(
                                activity.label,
                                style: const TextStyle(
                                  fontFamily: 'BeVietnamPro',
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                      onChanged: (value) {
                        if (value != null) setState(() => _activity = value);
                      },
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Mục tiêu',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: BuaColors.muted,
                        fontSize: 11.5,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        for (final goal in Goal.values)
                          Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: goal == Goal.gain ? 0 : 6,
                              ),
                              child: _goalChip(goal),
                            ),
                          ),
                      ],
                    ),
                    if (_goal != Goal.maintain) ...[
                      const SizedBox(height: 14),
                      Text(
                        'Tốc độ',
                        style: Theme.of(context).textTheme.labelMedium
                            ?.copyWith(color: BuaColors.muted, fontSize: 11.5),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          for (final pace in const [0.25, 0.5, 0.75])
                            Expanded(
                              child: Padding(
                                padding: EdgeInsets.only(
                                  right: pace == 0.75 ? 0 : 6,
                                ),
                                child: _paceChip(pace),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      _field(
                        'Cân nặng mục tiêu (không bắt buộc)',
                        _targetWeight,
                        suffix: 'kg',
                        decimal: true,
                      ),
                    ],
                    const SizedBox(height: 20),
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
                              'Thay đổi cân nặng sẽ được ghi vào lịch sử hôm nay và mục tiêu calo sẽ tính lại tự động.',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: const Color(0xFF40502F),
                                    fontSize: 10.5,
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
            Padding(
              padding: EdgeInsets.fromLTRB(
                16,
                8,
                16,
                14 + MediaQuery.viewInsetsOf(context).bottom,
              ),
              child: FilledButton(
                onPressed: _save,
                child: const Text('Lưu thay đổi'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    String? suffix,
    bool decimal = false,
    bool text = false,
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
        const SizedBox(height: 5),
        TextField(
          controller: controller,
          keyboardType: text
              ? TextInputType.name
              : decimal
              ? const TextInputType.numberWithOptions(decimal: true)
              : TextInputType.number,
          inputFormatters: text
              ? null
              : [
                  decimal
                      ? FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))
                      : FilteringTextInputFormatter.digitsOnly,
                ],
          style: text ? null : numberStyle(15),
          decoration: InputDecoration(
            suffixText: suffix,
            suffixStyle: const TextStyle(
              fontFamily: 'BeVietnamPro',
              fontSize: 10,
              color: BuaColors.muted,
            ),
          ),
        ),
      ],
    );
  }

  Widget _goalChip(Goal goal) {
    final selected = _goal == goal;
    return GestureDetector(
      onTap: () => setState(() => _goal = goal),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? BuaColors.ink : BuaColors.paper,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: selected ? BuaColors.ink : BuaColors.line),
        ),
        child: Text(
          goal.label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: selected ? BuaColors.lime : BuaColors.muted,
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
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: selected ? BuaColors.limeSoft : BuaColors.paper,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: selected ? BuaColors.leaf : BuaColors.line),
        ),
        child: Text(
          '${fmtNum(pace, decimals: 2)} kg',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: 'BeVietnamPro',
            fontSize: 9.5,
            fontWeight: FontWeight.w600,
            color: selected ? BuaColors.ink : BuaColors.muted,
          ),
        ),
      ),
    );
  }
}
