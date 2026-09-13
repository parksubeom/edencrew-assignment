/// 데이터 계층에서 올라오는 실패를 화면이 그대로 쓸 수 있는 형태로 감싼 예외입니다.
///
/// 화면은 [message]만 읽어 그대로 보여주면 되고, 원인을 따라가야 할 때만
/// [cause]를 봅니다. Figma에 에러 상태 시안이 없어서, 문구는 사용자가 바로
/// 다음 행동(다시 시도)을 택할 수 있는 수준으로만 적었습니다.
class StockDataException implements Exception {
  const StockDataException(this.message, {this.cause});

  /// 네트워크 자체가 닿지 않을 때입니다.
  const StockDataException.network({Object? cause})
      : this('네트워크에 연결할 수 없습니다.', cause: cause);

  /// 응답은 왔지만 상태 코드가 정상이 아닐 때입니다.
  const StockDataException.badResponse(int statusCode)
      : this('시세를 불러오지 못했습니다. (HTTP $statusCode)');

  /// 응답 모양이 예상과 다를 때입니다.
  const StockDataException.parse({Object? cause})
      : this('응답을 해석하지 못했습니다.', cause: cause);

  /// 사용자에게 그대로 보여줄 문구입니다.
  final String message;

  /// 원인이 된 예외입니다. 로깅·디버깅용이며 화면에는 쓰지 않습니다.
  final Object? cause;

  @override
  String toString() =>
      'StockDataException($message)${cause == null ? '' : ' <- $cause'}';
}
