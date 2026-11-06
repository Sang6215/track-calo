import 'dart:math' as math;

enum Sex { male, female }

extension SexX on Sex {
  String get label => this == Sex.male ? 'Nam' : 'Nữ';
}

enum Activity { sedentary, light, moderate, active, veryActive }

extension ActivityX on Activity {
  String get label => switch (this) {
    Activity.sedentary => 'Ít vận động',
    Activity.light => 'Vận động nhẹ',
    Activity.moderate => 'Vận động vừa',
    Activity.active => 'Vận động nhiều',
    Activity.veryActive => 'Rất năng động',
  };

  String get hint => switch (this) {
    Activity.sedentary => 'Ngồi nhiều, hầu như không tập',
    Activity.light => 'Đi bộ nhẹ, tập 1–2 buổi/tuần',
    Activity.moderate => 'Tập 3–4 buổi/tuần',
    Activity.active => 'Tập 5–6 buổi/tuần',
    Activity.veryActive => 'Lao động nặng hoặc tập 2 lần/ngày',
  };

  double get factor => switch (this) {
    Activity.sedentary => 1.2,
    Activity.light => 1.375,
    Activity.moderate => 1.55,
    Activity.active => 1.725,
    Activity.veryActive => 1.9,
  };
}

enum Goal { lose, maintain, gain }

extension GoalX on Goal {
  String get label => switch (this) {
    Goal.lose => 'Giảm cân',
    Goal.maintain => 'Giữ cân',
    Goal.gain => 'Tăng cân',
  };

  String get hint => switch (this) {
    Goal.lose => 'Thâm hụt nhẹ, giữ cơ',
    Goal.maintain => 'Ăn quanh mức TDEE',
    Goal.gain => 'Thặng dư nhẹ, tăng cơ',
  };
}

enum MealType { breakfast, lunch, dinner, snack }

extension MealTypeX on MealType {
  String get label => switch (this) {
    MealType.breakfast => 'Sáng',
    MealType.lunch => 'Trưa',
    MealType.dinner => 'Tối',
    MealType.snack => 'Bữa phụ',
  };

  String get labelLong => switch (this) {
    MealType.breakfast => 'Bữa sáng',
    MealType.lunch => 'Bữa trưa',
    MealType.dinner => 'Bữa tối',
    MealType.snack => 'Bữa phụ',
  };

  int get order => switch (this) {
    MealType.breakfast => 0,
    MealType.lunch => 1,
    MealType.dinner => 2,
    MealType.snack => 3,
  };
}

MealType mealForNow() {
  final h = DateTime.now().hour;
  if (h < 10) return MealType.breakfast;
  if (h < 14) return MealType.lunch;
  if (h < 17) return MealType.snack;
  if (h < 21) return MealType.dinner;
  return MealType.snack;
}

enum WeightUnit { kg }

const foodCategories = <String>[
  'soup',
  'rice',
  'bread',
  'protein',
  'veg',
  'fruit',
  'drink',
  'snack',
  'staple',
];

String categoryLabel(String category) => switch (category) {
  'soup' => 'Món nước',
  'rice' => 'Cơm & bún',
  'bread' => 'Bánh',
  'protein' => 'Đạm',
  'veg' => 'Rau & canh',
  'fruit' => 'Trái cây',
  'drink' => 'Đồ uống',
  'snack' => 'Ăn vặt',
  'staple' => 'Tinh bột',
  _ => 'Khác',
};

class Food {
  final String id;
  final String name;
  final String category;
  final String servingLabel;
  final double servingGrams;
  final double kcal100;
  final double protein100;
  final double carb100;
  final double fat100;
  final bool custom;

  const Food({
    required this.id,
    required this.name,
    required this.category,
    required this.servingLabel,
    required this.servingGrams,
    required this.kcal100,
    required this.protein100,
    required this.carb100,
    required this.fat100,
    this.custom = false,
  });

  double get kcalPerServing => kcal100 * servingGrams / 100;
  double get proteinPerServing => protein100 * servingGrams / 100;
  double get carbPerServing => carb100 * servingGrams / 100;
  double get fatPerServing => fat100 * servingGrams / 100;

  String get searchText => normalizeVi(name);

  factory Food.fromJson(Map<String, dynamic> json) => Food(
    id: json['id'] as String,
    name: json['name'] as String,
    category: (json['cat'] ?? json['category'] ?? 'protein') as String,
    servingLabel: (json['unit'] ?? json['servingLabel'] ?? '1 phần') as String,
    servingGrams: ((json['grams'] ?? json['servingGrams']) as num).toDouble(),
    kcal100: ((json['kcal'] ?? json['kcal100']) as num).toDouble(),
    protein100: ((json['p'] ?? json['protein100']) as num).toDouble(),
    carb100: ((json['c'] ?? json['carb100']) as num).toDouble(),
    fat100: ((json['f'] ?? json['fat100']) as num).toDouble(),
    custom: (json['custom'] as bool?) ?? false,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'cat': category,
    'unit': servingLabel,
    'grams': servingGrams,
    'kcal': kcal100,
    'p': protein100,
    'c': carb100,
    'f': fat100,
    'custom': custom,
  };

