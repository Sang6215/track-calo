import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import 'package:bua/models.dart';
import 'package:bua/store.dart';

Food _food() => const Food(
  id: 'com_trang',
  name: 'Cơm trắng',
  category: 'rice',
  servingLabel: '1 bát',
  servingGrams: 200,
  kcal100: 130,
  protein100: 2.7,
  carb100: 28,
  fat100: 0.3,
);

Profile _profile({double weight = 65}) => Profile(
  name: 'Bảo',
  sex: Sex.male,
  age: 24,
  heightCm: 170,
  weightKg: weight,
  activity: Activity.moderate,
  goal: Goal.maintain,
  pace: 0,
);

void main() {
  group('hồ sơ và mục tiêu', () {
    test('TDEE và macro tính đúng công thức', () {
      final profile = _profile();
      expect(profile.bmr, closeTo(1597.5, 0.1));
      expect(profile.tdee, closeTo(2476.1, 0.2));
      expect(profile.targetKcal, 2476);

      final targets = profile.targets;
      expect(targets.proteinG, closeTo(2476 * 0.3 / 4, 0.01));
      expect(targets.carbG, closeTo(2476 * 0.4 / 4, 0.01));
      expect(targets.fatG, closeTo(2476 * 0.3 / 9, 0.01));
    });

    test('mục tiêu giảm cân bị chặn dưới mức tối thiểu', () {
      final profile = Profile(
        name: 'An',
        sex: Sex.female,
        age: 60,
        heightCm: 150,
        weightKg: 45,
        activity: Activity.sedentary,
        goal: Goal.lose,
        pace: 0.75,
      );
      expect(profile.targetKcal, greaterThanOrEqualTo(1200));
    });

    test('mục tiêu tay được ưu tiên', () {
      final profile = _profile().copyWith(manualKcal: 1800);
      expect(profile.targetKcal, 1800);
      expect(profile.targets.kcal, 1800);
    });
  });

  group('tìm kiếm tiếng Việt', () {
    const food = Food(
      id: 'pho_bo',
      name: 'Phở bò',
      category: 'soup',
      servingLabel: '1 tô',
      servingGrams: 500,
      kcal100: 90,
      protein100: 5.6,
      carb100: 11,
      fat100: 2.6,
    );

    test('bỏ dấu và so khớp chính xác', () {
      expect(normalizeVi('Phở bò'), 'pho bo');
      expect(foodMatchScore(food, 'pho bo'), 0);
      expect(foodMatchScore(food, 'pho'), 1);
      expect(foodMatchScore(food, 'bò'), isNotNull);
      expect(foodMatchScore(food, 'cơm'), isNull);
    });

    test('định dạng ngày ổn định', () {
      final date = DateTime(2026, 1, 5);
      expect(dateKey(date), '2026-01-05');
      expect(dateFromKey('2026-01-05'), date);
      expect(weekdayShort(date), 'T2');
    });
  });

  group('AppStore', () {
    late Directory dir;
    late AppStore store;

    setUp(() async {
      dir = await Directory.systemTemp.createTemp('bua_test_');
      store = AppStore(directory: dir, seedFoods: [_food()]);
      await store.load();
    });

    tearDown(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });

    test('hoàn tất onboarding lưu hồ sơ và cân nặng', () async {
      await store.completeOnboarding(_profile());
      expect(store.hasProfile, isTrue);
      expect(store.profile!.name, 'Bảo');
      expect(store.weights, hasLength(1));
      expect(File('${dir.path}/bua_data.json').existsSync(), isTrue);
    });

    test('thêm, sửa, xóa và tính tổng bữa', () async {
      await store.completeOnboarding(_profile());
      final entry = await store.addFood(
        food: _food(),
        date: store.todayKey,
        meal: MealType.lunch,
        grams: 200,
      );
      var totals = store.totalsFor(store.todayKey);
      expect(totals.kcal, closeTo(260, 0.001));
      expect(totals.protein, closeTo(5.4, 0.001));

      await store.updateEntry(entry.copyWith(grams: 100));
      totals = store.totalsFor(store.todayKey);
      expect(totals.kcal, closeTo(130, 0.001));

      final removed = await store.removeEntry(entry.id);
      expect(removed, isNotNull);
      expect(store.entriesFor(store.todayKey), isEmpty);
    });

    test('sao chép ngày và áp dụng bữa quen', () async {
      await store.completeOnboarding(_profile());
      final a = await store.addFood(
        food: _food(),
        date: store.todayKey,
        meal: MealType.lunch,
        grams: 200,
      );
      await store.addFood(
        food: _food(),
        date: store.todayKey,
        meal: MealType.dinner,
        grams: 100,
      );

      final tomorrow = dateKey(DateTime.now().add(const Duration(days: 1)));
      final copied = await store.copyDay(from: store.todayKey, to: tomorrow);
      expect(copied, 2);
      expect(store.entriesFor(tomorrow), hasLength(2));

      final combo = await store.saveComboFromEntries(
        name: 'Trưa của tôi',
        meal: MealType.lunch,
        entries: [a],
      );
      expect(combo, isNotNull);
      expect(store.combos, hasLength(1));
      expect(store.comboFoodTotals(combo!).kcal, closeTo(260, 0.001));

      final applied = await store.applyCombo(combo, tomorrow);
      expect(applied, 1);
      expect(store.entriesFor(tomorrow), hasLength(3));
    });

    test('nước bị giới hạn và lưu đúng ngày', () async {
      await store.completeOnboarding(_profile());
      await store.setWater(store.todayKey, 5);
      expect(store.waterFor(store.todayKey), 5);
      await store.setWater(store.todayKey, 99);
      expect(store.waterFor(store.todayKey), 30);
    });

    test('xuất rồi nhập lại giữ nguyên dữ liệu', () async {
      await store.completeOnboarding(_profile());
      await store.addFood(
        food: _food(),
        date: store.todayKey,
        meal: MealType.breakfast,
        grams: 200,
      );
      final raw = store.exportJson();

      await store.resetAll();
      expect(store.hasProfile, isFalse);
      expect(store.logs, isEmpty);

      await store.importJson(raw);
      expect(store.hasProfile, isTrue);
      expect(store.logs, hasLength(1));
      expect(store.totalsFor(store.todayKey).kcal, closeTo(260, 0.001));
    });

    test('tệp sao lưu sai bị từ chối', () async {
      expect(
        () => store.importJson('{"hello":"world"}'),
        throwsA(isA<FormatException>()),
      );
    });

    test('cân nặng mới được ghi và cập nhật hồ sơ', () async {
      await store.completeOnboarding(_profile());
      await store.addWeight(store.todayKey, 64.2);
      expect(store.latestWeight!.kg, 64.2);
      expect(store.profile!.weightKg, 64.2);
    });

    test('khôi phục từ .bak khi file chính bị mất', () async {
      await store.completeOnboarding(_profile());
      await store.addFood(
        food: _food(),
        date: store.todayKey,
        meal: MealType.lunch,
        grams: 200,
      );
      final main = File('${dir.path}${Platform.pathSeparator}bua_data.json');
      final backup = File('${main.path}.bak');
      expect(await main.exists(), isTrue);
      expect(await backup.exists(), isTrue);

      // Save once more so the .bak snapshot includes the logged food.
      await store.setWater(store.todayKey, 1);
      await main.delete();
      final restored = AppStore(directory: dir, seedFoods: [_food()]);
      await restored.load();
      expect(restored.hasProfile, isTrue);
      expect(restored.entriesFor(restored.todayKey), hasLength(1));
      expect(restored.loadWarning, isNotNull);
    });
  });
}
