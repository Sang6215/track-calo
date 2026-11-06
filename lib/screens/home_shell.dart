import 'package:flutter/material.dart';

import '../models.dart';
import '../store.dart';
import '../widgets.dart';
import 'add_food_page.dart';
import 'diary_page.dart';
import 'progress_page.dart';
import 'settings_page.dart';
import 'today_page.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key, required this.store});

  final AppStore store;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  Future<void> _openAdd({String? date, MealType? meal}) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddFoodPage(
          store: widget.store,
          date: date ?? widget.store.todayKey,
          initialMeal: meal ?? mealForNow(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: [
          TodayPage(
            store: widget.store,
            onAdd: (meal) => _openAdd(meal: meal),
            onOpenDiary: () => setState(() => _index = 1),
            onOpenSettings: () => setState(() => _index = 3),
          ),
          DiaryPage(
            store: widget.store,
            onAdd: (date, meal) => _openAdd(date: date, meal: meal),
          ),
          ProgressPage(store: widget.store),
          SettingsPage(store: widget.store),
        ],
      ),
      bottomNavigationBar: BuaBottomBar(
        index: _index,
        onSelect: (value) => setState(() => _index = value),
        onAdd: () => _openAdd(),
      ),
    );
  }
}
