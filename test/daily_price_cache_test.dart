import 'dart:io';
import 'dart:typed_data';

import 'package:edencrew_assignment_starter/data/naver_http_client.dart';
import 'package:edencrew_assignment_starter/data/naver_stock_api.dart';
import 'package:edencrew_assignment_starter/data/stock_repository.dart';
import 'package:edencrew_assignment_starter/domain/chart_period.dart';
import 'package:edencrew_assignment_starter/domain/daily_price.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// `1년도 한 번에 전부 받지 말고, 필요한 만큼만 받고 이미 받은 페이지는
/// 재사용하도록 구성해 주세요`가 요구사항이라, 실제로 몇 페이지를
/// 요청하는지 세어 확인합니다.
void main() {
  late List<int> requestedPages;
  late StockRepository repository;

  setUp(() async {
    requestedPages = <int>[];

    final Uint8List page1 = await File(
      'assets/mock/sise_day_005930_p1.html',
    ).readAsBytes();
    final Uint8List page2 = await File(
      'assets/mock/sise_day_005930_p2.html',
    ).readAsBytes();

    final http.Client client = MockClient((http.Request request) async {
      final int page =
          int.tryParse(request.url.queryParameters['page'] ?? '1') ?? 1;
      requestedPages.add(page);

      return http.Response.bytes(
        page <= 1 ? page1 : page2,
        200,
        headers: <String, String>{'content-type': 'text/html;charset=EUC-KR'},
      );
    });

    repository = StockRepository(
      NaverStockApi(NaverHttpClient(client: client)),
    );
  });

  test('1개월은 2페이지만 받는다', () async {
    await repository.loadDailyPrices('005930', ChartPeriod.oneMonth);

    expect(requestedPages..sort(), <int>[1, 2]);
  });

  test('기간을 늘리면 모자란 페이지만 추가로 받는다', () async {
    await repository.loadDailyPrices('005930', ChartPeriod.oneMonth);
    requestedPages.clear();

    await repository.loadDailyPrices('005930', ChartPeriod.threeMonths);

    // 3개월은 6페이지. 1·2페이지는 이미 있으므로 3~6만 받아야 합니다.
    expect(requestedPages..sort(), <int>[3, 4, 5, 6]);
  });

  test('이미 받은 기간으로 되돌아가면 요청이 나가지 않는다', () async {
    await repository.loadDailyPrices('005930', ChartPeriod.threeMonths);
    requestedPages.clear();

    await repository.loadDailyPrices('005930', ChartPeriod.oneMonth);

    expect(requestedPages, isEmpty);
  });

  test('기간이 요구하는 거래일 수만큼만 돌려준다', () async {
    final List<DailyPrice> prices = await repository.loadDailyPrices(
      '005930',
      ChartPeriod.oneMonth,
    );

    expect(prices, hasLength(ChartPeriod.oneMonth.tradingDays));
  });

  test('캐시를 비우면 다시 받는다', () async {
    await repository.loadDailyPrices('005930', ChartPeriod.oneMonth);
    repository.invalidateDailyPrices('005930');
    requestedPages.clear();

    await repository.loadDailyPrices('005930', ChartPeriod.oneMonth);

    expect(requestedPages..sort(), <int>[1, 2]);
  });
}
