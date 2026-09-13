import 'package:flutter/foundation.dart';

/// 종목을 식별하고 화면에 이름을 보여주기 위한 최소 정보입니다.
///
/// 관심 목록 · 검색 결과 · 상세 화면이 모두 이 타입을 공유합니다.
@immutable
class StockRef {
  const StockRef({
    required this.symbol,
    required this.name,
    required this.market,
  });

  factory StockRef.fromJson(Map<String, dynamic> json) => StockRef(
    symbol: json['symbol'] as String,
    name: json['name'] as String,
    market: json['market'] as String,
  );

  /// 6자리 종목코드. 예: `005930`
  final String symbol;

  /// 종목명. 예: `삼성전자`
  final String name;

  /// 거래소명. 예: `코스피`
  final String market;

  /// canonical id 입니다.
  ///
  /// 해외 종목까지 늘어나더라도 코드가 충돌하지 않도록 `domestic:` 접두사를
  /// 붙여 둡니다. (NAVER_API.md의 요구사항)
  String get id => 'domestic:$symbol';

  /// 화면에서 `005930 · 코스피`로 보이는 부분입니다.
  String get symbolWithMarket => '$symbol · $market';

  StockRef copyWith({String? name, String? market}) => StockRef(
    symbol: symbol,
    name: name ?? this.name,
    market: market ?? this.market,
  );

  Map<String, dynamic> toJson() => <String, dynamic>{
    'symbol': symbol,
    'name': name,
    'market': market,
  };

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StockRef &&
          other.symbol == symbol &&
          other.name == name &&
          other.market == market;

  @override
  int get hashCode => Object.hash(symbol, name, market);

  @override
  String toString() => 'StockRef($id, $name, $market)';
}