  Food copyWith({
    String? name,
    String? category,
    String? servingLabel,
    double? servingGrams,
    double? kcal100,
    double? protein100,
    double? carb100,
    double? fat100,
  }) => Food(
    id: id,
    name: name ?? this.name,
    category: category ?? this.category,
    servingLabel: servingLabel ?? this.servingLabel,
    servingGrams: servingGrams ?? this.servingGrams,
    kcal100: kcal100 ?? this.kcal100,
    protein100: protein100 ?? this.protein100,
    carb100: carb100 ?? this.carb100,
    fat100: fat100 ?? this.fat100,
    custom: custom,
  );
}

class LogEntry {
  final String id;
  final String date;
  final MealType meal;
  final String foodId;
  final String name;
  final double grams;
  final double kcal100;
  final double protein100;
  final double carb100;
  final double fat100;
  final int createdAt;

  const LogEntry({
    required this.id,
    required this.date,
    required this.meal,
    required this.foodId,
    required this.name,
    required this.grams,
    required this.kcal100,
    required this.protein100,
    required this.carb100,
    required this.fat100,
    required this.createdAt,
  });

  double get kcal => kcal100 * grams / 100;
  double get protein => protein100 * grams / 100;
  double get carb => carb100 * grams / 100;
  double get fat => fat100 * grams / 100;

  LogEntry copyWith({
    String? date,
    MealType? meal,
    double? grams,
    int? createdAt,
  }) => LogEntry(
    id: id,
    date: date ?? this.date,
    meal: meal ?? this.meal,
    foodId: foodId,
    name: name,
    grams: grams ?? this.grams,
    kcal100: kcal100,
    protein100: protein100,
    carb100: carb100,
    fat100: fat100,
    createdAt: createdAt ?? this.createdAt,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'meal': meal.name,
    'foodId': foodId,
    'name': name,
    'grams': grams,
    'kcal100': kcal100,
    'p100': protein100,
    'c100': carb100,
    'f100': fat100,
    'createdAt': createdAt,
  };

  factory LogEntry.fromJson(Map<String, dynamic> json) => LogEntry(
    id: json['id'] as String,
    date: json['date'] as String,
    meal: MealType.values.byName(json['meal'] as String),
    foodId: json['foodId'] as String,
    name: json['name'] as String,
    grams: (json['grams'] as num).toDouble(),
    kcal100: (json['kcal100'] as num).toDouble(),
    protein100: (json['p100'] as num).toDouble(),
    carb100: (json['c100'] as num).toDouble(),
    fat100: (json['f100'] as num).toDouble(),
    createdAt: (json['createdAt'] as num).toInt(),
  );
}

class ComboItem {
  final String foodId;
  final double grams;

  const ComboItem({required this.foodId, required this.grams});

  Map<String, dynamic> toJson() => {'foodId': foodId, 'grams': grams};

  factory ComboItem.fromJson(Map<String, dynamic> json) => ComboItem(
    foodId: json['foodId'] as String,
    grams: (json['grams'] as num).toDouble(),
  );
}

class Combo {
  final String id;
  final String name;
  final MealType meal;
  final List<ComboItem> items;

  const Combo({
    required this.id,
    required this.name,
    required this.meal,
    required this.items,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'meal': meal.name,
    'items': items.map((e) => e.toJson()).toList(),
  };

  factory Combo.fromJson(Map<String, dynamic> json) => Combo(
    id: json['id'] as String,
    name: json['name'] as String,
    meal: MealType.values.byName(json['meal'] as String),
    items: (json['items'] as List)
        .map((e) => ComboItem.fromJson(e as Map<String, dynamic>))
        .toList(),
  );
}

class WeightEntry {
  final String date;
  final double kg;

  const WeightEntry({required this.date, required this.kg});

  Map<String, dynamic> toJson() => {'date': date, 'kg': kg};

  factory WeightEntry.fromJson(Map<String, dynamic> json) => WeightEntry(
    date: json['date'] as String,
    kg: (json['kg'] as num).toDouble(),
  );
}

class Profile {
  final String name;
  final Sex sex;
  final int age;
  final double heightCm;
  final double weightKg;
  final Activity activity;
  final Goal goal;
  final double pace;
  final double? targetWeightKg;
  final int? manualKcal;
  final int proteinPct;
  final int carbPct;
  final int fatPct;

