import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/app_exception.dart';
import '../domain/chart_period.dart';
import '../domain/daily_price.dart';
import '../domain/quote.dart';
import '../domain/stock_ref.dart';
import 'providers.dart';

/// 상세 화면 상단의 종목명 · `종목코드 · 시장` 입니다.
///
/// 검색을 거쳐 들어왔다면 리포지토리 캐시에 이미 들어 있어 요청이 나가지
/// 않고, 관심 목록에서 바로 들어왔거나 앱을 다시 켠 뒤라면 메타데이터
/// endpoint를 한 번 호출합니다.
final stockMetaProvider = FutureProvider.family<StockRef, String>(
  (Ref ref, String symbol) =>
      ref.watch(stockRepositoryProvider).loadMeta(symbol),
);

/// 상세 화면의 현재가 · 등락 · 요약 카드에 쓰는 시세입니다.
final stockQuoteProvider = FutureProvider.family<Quote, String>((
  Ref ref,
  String symbol,
) async {
  final Map<String, Quote> quotes = await ref
      .watch(stockRepositoryProvider)
      .loadQuotes(<String>[symbol]);

  final Quote? quote = quotes[symbol];
  if (quote == null) {
    throw const StockDataException('시세를 찾지 못했습니다.');
  }
  return quote;
});

/// 일별 시세 요청 키입니다.
///
/// `family`의 인자는 값이 같으면 같은 요청으로 취급되어야 캐시가 듣습니다.
/// 그래서 `==`와 `hashCode`를 직접 맞춰 둡니다.
@immutable
class DailyPriceRequest {
  const DailyPriceRequest({required this.symbol, required this.period});

  final String symbol;
  final ChartPeriod period;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyPriceRequest &&
          other.symbol == symbol &&
          other.period == period;

  @override
  int get hashCode => Object.hash(symbol, period);

  @override
  String toString() => 'DailyPriceRequest($symbol, ${period.label})';
}

/// 차트와 일별 시세 표가 함께 쓰는 데이터입니다.
///
/// 기간 탭을 바꾸면 인자가 달라져 새로 실행되지만, 실제 네트워크 요청은
/// [StockRepository]가 모자란 페이지에 대해서만 보냅니다. `1개월`에서
/// `3개월`로 갔다가 돌아오면 두 번째에는 요청이 나가지 않습니다.
final dailyPricesProvider =
    FutureProvider.family<List<DailyPrice>, DailyPriceRequest>(
      (Ref ref, DailyPriceRequest request) => ref
          .watch(stockRepositoryProvider)
          .loadDailyPrices(request.symbol, request.period),
    );
