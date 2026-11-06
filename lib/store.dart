import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;

import 'models.dart';

enum FoodFilter { recent, favorites, all, custom }

class DaySummary {
  final DateTime date;
  final DayTotals totals;
  const DaySummary(this.date, this.totals);

  String get key => dateKey(date);
}

class AppStore extends ChangeNotifier {
  AppStore({Directory? directory, List<Food>? seedFoods})
    : _directoryOverride = directory,
      _seedOverride = seedFoods;

  static const int dataVersion = 1;

  final Directory? _directoryOverride;
  final List<Food>? _seedOverride;

  Directory? _dir;
  File? _file;
  List<Food> _seedFoods = [];
  List<Food> _customFoods = [];
  List<LogEntry> _logs = [];
  List<Combo> _combos = [];
  List<WeightEntry> _weights = [];
  Map<String, int> _water = {};
  Set<String> _favorites = {};
  Profile? _profile;
  int _waterGoalCups = 8;
  DateTime? _lastSaved;
  String? _loadWarning;

  List<Food> get seedFoods => List.unmodifiable(_seedFoods);
  List<Food> get customFoods => List.unmodifiable(_customFoods);
  List<LogEntry> get logs => List.unmodifiable(_logs);
  List<Combo> get combos => List.unmodifiable(_combos);
  List<WeightEntry> get weights => List.unmodifiable(_weights);
  Profile? get profile => _profile;
  int get waterGoalCups => _waterGoalCups;
  DateTime? get lastSaved => _lastSaved;
  String? get loadWarning => _loadWarning;
  String? get dataFilePath => _file?.path;
  String? get backupDirectoryPath =>
      _dir == null ? null : '${_dir!.path}${Platform.pathSeparator}backups';
  bool get hasProfile => _profile != null;

  String get todayKey => dateKey(DateTime.now());

  List<Food> get allFoods {
    final list = [..._seedFoods, ..._customFoods];
    list.sort((a, b) => a.name.compareTo(b.name));
    return list;
  }

  Food? foodById(String id) {
    for (final f in _seedFoods) {
      if (f.id == id) return f;
    }
    for (final f in _customFoods) {
      if (f.id == id) return f;
    }
    return null;
  }

  Future<void> load() async {
    final dir = _directoryOverride ?? Directory.current;
    _dir = dir;
    _file = File('${dir.path}${Platform.pathSeparator}bua_data.json');

    if (_seedOverride != null) {
      _seedFoods = List.of(_seedOverride);
    } else {
      final raw = await rootBundle.loadString('assets/data/seed_foods.json');
      _seedFoods = (jsonDecode(raw) as List)
          .map((e) => Food.fromJson(e as Map<String, dynamic>))
          .toList();
    }

    final backup = File('${_file!.path}.bak');
    if (await _file!.exists()) {
      try {
        _applyJson(
          jsonDecode(await _file!.readAsString()) as Map<String, dynamic>,
        );
      } catch (_) {
        await _restoreFromBackup(backup);
      }
    } else if (await backup.exists()) {
      await _restoreFromBackup(backup);
    }

    _normalizeAll();
    notifyListeners();
  }

  Future<void> _restoreFromBackup(File backup) async {
    try {
      _applyJson(
        jsonDecode(await backup.readAsString()) as Map<String, dynamic>,
      );
      _loadWarning = 'Đã khôi phục từ bản sao lưu gần nhất.';
    } catch (_) {
      _loadWarning =
          'Không đọc được dữ liệu. Ứng dụng bắt đầu với dữ liệu trống.';
    }
  }

  void _normalizeAll() {
    _logs.sort((a, b) {
      final byDate = a.date.compareTo(b.date);
      return byDate != 0 ? byDate : a.createdAt.compareTo(b.createdAt);
    });
    _weights.sort((a, b) => a.date.compareTo(b.date));
  }

