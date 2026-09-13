import '../core/app_exception.dart';
import '../domain/stock_ref.dart';
import 'dto/autocomplete_item_dto.dart';
import 'dto/daily_price_page_dto.dart';
import 'dto/realtime_quote_dto.dart';
import 'dto/stock_meta_dto.dart';
import 'naver_http_client.dart';
import 'sise_day_parser.dart';

/// NAVER_API.md에 정리된 endpoint 네 개를 그대로 옮긴 계층입니다.
///
/// 여기서는 **요청을 만들고 DTO로 바꾸는 것까지만** 합니다. 캐싱과 도메인
/// 모델 조립은 [StockRepository]의 몫입니다. 그래야 "어떤 요청이 실제로
/// 나가는지"를 이 파일 하나만 보고 확인할 수 있습니다.
class NaverStockApi {
  const NaverStockApi(this._client);

  final NaverHttpClient _client;

  /// 자동완성이 지원하는 검색 대상입니다. 국내 주식만 쓰지만, 응답 모양을
  /// 가이드와 맞추기 위해 파라미터는 그대로 둡니다. 실제 필터링은
  /// [AutocompleteItemDto.isDomesticStock]에서 합니다.
  static const String _searchTarget = 'stock,ipo,index,marketindicator';

  /// 실시간 시세를 한 번에 물어볼 수 있는 종목 수의 상한입니다.
  ///
  /// 관심종목은 한 번의 요청으로 조회해야 하지만(NAVER_API.md), 목록이
  /// 아주 길어졌을 때 URL이 무한정 길어지지 않도록 안전장치를 둡니다.
  static const int quoteBatchSize = 50;

  /// 1. 검색 자동완성
  Future<List<StockRef>> searchStocks(String query) async {
    final Uri uri = Uri.https('ac.stock.naver.com', '/ac', <String, String>{
      'q': query,
      'target': _searchTarget,
    });

    final Map<String, dynamic> json = await _client.getJson(uri);
    final List<dynamic> items =
        json['items'] as List<dynamic>? ?? const <dynamic>[];

    return items
        .whereType<Map<String, dynamic>>()
        .map(AutocompleteItemDto.fromJson)
        .where((AutocompleteItemDto dto) => dto.isDomesticStock)
        .map((AutocompleteItemDto dto) => dto.toDomain())
        .toList(growable: false);
  }

  /// 2. 실시간 시세 — 여러 종목을 **한 번의 요청**으로 조회합니다.
  Future<List<RealtimeQuoteDto>> fetchRealtimeQuotes(
    List<String> symbols,
  ) async {
    if (symbols.isEmpty) return const <RealtimeQuoteDto>[];

    final Uri uri = Uri.https(
      'polling.finance.naver.com',
      '/api/realtime',
      <String, String>{'query': 'SERVICE_ITEM:${symbols.join(',')}'},
    );

    final Map<String, dynamic> json = await _client.getJson(uri);
    final Map<String, dynamic>? result = json['result'] as Map<String, dynamic>?;
    final List<dynamic> areas =
        result?['areas'] as List<dynamic>? ?? const <dynamic>[];

    return areas
        .whereType<Map<String, dynamic>>()
        .expand(
          (Map<String, dynamic> area) =>
              area['datas'] as List<dynamic>? ?? const <dynamic>[],
        )
        .whereType<Map<String, dynamic>>()
        .map(RealtimeQuoteDto.fromJson)
        .toList(growable: false);
  }

  /// 3. 종목 메타데이터
  Future<StockMetaDto> fetchStockMeta(String symbol) async {
    final Uri uri = Uri.https(
      'stock.naver.com',
      '/api/securityFe/api/fchart/domestic/stock/$symbol',
    );

    final Map<String, dynamic> json = await _client.getJson(uri);
    final StockMetaDto dto = StockMetaDto.fromJson(json);
    if (dto.stockName.isEmpty) {
      throw const StockDataException('종목 정보를 찾지 못했습니다.');
    }
    return dto;
  }

  /// 4. 일별 시세 (HTML)
  Future<DailyPricePageDto> fetchDailyPricePage(String symbol, int page) async {
    final Uri uri = Uri.https(
      'finance.naver.com',
      '/item/sise_day.naver',
      <String, String>{'code': symbol, 'page': '$page'},
    );

    // Referer가 없으면 응답을 주지 않는 경우가 있어 함께 보냅니다.
    final String body = await _client.getText(
      uri,
      headers: <String, String>{
        'Referer': 'https://finance.naver.com/item/sise_day.naver?code=$symbol',
      },
    );

    return SiseDayParser.parse(body, page: page);
  }
}
