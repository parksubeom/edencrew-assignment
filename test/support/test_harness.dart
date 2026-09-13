import 'dart:io';

import 'package:edencrew_assignment_starter/data/naver_http_client.dart';
import 'package:edencrew_assignment_starter/domain/stock_ref.dart';
import 'package:edencrew_assignment_starter/state/favorites_provider.dart';
import 'package:edencrew_assignment_starter/state/providers.dart';
import 'package:edencrew_assignment_starter/theme/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'mock_naver_client.dart';

/// 시안 기준 프레임 크기입니다. 화면을 이 크기로 띄워 확인합니다.
const Size kFrameSize = Size(393, 852);

/// 위젯 테스트 준비를 한 번에 끝냅니다. `setUpAll(initTestEnvironment)`로 씁니다.
///
/// 폰트와 mock 응답을 **테스트 본문 밖에서** 읽어 둡니다. 테스트 본문은
/// 가짜 시계 안에서 돌기 때문에, 그 안에서 파일을 읽으면 Future가 끝나지
/// 않고 멈춥니다.
Future<void> initTestEnvironment() async {
  await loadAppFonts();
  await NaverFixtures.load();
}

/// 테스트에서 실제 서체로 글자를 그리기 위해 폰트를 등록합니다.
///
/// 등록하지 않으면 flutter_test의 기본 서체로 그려져 줄바꿈과 글자 폭이
/// 실제 화면과 달라집니다. `pubspec.yaml`의 `flutter.fonts`는 테스트
/// 번들에 들어오지 않아서 파일에서 직접 읽습니다.
Future<void> loadAppFonts() async {
  final FontLoader loader = FontLoader(AppTypography.fontFamily);
  for (final String path in <String>[
    'assets/fonts/NotoSansKR-Regular.otf',
    'assets/fonts/NotoSansKR-Medium.otf',
    'assets/fonts/NotoSansKR-Bold.otf',
  ]) {
    final Uint8List bytes = await File(path).readAsBytes();
    loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
  }
  await loader.load();

  // 아이콘도 실제 글리프로 그려야 시안과 맞춰 볼 수 있습니다.
  // flutter_tester는 기본적으로 asset 폰트를 끄기 때문에, Flutter SDK가
  // 들고 있는 Material Icons를 직접 등록합니다.
  final String? flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ?? _flutterRootFromDartExecutable();
  if (flutterRoot == null) return;

  final File iconFont = File(
    '$flutterRoot/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
  );
  if (!iconFont.existsSync()) return;

  final FontLoader iconLoader = FontLoader('MaterialIcons');
  final Uint8List iconBytes = await iconFont.readAsBytes();
  iconLoader.addFont(Future<ByteData>.value(ByteData.view(iconBytes.buffer)));
  await iconLoader.load();
}

/// `flutter test`는 FLUTTER_ROOT를 항상 넘겨주지는 않아서, dart 실행 파일
/// 위치에서 거슬러 올라가 SDK 경로를 찾습니다.
String? _flutterRootFromDartExecutable() {
  final List<String> parts = Platform.resolvedExecutable.split(
    Platform.pathSeparator,
  );
  final int cacheIndex = parts.indexOf('bin');
  if (cacheIndex <= 0) return null;
  return parts.sublist(0, cacheIndex).join(Platform.pathSeparator);
}

/// 저장된 관심 목록을 흉내 냅니다.
Future<SharedPreferences> createPreferences({
  List<StockRef> favorites = const <StockRef>[],
  String? sortOptionName,
}) async {
  SharedPreferences.setMockInitialValues(<String, Object>{
    if (favorites.isNotEmpty)
      'flutter.${FavoriteStorage.key}': FavoriteStorage.encode(favorites),
    'flutter.watchlist.sort.v1': ?sortOptionName,
  });
  return SharedPreferences.getInstance();
}

/// 테스트용 앱 껍데기입니다.
///
/// 네트워크만 mock으로 바꾸고 나머지(파서 · 리포지토리 · provider)는 실제
/// 구현을 그대로 씁니다. 화면에 보이는 값이 실제 파싱을 거쳐 나온 값입니다.
Widget buildTestApp({
  required Widget child,
  required SharedPreferences preferences,
}) {
  return ProviderScope(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(preferences),
      naverHttpClientProvider.overrideWithValue(
        NaverHttpClient(client: createMockNaverClient()),
      ),
    ],
    child: MaterialApp(
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: child,
    ),
  );
}

/// 화면 크기를 시안과 같게 맞춥니다.
///
/// 상태 표시줄(59)과 홈 인디케이터(34) 영역까지 넣어야 시안 프레임과
/// 같은 좌표에서 비교할 수 있습니다. SafeArea가 실제 기기에서와 같은
/// 여백을 잡습니다.
void setFrameSize(WidgetTester tester, {double devicePixelRatio = 2}) {
  tester.view.devicePixelRatio = devicePixelRatio;
  tester.view.physicalSize = kFrameSize * devicePixelRatio;
  tester.view.padding = FakeViewPadding(
    top: 59 * devicePixelRatio,
    bottom: 34 * devicePixelRatio,
  );
  tester.view.viewPadding = FakeViewPadding(
    top: 59 * devicePixelRatio,
    bottom: 34 * devicePixelRatio,
  );
  addTearDown(tester.view.reset);
}
