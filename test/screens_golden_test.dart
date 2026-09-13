import 'package:edencrew_assignment_starter/app.dart';
import 'package:edencrew_assignment_starter/domain/stock_ref.dart';
import 'package:edencrew_assignment_starter/ui/detail/detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_harness.dart';

/// 시안(393 × 852)과 같은 크기로 각 화면을 그려 PNG로 남깁니다.
/// 결과는 `test/goldens/`에 있고, Figma 프레임과 나란히 놓고 여백과 글자
/// 크기를 맞추는 데 썼습니다. 상태 표시줄(59)과 홈 인디케이터(34)까지 넣어
/// 시안 프레임과 같은 좌표에서 비교합니다.
///
/// **평소에는 건너뜁니다.** 글자 래스터라이즈가 OS와 폰트 버전에 따라 미세하게
/// 달라져서, 다른 환경에서 `flutter test`가 실패하는 것을 막기 위해서입니다.
/// 이미지를 다시 만들려면 아래처럼 실행합니다.
///
/// ```bash
/// flutter test --dart-define=GOLDEN=true --update-goldens test/screens_golden_test.dart
/// ```
const bool _runGoldens = bool.fromEnvironment('GOLDEN');

void main() {
  const List<StockRef> favorites = <StockRef>[
    StockRef(symbol: '005930', name: '삼성전자', market: '코스피'),
    StockRef(symbol: '000660', name: 'SK하이닉스', market: '코스피'),
    StockRef(symbol: '035720', name: '카카오', market: '코스피'),
    StockRef(symbol: '247540', name: '에코프로비엠', market: '코스닥'),
    StockRef(symbol: '373220', name: 'LG에너지솔루션', market: '코스피'),
  ];

  setUpAll(initTestEnvironment);

  testWidgets('01 관심', (WidgetTester tester) async {
    setFrameSize(tester);
    final SharedPreferences preferences = await createPreferences(
      favorites: favorites,
      sortOptionName: 'name',
    );

    await tester.pumpWidget(
      buildTestApp(child: const HomeShell(), preferences: preferences),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/01_watchlist.png'),
    );
  }, skip: !_runGoldens);

  testWidgets('01 관심_empty', (WidgetTester tester) async {
    setFrameSize(tester);
    final SharedPreferences preferences = await createPreferences();

    await tester.pumpWidget(
      buildTestApp(child: const HomeShell(), preferences: preferences),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/01_watchlist_empty.png'),
    );
  }, skip: !_runGoldens);

  testWidgets('01 관심_sort', (WidgetTester tester) async {
    setFrameSize(tester);
    final SharedPreferences preferences = await createPreferences(
      favorites: favorites,
      sortOptionName: 'name',
    );

    await tester.pumpWidget(
      buildTestApp(child: const HomeShell(), preferences: preferences),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('가나다순'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/01_watchlist_sort.png'),
    );
  }, skip: !_runGoldens);

  testWidgets('02 검색_empty', (WidgetTester tester) async {
    setFrameSize(tester);
    final SharedPreferences preferences = await createPreferences();

    await tester.pumpWidget(
      buildTestApp(child: const HomeShell(), preferences: preferences),
    );
    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/02_search_empty.png'),
    );
  }, skip: !_runGoldens);

  testWidgets('02 검색', (WidgetTester tester) async {
    setFrameSize(tester);
    final SharedPreferences preferences = await createPreferences(
      favorites: <StockRef>[favorites.first],
    );

    await tester.pumpWidget(
      buildTestApp(child: const HomeShell(), preferences: preferences),
    );
    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '삼성');
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/02_search_results.png'),
    );
  }, skip: !_runGoldens);

  testWidgets('02 검색결과_empty', (WidgetTester tester) async {
    setFrameSize(tester);
    final SharedPreferences preferences = await createPreferences();

    await tester.pumpWidget(
      buildTestApp(child: const HomeShell(), preferences: preferences),
    );
    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'ㄱㄴㄷㄹㅁㅂㅅ');
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/02_search_no_results.png'),
    );
  }, skip: !_runGoldens);

  testWidgets('04 검색 · 관심 등록 토스트', (WidgetTester tester) async {
    setFrameSize(tester);
    final SharedPreferences preferences = await createPreferences();

    await tester.pumpWidget(
      buildTestApp(child: const HomeShell(), preferences: preferences),
    );
    await tester.tap(find.text('검색'));
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '삼성');
    await tester.pumpAndSettle(const Duration(milliseconds: 600));

    await tester.tap(find.byIcon(Icons.star_border_rounded).first);
    await tester.pump(const Duration(milliseconds: 250));

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/04_search_toast_added.png'),
    );

    // 타이머가 남은 채로 테스트가 끝나지 않도록 정리합니다.
    await tester.pumpAndSettle(const Duration(seconds: 3));
  }, skip: !_runGoldens);

  testWidgets('03 종목상세', (WidgetTester tester) async {
    setFrameSize(tester);
    final SharedPreferences preferences = await createPreferences(
      favorites: <StockRef>[favorites.first],
    );

    await tester.pumpWidget(
      buildTestApp(
        child: const DetailScreen(
          stock: StockRef(symbol: '005930', name: '삼성전자', market: '코스피'),
        ),
        preferences: preferences,
      ),
    );
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/03_detail.png'),
    );
  }, skip: !_runGoldens);
}