  const Profile({
    required this.name,
    required this.sex,
    required this.age,
    required this.heightCm,
    required this.weightKg,
    required this.activity,
    required this.goal,
    required this.pace,
    this.targetWeightKg,
    this.manualKcal,
    this.proteinPct = 30,
    this.carbPct = 40,
    this.fatPct = 30,
  });

  double get bmr =>
      10 * weightKg + 6.25 * heightCm - 5 * age + (sex == Sex.male ? 5 : -161);

  double get tdee => bmr * activity.factor;

  double get goalDelta {
    if (goal == Goal.maintain) return 0;
    final weekly = pace * 7700 / 7;
    return goal == Goal.lose ? -weekly : weekly;
  }

  int get calculatedKcal {
    final floor = sex == Sex.male ? 1500.0 : 1200.0;
    return math.max(floor, tdee + goalDelta).round();
  }

  int get targetKcal => manualKcal ?? calculatedKcal;

  NutritionTargets get targets => NutritionTargets(
    kcal: targetKcal.toDouble(),
    proteinG: targetKcal * proteinPct / 100 / 4,
    carbG: targetKcal * carbPct / 100 / 4,
    fatG: targetKcal * fatPct / 100 / 9,
  );

  Profile copyWith({
    String? name,
    Sex? sex,
    int? age,
    double? heightCm,
    double? weightKg,
    Activity? activity,
    Goal? goal,
    double? pace,
    double? targetWeightKg,
    bool clearTargetWeight = false,
    int? manualKcal,
    bool clearManualKcal = false,
    int? proteinPct,
    int? carbPct,
    int? fatPct,
  }) => Profile(
    name: name ?? this.name,
    sex: sex ?? this.sex,
    age: age ?? this.age,
    heightCm: heightCm ?? this.heightCm,
    weightKg: weightKg ?? this.weightKg,
    activity: activity ?? this.activity,
    goal: goal ?? this.goal,
    pace: pace ?? this.pace,
    targetWeightKg: clearTargetWeight
        ? null
        : (targetWeightKg ?? this.targetWeightKg),
    manualKcal: clearManualKcal ? null : (manualKcal ?? this.manualKcal),
    proteinPct: proteinPct ?? this.proteinPct,
    carbPct: carbPct ?? this.carbPct,
    fatPct: fatPct ?? this.fatPct,
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    'sex': sex.name,
    'age': age,
    'heightCm': heightCm,
    'weightKg': weightKg,
    'activity': activity.name,
    'goal': goal.name,
    'pace': pace,
    'targetWeightKg': targetWeightKg,
    'manualKcal': manualKcal,
    'proteinPct': proteinPct,
    'carbPct': carbPct,
    'fatPct': fatPct,
  };

  factory Profile.fromJson(Map<String, dynamic> json) => Profile(
    name: (json['name'] as String?) ?? '',
    sex: Sex.values.byName(json['sex'] as String),
    age: (json['age'] as num).toInt(),
    heightCm: (json['heightCm'] as num).toDouble(),
    weightKg: (json['weightKg'] as num).toDouble(),
    activity: Activity.values.byName(json['activity'] as String),
    goal: Goal.values.byName(json['goal'] as String),
    pace: (json['pace'] as num?)?.toDouble() ?? 0.5,
    targetWeightKg: (json['targetWeightKg'] as num?)?.toDouble(),
    manualKcal: (json['manualKcal'] as num?)?.toInt(),
    proteinPct: (json['proteinPct'] as num?)?.toInt() ?? 30,
    carbPct: (json['carbPct'] as num?)?.toInt() ?? 40,
    fatPct: (json['fatPct'] as num?)?.toInt() ?? 30,
  );
}

class NutritionTargets {
  final double kcal;
  final double proteinG;
  final double carbG;
  final double fatG;

  const NutritionTargets({
    required this.kcal,
    required this.proteinG,
    required this.carbG,
    required this.fatG,
  });
}

class DayTotals {
  final double kcal;
  final double protein;
  final double carb;
  final double fat;

  const DayTotals({
    this.kcal = 0,
    this.protein = 0,
    this.carb = 0,
    this.fat = 0,
  });

  factory DayTotals.fromEntries(Iterable<LogEntry> entries) {
    var kcal = 0.0, protein = 0.0, carb = 0.0, fat = 0.0;
    for (final e in entries) {
      kcal += e.kcal;
      protein += e.protein;
      carb += e.carb;
      fat += e.fat;
    }
    return DayTotals(kcal: kcal, protein: protein, carb: carb, fat: fat);
  }

