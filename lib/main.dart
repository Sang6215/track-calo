import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'screens/home_shell.dart';
import 'screens/onboarding_page.dart';
import 'store.dart';
import 'theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: BuaColors.paper,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  final directory = await getApplicationDocumentsDirectory();
  final store = AppStore(directory: directory);
  await store.load();
  runApp(BuaApp(store: store));
}

class BuaApp extends StatelessWidget {
  const BuaApp({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Track Calo',
      debugShowCheckedModeBanner: false,
      theme: buildBuaTheme(),
      home: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          if (!store.hasProfile) return OnboardingPage(store: store);
          return HomeShell(store: store);
        },
      ),
    );
  }
}
