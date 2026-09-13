import 'dart:math' as math;

import '../domain/chart_period.dart';
import '../domain/daily_price.dart';
import '../domain/quote.dart';
import '../domain/stock_ref.dart';
import 'dto/daily_price_page_dto.dart';
import 'dto/realtime_quote_dto.dart';
import 'naver_stock_api.dart';

/// 화면이 실제로 쓰는 데이터 창구입니다.
///
/// [NaverStockApi]가 "요청 한 번"이라면 이 클래스는 "화면이 필요한 만큼"을
/// 책임집니다. 특히 일별 시세는 기간 탭을 바꿀 때마다 25페이지를 다시 받는
/// 일이 없도록, **종목별로 이미 받은 페이지를 들고 있다가 모자란 페이지만**
/// 추가로 요청합니다.
class StockRepository {
  StockRepository(this._api);

  final NaverStockApi _api;

  /// 종목코드 → 이미 받아 둔 일별 시세 페이지
  final Map<String, _DailyPriceCache> _dailyPriceCache =
      <String, _DailyPriceCache>{};

  /// 종목코드 → 메타데이터. 이름과 시장은 바뀌지 않으므로 앱이 사는 동안
  /// 한 번만 받으면 됩니다.
  final Map<String, StockRef> _metaCache = <String, StockRef>{};

  /// 일별 시세 페이지를 동시에 몇 개까지 받을지입니다.
  ///
  /// `1년`은 25페이지라 하나씩 받으면 너무 느리고, 25개를 한꺼번에 던지면
  /// 차단될 수 있어 중간값으로 잡았습니다.
  static const int _pageRequestConcurrency = 5;

  /// 검색 결과입니다. 국내 주식 6자리 코드만 넘어옵니다.
  Future<List<StockRef>> search(String query) => _api.searchStocks(query);

  /// 관심 목록 전체 시세를 조회합니다.
  ///
  /// 종목마다 따로 호출하지 않고 한 번의 요청으로 받습니다. 종목 수가
  /// [NaverStockApi.quoteBatchSize]를 넘으면 그만큼씩 나눠 보냅니다.
  ///
  /// 돌려주는 값은 symbol로 바로 찾을 수 있는 Map입니다. 목록을 정렬하거나
  /// 행을 그릴 때 매번 리스트를 훑지 않기 위해서입니다.
  Future<Map<String, Quote>> loadQuotes(List<String> symbols) async {
    if (symbols.isEmpty) return <String, Quote>{};

    final Map<String, Quote> quotes = <String, Quote>{};
    for (final List<String> batch in _chunks(
      symbols,
      NaverStockApi.quoteBatchSize,
    )) {
      final List<RealtimeQuoteDto> dtos = await _api.fetchRealtimeQuotes(batch);
      for (final RealtimeQuoteDto dto in dtos) {
        quotes[dto.symbol] = dto.toDomain();
      }
    }
    return quotes;
  }

  /// 종목명과 거래소명입니다. 한 번 받은 종목은 캐시에서 돌려줍니다.
  Future<StockRef> loadMeta(String symbol) async {
    final StockRef? cached = _metaCache[symbol];
    if (cached != null) return cached;

    final StockRef ref = (await _api.fetchStockMeta(symbol)).toDomain();
    _metaCache[symbol] = ref;
    return ref;
  }

  /// 검색 결과처럼 이미 이름과 시장을 알고 있는 값을 캐시에 넣어 둡니다.
  ///
  /// 검색 화면에서 상세로 들어가면 메타데이터를 다시 받을 필요가 없습니다.
  void cacheMeta(StockRef ref) => _metaCache[ref.symbol] = ref;

  /// [period]가 요구하는 거래일 수만큼 일별 시세를 돌려줍니다.
  ///
  /// 이미 받아 둔 페이지는 다시 요청하지 않습니다. 예를 들어 `1개월`(2페이지)를
  /// 본 뒤 `3개월`(6페이지)로 바꾸면 3~6페이지만 추가로 받습니다. 다시
  /// `1개월`로 돌아오면 요청이 한 건도 나가지 않습니다.
  Future<List<DailyPrice>> loadDailyPrices(
    String symbol,
    ChartPeriod period,
  ) async {
    final _DailyPriceCache cache = _dailyPriceCache.putIfAbsent(
      symbol,
      _DailyPriceCache.new,
    );

    // 1페이지를 먼저 받아야 lastPage를 알 수 있고, 그래야 없는 페이지를
    // 요청하지 않을 수 있습니다.
    if (!cache.hasPage(1)) {
      cache.put(await _api.fetchDailyPricePage(symbol, 1));
    }

    final int wantedPages = math.min(period.pageCount, cache.lastPage);
    final List<int> missingPages = <int>[
      for (int page = 2; page <= wantedPages; page++)
        if (!cache.hasPage(page)) page,
    ];

    for (final List<int> chunk in _chunks(
      missingPages,
      _pageRequestConcurrency,
    )) {
      final List<DailyPricePageDto> pages = await Future.wait(
        chunk.map((int page) => _api.fetchDailyPricePage(symbol, page)),
      );
      for (final DailyPricePageDto page in pages) {
        cache.put(page);
      }
    }

    return cache.take(period.tradingDays);
  }

  /// 상세 화면에서 새로고침할 때처럼, 캐시를 버리고 다시 받아야 할 때 씁니다.
  void invalidateDailyPrices(String symbol) => _dailyPriceCache.remove(symbol);

  /// [items]를 [size]개씩 끊어 돌려줍니다.
  static Iterable<List<T>> _chunks<T>(List<T> items, int size) sync* {
    for (int start = 0; start < items.length; start += size) {
      yield items.sublist(start, math.min(start + size, items.length));
    }
  }
}

/// 한 종목의 일별 시세 페이지 캐시입니다.
///
/// 페이지 번호를 키로 들고 있다가, 필요한 만큼 앞에서부터 이어 붙입니다.
/// 1페이지가 가장 최근 10거래일이므로 페이지 번호 순서가 곧 최신순입니다.
class _DailyPriceCache {
  final Map<int, List<DailyPrice>> _pages = <int, List<DailyPrice>>{};

  /// 이 종목에 존재하는 마지막 페이지입니다. 1페이지를 받기 전에는 알 수
  /// 없으므로, 그때까지는 1로 둡니다.
  int _lastPage = 1;

  int get lastPage => _lastPage;

  bool hasPage(int page) => _pages.containsKey(page);

  void put(DailyPricePageDto page) {
    _pages[page.page] = page.items;
    _lastPage = page.lastPage;
  }

  /// 최신 거래일부터 [count]개를 돌려줍니다.
  List<DailyPrice> take(int count) {
    final List<int> pageNumbers = _pages.keys.toList()..sort();
    final List<DailyPrice> merged = <DailyPrice>[
      for (final int page in pageNumbers) ..._pages[page]!,
    ];
    if (merged.length <= count) return merged;
    return merged.sublist(0, count);
  }
}
