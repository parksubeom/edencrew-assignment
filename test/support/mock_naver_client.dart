import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

/// `assets/mock/`에 저장해 둔 실제 응답을 메모리에 올려 둡니다.
///
/// 위젯 테스트는 가짜 시계(FakeAsync) 안에서 돌기 때문에, 테스트 본문에서
/// 파일을 읽으면 그 Future가 끝나지 않고 멈춥니다. 그래서 파일 읽기는
/// `setUpAll`에서 미리 끝내 두고, 요청 처리기는 메모리에 있는 바이트만
/// 돌려주도록 했습니다.
abstract final class NaverFixtures {
  static late final Uint8List autocomplete;
  static late final Uint8List realtime;
  static late final Uint8List siseDayPage1;
  static late final Uint8List siseDayPage2;

  static bool _loaded = false;

  static Future<void> load() async {
    if (_loaded) return;
    autocomplete = await File(
      'assets/mock/ac_search_samsung.json',
    ).readAsBytes();
    realtime = await File('assets/mock/realtime_watchlist.json').readAsBytes();
    siseDayPage1 = await File(
      'assets/mock/sise_day_005930_p1.html',
    ).readAsBytes();
    siseDayPage2 = await File(
      'assets/mock/sise_day_005930_p2.html',
    ).readAsBytes();
    _loaded = true;
  }
}

/// 저장해 둔 응답으로 Naver endpoint 네 개를 흉내 냅니다.
///
/// 응답 본문뿐 아니라 **Content-Type의 charset까지 실제와 같게** 돌려줍니다.
/// 그래야 EUC-KR 디코딩을 포함한 파싱 경로를 그대로 태울 수 있습니다.
/// 화면에 보이는 값은 실제 파싱을 거쳐 나온 값입니다.
http.Client createMockNaverClient() {
  return MockClient((http.Request request) async {
    final Uri uri = request.url;

    switch (uri.host) {
      case 'ac.stock.naver.com':
        return _autocompleteResponse(uri.queryParameters['q'] ?? '');

      case 'polling.finance.naver.com':
        return _bytes(NaverFixtures.realtime, 'text/plain;charset=EUC-KR');

      case 'stock.naver.com':
        return _metaResponse(uri.pathSegments.last);

      case 'finance.naver.com':
        final int page = int.tryParse(uri.queryParameters['page'] ?? '1') ?? 1;
        // 저장해 둔 페이지는 1·2번뿐이라 그 뒤 페이지는 2번을 돌려줍니다.
        // 페이지를 이어 받는 동작을 확인하는 데는 충분합니다.
        return _bytes(
          page <= 1 ? NaverFixtures.siseDayPage1 : NaverFixtures.siseDayPage2,
          'text/html;charset=EUC-KR',
        );

      default:
        return http.Response('not found', 404);
    }
  });
}

http.Response _bytes(Uint8List body, String contentType) => http.Response.bytes(
  body,
  200,
  headers: <String, String>{'content-type': contentType},
);

/// 저장해 둔 `삼성` 자동완성 응답에서 검색어에 맞는 항목만 남겨 돌려줍니다.
///
/// 실제 endpoint처럼 검색어에 따라 결과가 달라져야, `검색 결과 없음` 상태까지
/// 같은 경로로 확인할 수 있습니다.
http.Response _autocompleteResponse(String query) {
  final Map<String, dynamic> source =
      jsonDecode(utf8.decode(NaverFixtures.autocomplete))
          as Map<String, dynamic>;

  final List<dynamic> items =
      source['items'] as List<dynamic>? ?? const <dynamic>[];
  final String needle = query.trim().toLowerCase();

  final List<dynamic> matched = items.where((dynamic item) {
    if (item is! Map<String, dynamic>) return false;
    final String name = (item['name'] as String? ?? '').toLowerCase();
    final String code = item['code'] as String? ?? '';
    return needle.isEmpty || name.contains(needle) || code.contains(needle);
  }).toList();

  return _bytes(
    Uint8List.fromList(
      utf8.encode(
        jsonEncode(<String, dynamic>{'query': query, 'items': matched}),
      ),
    ),
    'application/json;charset=UTF-8',
  );
}

/// 메타데이터는 005930만 저장해 두었으므로, 나머지 종목은 같은 모양으로
/// 만들어 돌려줍니다. 검색 결과에 나오는 종목을 상세로 열어볼 수 있게
/// 하기 위해서입니다.
http.Response _metaResponse(String symbol) {
  const Map<String, String> names = <String, String>{
    '005930': '삼성전자',
    '005935': '삼성전자우',
    '000660': 'SK하이닉스',
    '035720': '카카오',
    '247540': '에코프로비엠',
    '373220': 'LG에너지솔루션',
    '207940': '삼성바이오로직스',
  };

  final Map<String, Object> body = <String, Object>{
    'symbolCode': symbol,
    'stockName': names[symbol] ?? '테스트종목',
    'stockExchangeNameKor': symbol == '247540' ? '코스닥' : '코스피',
  };

  return _bytes(
    Uint8List.fromList(utf8.encode(jsonEncode(body))),
    'application/json;charset=utf-8',
  );
}