  DayTotals operator +(DayTotals other) => DayTotals(
    kcal: kcal + other.kcal,
    protein: protein + other.protein,
    carb: carb + other.carb,
    fat: fat + other.fat,
  );
}

// ---------- date helpers ----------

String dateKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

DateTime dateFromKey(String key) {
  final parts = key.split('-');
  return DateTime(
    int.parse(parts[0]),
    int.parse(parts[1]),
    int.parse(parts[2]),
  );
}

DateTime dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

String weekdayName(DateTime d) {
  const names = [
    'Thứ Hai',
    'Thứ Ba',
    'Thứ Tư',
    'Thứ Năm',
    'Thứ Sáu',
    'Thứ Bảy',
    'Chủ Nhật',
  ];
  return names[d.weekday - 1];
}

String weekdayShort(DateTime d) {
  const names = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];
  return names[d.weekday - 1];
}

String shortDate(DateTime d) => '${d.day}/${d.month}';

String longDate(DateTime d) => '${weekdayName(d)} · ${shortDate(d)}';

String friendlyDay(DateTime d) {
  final now = dateOnly(DateTime.now());
  final target = dateOnly(d);
  final diff = now.difference(target).inDays;
  if (diff == 0) return 'Hôm nay';
  if (diff == 1) return 'Hôm qua';
  return '${weekdayShort(d)} · ${shortDate(d)}';
}

String greetingForNow() {
  final h = DateTime.now().hour;
  if (h < 11) return 'Chào buổi sáng';
  if (h < 14) return 'Chào buổi trưa';
  if (h < 18) return 'Chào buổi chiều';
  return 'Chào buổi tối';
}

// ---------- format helpers ----------

String fmtNum(double value, {int decimals = 0}) {
  if (decimals == 0) return value.round().toString();
  return value.toStringAsFixed(decimals).replaceAll('.', ',');
}

String fmtKcal(double value) => fmtNum(value);

String fmtGram(double value) => value >= 100
    ? fmtNum(value)
    : fmtNum(value, decimals: value % 1 == 0 ? 0 : 1);

String fmtKg(double value) => fmtNum(value, decimals: 1);

String newId() =>
    '${DateTime.now().microsecondsSinceEpoch}-${math.Random().nextInt(1 << 20)}';

// ---------- Vietnamese search ----------

const Map<String, String> _viMap = {
  'à': 'a',
  'á': 'a',
  'ạ': 'a',
  'ả': 'a',
  'ã': 'a',
  'â': 'a',
  'ầ': 'a',
  'ấ': 'a',
  'ậ': 'a',
  'ẩ': 'a',
  'ẫ': 'a',
  'ă': 'a',
  'ằ': 'a',
  'ắ': 'a',
  'ặ': 'a',
  'ẳ': 'a',
  'ẵ': 'a',
  'è': 'e',
  'é': 'e',
  'ẹ': 'e',
  'ẻ': 'e',
  'ẽ': 'e',
  'ê': 'e',
  'ề': 'e',
  'ế': 'e',
  'ệ': 'e',
  'ể': 'e',
  'ễ': 'e',
  'ì': 'i',
  'í': 'i',
  'ị': 'i',
  'ỉ': 'i',
  'ĩ': 'i',
  'ò': 'o',
  'ó': 'o',
  'ọ': 'o',
  'ỏ': 'o',
  'õ': 'o',
  'ô': 'o',
  'ồ': 'o',
  'ố': 'o',
  'ộ': 'o',
  'ổ': 'o',
  'ỗ': 'o',
  'ơ': 'o',
  'ờ': 'o',
  'ớ': 'o',
  'ợ': 'o',
  'ở': 'o',
  'ỡ': 'o',
  'ù': 'u',
  'ú': 'u',
  'ụ': 'u',
  'ủ': 'u',
  'ũ': 'u',
  'ư': 'u',
  'ừ': 'u',
  'ứ': 'u',
  'ự': 'u',
  'ử': 'u',
  'ữ': 'u',
  'ỳ': 'y',
  'ý': 'y',
  'ỵ': 'y',
  'ỷ': 'y',
  'ỹ': 'y',
  'đ': 'd',
};

String normalizeVi(String input) {
  final lower = input.toLowerCase();
  final buffer = StringBuffer();
  for (final rune in lower.runes) {
    final ch = String.fromCharCode(rune);
    buffer.write(_viMap[ch] ?? ch);
  }
  return buffer
      .toString()
      .replaceAll(RegExp(r'[^a-z0-9\s]'), ' ')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();
}

int? foodMatchScore(Food food, String query) {
  final q = normalizeVi(query);
  if (q.isEmpty) return 0;
  final name = food.searchText;
  if (name == q) return 0;
  if (name.startsWith(q)) return 1;
  final index = name.indexOf(q);
  if (index >= 0) return index < 6 ? 2 : 3;
  final words = q.split(' ').where((w) => w.isNotEmpty);
  if (words.isNotEmpty && words.every(name.contains)) return 4;
  return null;
}
