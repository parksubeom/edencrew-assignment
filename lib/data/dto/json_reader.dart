/// DTO들이 공통으로 쓰는 JSON 읽기 도우미입니다.
///
/// Naver 응답은 같은 필드가 상황에 따라 정수로도, 실수로도, 문자열로도
/// 내려옵니다. (예: 거래량이 `13938673`일 때와 `1.3938673E7`일 때)
/// 매 DTO에서 같은 방어 코드를 반복하지 않으려고 모아 두었습니다.
abstract final class JsonReader {
  /// 값이 없거나 숫자로 읽을 수 없으면 [fallback]을 돌려줍니다.
  static int intOr(Object? value, [int fallback = 0]) {
    if (value is int) return value;
    if (value is num) return value.round();
    if (value is String) {
      final String cleaned = value.replaceAll(',', '').trim();
      return int.tryParse(cleaned) ?? double.tryParse(cleaned)?.round() ??
          fallback;
    }
    return fallback;
  }

  static String stringOr(Object? value, [String fallback = '']) {
    if (value is String) return value;
    if (value == null) return fallback;
    return value.toString();
  }
}