  void _applyJson(Map<String, dynamic> json) {
    _profile = json['profile'] == null
        ? null
        : Profile.fromJson(json['profile'] as Map<String, dynamic>);
    _logs = (json['logs'] as List? ?? [])
        .map((e) => LogEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    _customFoods = (json['customFoods'] as List? ?? [])
        .map((e) => Food.fromJson(e as Map<String, dynamic>))
        .toList();
    _combos = (json['combos'] as List? ?? [])
        .map((e) => Combo.fromJson(e as Map<String, dynamic>))
        .toList();
    _weights = (json['weights'] as List? ?? [])
        .map((e) => WeightEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    _water = (json['water'] as Map? ?? {}).map(
      (key, value) => MapEntry(key.toString(), (value as num).toInt()),
    );
    _favorites = (json['favorites'] as List? ?? [])
        .map((e) => e.toString())
        .toSet();
    _waterGoalCups = (json['waterGoalCups'] as num?)?.toInt() ?? 8;
  }

  Map<String, dynamic> toJson() => {
    'version': dataVersion,
    'profile': _profile?.toJson(),
    'logs': _logs.map((e) => e.toJson()).toList(),
    'customFoods': _customFoods.map((e) => e.toJson()).toList(),
    'combos': _combos.map((e) => e.toJson()).toList(),
    'weights': _weights.map((e) => e.toJson()).toList(),
    'water': _water,
    'favorites': _favorites.toList(),
    'waterGoalCups': _waterGoalCups,
  };

  Future<void> _save() async {
    final file = _file;
    final dir = _dir;
    if (file == null || dir == null) return;

    final payload = const JsonEncoder.withIndent('  ').convert(toJson());
    final tmp = File('${file.path}.tmp');
    await tmp.writeAsString(payload, flush: true);

    if (await file.exists()) {
      await file.copy('${file.path}.bak');
      await file.delete();
    }
    await tmp.rename(file.path);

    await _dailyBackup(payload, dir);
    _lastSaved = DateTime.now();
    notifyListeners();
  }

  Future<void> _dailyBackup(String payload, Directory dir) async {
    try {
      final folder = Directory('${dir.path}${Platform.pathSeparator}backups');
      if (!await folder.exists()) await folder.create(recursive: true);
      final file = File(
        '${folder.path}${Platform.pathSeparator}bua-$todayKey.json',
      );
      if (!await file.exists()) await file.writeAsString(payload, flush: true);

      final files = await folder
          .list()
          .where((e) => e is File && e.path.endsWith('.json'))
          .cast<File>()
          .toList();
      files.sort((a, b) => a.path.compareTo(b.path));
      while (files.length > 7) {
        await files.removeAt(0).delete();
      }
    } catch (_) {
      // Backup is best-effort; the primary save already succeeded.
    }
  }

  // ---------- profile ----------

  Future<void> completeOnboarding(Profile profile) async {
    _profile = profile;
    final key = todayKey;
    _weights.removeWhere((w) => w.date == key);
    _weights.add(WeightEntry(date: key, kg: profile.weightKg));
    _normalizeAll();
    await _save();
  }

  Future<void> updateProfile(Profile next) async {
    final previous = _profile;
    _profile = next;
    if (previous == null || (previous.weightKg - next.weightKg).abs() > 0.05) {
      final key = todayKey;
      _weights.removeWhere((w) => w.date == key);
      _weights.add(WeightEntry(date: key, kg: next.weightKg));
      _normalizeAll();
    }
    await _save();
  }

  // ---------- food logging ----------

  List<LogEntry> entriesFor(String date) {
    final list = _logs.where((e) => e.date == date).toList()
      ..sort((a, b) {
        final byMeal = a.meal.order.compareTo(b.meal.order);
        return byMeal != 0 ? byMeal : a.createdAt.compareTo(b.createdAt);
      });
    return list;
  }

  List<LogEntry> entriesForMeal(String date, MealType meal) =>
      entriesFor(date).where((e) => e.meal == meal).toList();

  DayTotals totalsFor(String date) =>
      DayTotals.fromEntries(_logs.where((e) => e.date == date));

  DayTotals get todayTotals => totalsFor(todayKey);

  Future<LogEntry> addFood({
    required Food food,
    required String date,
    required MealType meal,
    required double grams,
  }) async {
    final entry = LogEntry(
      id: newId(),
      date: date,
      meal: meal,
      foodId: food.id,
      name: food.name,
      grams: grams,
      kcal100: food.kcal100,
      protein100: food.protein100,
      carb100: food.carb100,
      fat100: food.fat100,
      createdAt: DateTime.now().millisecondsSinceEpoch,
    );
    _logs.add(entry);
    _normalizeAll();
    await _save();
    return entry;
  }

  Future<void> updateEntry(LogEntry entry) async {
    final index = _logs.indexWhere((e) => e.id == entry.id);
    if (index < 0) return;
    _logs[index] = entry;
    _normalizeAll();
    await _save();
  }

  Future<LogEntry?> removeEntry(String id) async {
    final index = _logs.indexWhere((e) => e.id == id);
    if (index < 0) return null;
    final removed = _logs.removeAt(index);
    await _save();
    return removed;
  }

  Future<void> restoreEntry(LogEntry entry) async {
    _logs.add(entry);
    _normalizeAll();
    await _save();
  }

  Future<int> copyDay({required String from, required String to}) async {
    final source = entriesFor(from);
    if (source.isEmpty) return 0;
    _logs.removeWhere((e) => e.date == to);
    final base = DateTime.now().millisecondsSinceEpoch;
    for (var i = 0; i < source.length; i++) {
      final e = source[i];
      _logs.add(
        LogEntry(
          id: newId(),
          date: to,
          meal: e.meal,
          foodId: e.foodId,
          name: e.name,
          grams: e.grams,
          kcal100: e.kcal100,
          protein100: e.protein100,
          carb100: e.carb100,
          fat100: e.fat100,
          createdAt: base + i,
        ),
      );
    }
    _normalizeAll();
    await _save();
    return source.length;
  }

  // ---------- water ----------

  int waterFor(String date) => _water[date] ?? 0;

  Future<void> setWater(String date, int cups) async {
    _water[date] = cups.clamp(0, 30).toInt();
    await _save();
  }

  Future<void> setWaterGoal(int cups) async {
    _waterGoalCups = cups.clamp(4, 20).toInt();
    await _save();
  }

  // ---------- favorites ----------

  bool isFavorite(String foodId) => _favorites.contains(foodId);

  Future<void> toggleFavorite(String foodId) async {
    if (!_favorites.remove(foodId)) _favorites.add(foodId);
    await _save();
  }

  List<Food> get favoriteFoods =>
      allFoods.where((f) => _favorites.contains(f.id)).toList();

  List<Food> get recentFoods {
    final seen = <String>{};
    final result = <Food>[];
    final sorted = [..._logs]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    for (final entry in sorted) {
      if (!seen.add(entry.foodId)) continue;
      final food = foodById(entry.foodId);
      if (food != null) result.add(food);
      if (result.length >= 15) break;
    }
    return result;
  }

  List<Food> searchFoods(String query, FoodFilter filter) {
    final source = switch (filter) {
      FoodFilter.recent => recentFoods,
      FoodFilter.favorites => favoriteFoods,
      FoodFilter.all => allFoods,
      FoodFilter.custom => _customFoods,
    };

    if (query.trim().isEmpty) {
      return List.of(source);
    }

    final scored = <(int, Food)>[];
    for (final food in source) {
      final score = foodMatchScore(food, query);
      if (score != null) scored.add((score, food));
    }
    scored.sort((a, b) {
      final byScore = a.$1.compareTo(b.$1);
      return byScore != 0 ? byScore : a.$2.name.compareTo(b.$2.name);
    });
    return scored.map((e) => e.$2).toList();
  }

  // ---------- custom foods ----------

  Future<void> addCustomFood(Food food) async {
    _customFoods.add(food);
    await _save();
  }

  Future<void> deleteCustomFood(String id) async {
    _customFoods.removeWhere((f) => f.id == id);
    _favorites.remove(id);
    await _save();
  }

  // ---------- combos ----------

  Future<Combo?> saveComboFromEntries({
    required String name,
    required MealType meal,
    required List<LogEntry> entries,
  }) async {
    if (entries.isEmpty) return null;
    final combo = Combo(
      id: newId(),
      name: name.trim(),
      meal: meal,
      items: entries
          .map((e) => ComboItem(foodId: e.foodId, grams: e.grams))
          .toList(),
    );
    _combos.add(combo);
    await _save();
    return combo;
  }

  Future<void> deleteCombo(String id) async {
    _combos.removeWhere((c) => c.id == id);
    await _save();
  }

  DayTotals comboFoodTotals(Combo combo) {
    var totals = const DayTotals();
    for (final item in combo.items) {
      final food = foodById(item.foodId);
      if (food == null) continue;
      totals =
          totals +
          DayTotals(
            kcal: food.kcal100 * item.grams / 100,
            protein: food.protein100 * item.grams / 100,
            carb: food.carb100 * item.grams / 100,
            fat: food.fat100 * item.grams / 100,
          );
    }
    return totals;
  }

  Future<int> applyCombo(Combo combo, String date) async {
    var added = 0;
    final base = DateTime.now().millisecondsSinceEpoch;
    for (final item in combo.items) {
      final food = foodById(item.foodId);
      if (food == null) continue;
      _logs.add(
        LogEntry(
          id: newId(),
          date: date,
          meal: combo.meal,
          foodId: food.id,
          name: food.name,
          grams: item.grams,
          kcal100: food.kcal100,
          protein100: food.protein100,
          carb100: food.carb100,
          fat100: food.fat100,
          createdAt: base + added,
        ),
      );
      added++;
    }
    if (added > 0) {
      _normalizeAll();
      await _save();
    }
    return added;
  }

  // ---------- weight & progress ----------

  Future<void> addWeight(String date, double kg) async {
    _weights.removeWhere((w) => w.date == date);
    _weights.add(WeightEntry(date: date, kg: kg));
    _normalizeAll();
    final latest = _weights.isNotEmpty ? _weights.last : null;
    if (latest != null && _profile != null) {
      _profile = _profile!.copyWith(weightKg: latest.kg);
    }
    await _save();
  }

  WeightEntry? get latestWeight => _weights.isEmpty ? null : _weights.last;

  List<WeightEntry> get weightSeries => List.of(_weights);

  double? get weightDelta {
    if (_weights.length < 2) return null;
    return _weights.last.kg - _weights[_weights.length - 2].kg;
  }

  List<DaySummary> get lastSevenDays {
    final today = dateOnly(DateTime.now());
    return List.generate(7, (index) {
      final day = today.subtract(Duration(days: 6 - index));
      final key = dateKey(day);
      return DaySummary(day, totalsFor(key));
    });
  }

  double? get averageKcalLastSeven {
    final days = lastSevenDays
        .where((d) => d.key != todayKey && d.totals.kcal > 0)
        .toList();
    if (days.isEmpty) return null;
    return days.fold<double>(0, (sum, d) => sum + d.totals.kcal) / days.length;
  }

  double? get averageProteinLastSeven {
    final days = lastSevenDays
        .where((d) => d.key != todayKey && d.totals.kcal > 0)
        .toList();
    if (days.isEmpty) return null;
    return days.fold<double>(0, (sum, d) => sum + d.totals.protein) /
        days.length;
  }

  int get loggedDayCount => _logs.map((e) => e.date).toSet().length;

  int get streak {
    final dates = _logs.map((e) => e.date).toSet();
    var day = dateOnly(DateTime.now());
    if (!dates.contains(dateKey(day))) {
      day = day.subtract(const Duration(days: 1));
    }
    var count = 0;
    while (dates.contains(dateKey(day)) && count < 3650) {
      count++;
      day = day.subtract(const Duration(days: 1));
    }
    return count;
  }

  // ---------- backup ----------

  String exportJson() => const JsonEncoder.withIndent('  ').convert(toJson());

  Future<File> writeExportFile() async {
    final dir = _dir ?? Directory.current;
    final now = DateTime.now();
    final stamp =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}-'
        '${now.hour.toString().padLeft(2, '0')}${now.minute.toString().padLeft(2, '0')}';
    final file = File(
      '${dir.path}${Platform.pathSeparator}trackcalo-backup-$stamp.json',
    );
    await file.writeAsString(exportJson(), flush: true);
    return file;
  }

  Future<void> importJson(String raw) async {
    final data = jsonDecode(raw);
    if (data is! Map<String, dynamic>) {
      throw const FormatException('Tệp sao lưu không hợp lệ.');
    }
    if (data['profile'] == null && data['logs'] == null) {
      throw const FormatException('Tệp sao lưu thiếu dữ liệu Track Calo.');
    }
    _applyJson(data);
    _normalizeAll();
    await _save();
  }

  Future<void> resetAll() async {
    _profile = null;
    _logs = [];
    _customFoods = [];
    _combos = [];
    _weights = [];
    _water = {};
    _favorites = {};
    _waterGoalCups = 8;
    await _save();
  }
}
