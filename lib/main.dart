import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'state/providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 관심 목록과 정렬 기준을 `Notifier.build()`(동기)에서 바로 읽을 수 있도록,
  // 앱을 띄우기 전에 한 번 받아 두고 주입합니다. 첫 프레임부터 저장된 목록이
  // 보이기 때문에 목록이 비었다가 채워지는 깜빡임이 없습니다.
  final SharedPreferences preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const EdencrewAssignmentApp(),
    ),
  );
}
