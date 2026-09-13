import 'package:edencrew_assignment_starter/app.dart';
import 'package:edencrew_assignment_starter/domain/stock_ref.dart';
import 'package:edencrew_assignment_starter/ui/common/app_bottom_nav.dart';
import 'package:edencrew_assignment_starter/ui/detail/detail_screen.dart';
import 'package:edencrew_assignment_starter/ui/search/widgets/search_result_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/test_harness.dart';

/// `관심 상태가 바뀌면 세 화면이 함께 바뀐다`는 필수 요건을, 화면을 실제로
/// 오가면서 확인합니다.
void main() {
  setUpAll(initTestEnvironment);

  Finder navTab(String label) => find.descendant(
    of: find.byType(AppBottomNav),
    matching: find.text(label),
  );

  Future<void> searchFor(WidgetTester tester, String query) async {
    await tester.tap(navTab('검색'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), query);
    // 디바운스(300ms)가 지난 뒤에야 요청이 나갑니다.
    await tester.pumpAndSettle(const Duration(milliseconds: 600));
  }

  testWidgets('검색에서 등록한 종목이 관심 목록에 나타난다', (WidgetTester tester) async {
    setFrameSize(tester);
    final SharedPreferences preferences = await createPreferences();

    await tester.pumpWidget(
      buildTestApp(child: const HomeShell(), preferences: preferences),
    );
    await tester.pumpAndSettle();

    // 처음에는 빈 상태입니다.
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);

    await searchFor(tester, '삼성');
    expect(find.byType(SearchResultRow), findsWidgets);

    // 첫 결과(삼성전자)의 별을 누릅니다.
    await tester.tap(
      find.descendant(
        of: find.byType(SearchResultRow).first,
        matching: find.byIcon(Icons.star_border_rounded),
      ),
    );
    await tester.pump(const Duration(milliseconds: 250));

    // 토스트 문구가 등록 쪽이어야 합니다.
    expect(find.text('관심이 등록되었습니다'), findsOneWidget);

    // 별이 즉시 채워집니다.
    expect(
      find.descendant(
        of: find.byType(SearchResultRow).first,
        matching: find.byIcon(Icons.star_rounded),
      ),
      findsOneWidget,
    );

    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 관심 탭으로 넘어가면 목록에 들어와 있습니다.
    await tester.tap(navTab('관심'));
    await tester.pumpAndSettle();

    expect(find.text('관심 종목이 없습니다'), findsNothing);
    expect(find.text('삼성전자'), findsOneWidget);
  });

  testWidgets('상세에서 관심을 해제하고 돌아오면 목록에서도 빠진다', (WidgetTester tester) async {
    setFrameSize(tester);
    final SharedPreferences preferences = await createPreferences();

    await tester.pumpWidget(
      buildTestApp(child: const HomeShell(), preferences: preferences),
    );
    await tester.pumpAndSettle();

    await searchFor(tester, '삼성');
    await tester.tap(
      find.descendant(
        of: find.byType(SearchResultRow).first,
        matching: find.byIcon(Icons.star_border_rounded),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 3));

    // 검색 결과 행을 눌러 상세로 들어갑니다.
    await tester.tap(find.byType(SearchResultRow).first);
    await tester.pumpAndSettle();
    expect(find.byType(DetailScreen), findsOneWidget);

    // 상세 헤더의 별은 이미 채워져 있어야 합니다. (검색에서 등록했으므로)
    final Finder detailStar = find.descendant(
      of: find.byType(DetailScreen),
      matching: find.byIcon(Icons.star_rounded),
    );
    expect(detailStar, findsOneWidget);

    // 여기서 해제하고 돌아옵니다.
    await tester.tap(detailStar);
    await tester.pumpAndSettle();
    // 헤더의 뒤로 가기 버튼으로 돌아옵니다.
    await tester.tap(find.byTooltip('뒤로'));
    await tester.pumpAndSettle();

    // 검색 결과의 별이 빈 모양으로 돌아와 있습니다.
    expect(
      find.descendant(
        of: find.byType(SearchResultRow).first,
        matching: find.byIcon(Icons.star_border_rounded),
      ),
      findsOneWidget,
    );

    // 관심 목록도 다시 비어 있습니다.
    await tester.tap(navTab('관심'));
    await tester.pumpAndSettle();
    expect(find.text('관심 종목이 없습니다'), findsOneWidget);
  });

  testWidgets('검색 결과에는 현재 관심 상태가 그대로 반영된다', (WidgetTester tester) async {
    setFrameSize(tester);
    // 이미 삼성전자를 관심으로 저장해 둔 상태에서 시작합니다.
    final SharedPreferences preferences = await createPreferences(
      favorites: const <StockRef>[
        StockRef(symbol: '005930', name: '삼성전자', market: '코스피'),
      ],
    );

    await tester.pumpWidget(
      buildTestApp(child: const HomeShell(), preferences: preferences),
    );
    await tester.pumpAndSettle();

    await searchFor(tester, '삼성');

    // 검색 응답에는 관심 여부가 없지만, 별은 관심 상태에서 나오므로
    // 첫 결과만 채워져 있어야 합니다.
    expect(
      find.descendant(
        of: find.byType(SearchResultRow).first,
        matching: find.byIcon(Icons.star_rounded),
      ),
      findsOneWidget,
    );
  });
}
