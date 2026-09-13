import 'dart:async';
import 'dart:convert';

import 'package:charset/charset.dart';
import 'package:http/http.dart' as http;

import '../core/app_exception.dart';

/// Naver endpoint 네 개가 공통으로 쓰는 HTTP 래퍼입니다.
///
/// 이 클래스가 책임지는 것은 두 가지입니다.
///
/// 1. **문자 인코딩.** 네 endpoint의 charset이 서로 다릅니다.
///    자동완성과 메타데이터는 UTF-8이지만, 실시간 시세는
///    `text/plain;charset=EUC-KR`, 일별 시세 HTML은
///    `text/html;charset=EUC-KR`로 내려옵니다. 처음에는 `response.body`를
///    그대로 썼는데 한글이 깨져서, 응답 헤더의 charset을 보고 바이트를
///    직접 디코딩하도록 바꿨습니다.
/// 2. **실패를 [StockDataException]으로 정규화.** 화면이 dio/http의
///    예외 타입을 알 필요가 없게 합니다.
class NaverHttpClient {
  NaverHttpClient({http.Client? client, Duration? timeout})
    : _client = client ?? http.Client(),
      _timeout = timeout ?? const Duration(seconds: 10);

  final http.Client _client;
  final Duration _timeout;

  /// 브라우저에서 보내는 것과 비슷한 헤더입니다.
  ///
  /// 기본 Dart User-Agent로 요청하면 finance.naver.com이 응답을 주지 않는
  /// 경우가 있어 넣어 두었습니다.
  static const Map<String, String> _defaultHeaders = <String, String>{
    'User-Agent':
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
        'AppleWebKit/537.36 (KHTML, like Gecko) Chrome/124.0.0.0 Safari/537.36',
    'Accept-Language': 'ko-KR,ko;q=0.9',
  };

  /// 응답 본문을 문자열로 돌려줍니다. charset 처리까지 끝난 상태입니다.
  Future<String> getText(Uri uri, {Map<String, String>? headers}) async {
    final http.Response response;
    try {
      response = await _client
          .get(uri, headers: <String, String>{..._defaultHeaders, ...?headers})
          .timeout(_timeout);
    } on TimeoutException catch (error) {
      throw StockDataException.network(cause: error);
    } catch (error) {
      throw StockDataException.network(cause: error);
    }

    if (response.statusCode != 200) {
      throw StockDataException.badResponse(response.statusCode);
    }
    return _decodeBody(response);
  }

  /// 응답을 JSON 객체로 돌려줍니다.
  Future<Map<String, dynamic>> getJson(
    Uri uri, {
    Map<String, String>? headers,
  }) async {
    final String body = await getText(uri, headers: headers);
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (error) {
      throw StockDataException.parse(cause: error);
    }
  }

  void close() => _client.close();

  /// Content-Type의 charset을 보고 바이트를 디코딩합니다.
  ///
  /// EUC-KR을 다루는 방법을 두 가지 찾았습니다. `charset_converter`는 각
  /// 플랫폼의 변환기를 플랫폼 채널로 부르고, `charset`은 순수 Dart로
  /// 구현되어 있습니다. 대상 플랫폼이 늘어날 때 신경 쓸 일이 적은 쪽이
  /// 낫다고 보고 `charset`을 골랐습니다.
  String _decodeBody(http.Response response) {
    final String charsetName = _charsetOf(response.headers['content-type']);
    try {
      if (charsetName == 'euc-kr' ||
          charsetName == 'ksc5601' ||
          charsetName == 'cp949' ||
          charsetName == 'ms949') {
        return eucKr.decode(response.bodyBytes);
      }
      return utf8.decode(response.bodyBytes, allowMalformed: true);
    } catch (error) {
      throw StockDataException.parse(cause: error);
    }
  }

  /// `text/html;charset=EUC-KR` → `euc-kr`
  static String _charsetOf(String? contentType) {
    if (contentType == null) return 'utf-8';
    final Match? match = RegExp(
      r'charset\s*=\s*"?([\w-]+)"?',
      caseSensitive: false,
    ).firstMatch(contentType);
    return (match?.group(1) ?? 'utf-8').toLowerCase();
  }
}
