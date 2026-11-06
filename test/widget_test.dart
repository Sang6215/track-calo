import 'dart:io';
import 'dart:ui' show Size;

import 'package:flutter_test/flutter_test.dart';

import 'package:bua/main.dart';
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

Profile _profile() => const Profile(
  name: 'Bảo',
  sex: Sex.male,
  age: 24,
  heightCm: 170,
  weightKg: 65,
  activity: Activity.moderate,
  goal: Goal.maintain,
  pace: 0,
);

Future<(AppStore, Directory)> _makeStore(
  WidgetTester tester, {
  bool withProfile = false,
}) async {
  late AppStore store;
  late Directory dir;
  await tester.runAsync(() async {
    dir = await Directory.systemTemp.createTemp('bua_widget_');
    store = AppStore(directory: dir, seedFoods: [_food()]);
    await store.load();
    if (withProfile) {
      await store.completeOnboarding(_profile());
    }
  });
  return (store, dir);
}

void main() {
  testWidgets('onboarding hiển thị bước đầu', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final (store, dir) = await _makeStore(tester);

    await tester.pumpWidget(BuaApp(store: store));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Cho Track Calo biết'), findsOneWidget);
    expect(find.text('Tiếp tục'), findsOneWidget);

    await tester.runAsync(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
  });

  testWidgets('màn Hôm nay hiển thị sau khi có hồ sơ', (tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final (store, dir) = await _makeStore(tester, withProfile: true);

    await tester.pumpWidget(BuaApp(store: store));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.text('Chào Bảo,'), findsOneWidget);
    expect(find.text('Bữa hôm nay'), findsOneWidget);
    expect(find.text('Hôm nay'), findsWidgets);
    expect(find.text('Nhật ký'), findsWidgets);
    expect(find.text('Tiến độ'), findsWidgets);
    expect(find.text('Tôi'), findsWidgets);

    await tester.runAsync(() async {
      if (await dir.exists()) await dir.delete(recursive: true);
    });
  });
}
