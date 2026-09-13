import 'package:flutter/foundation.dart';

import 'price_direction.dart';

/// 실시간 시세 한 종목분입니다.
///
/// 등락액 · 등락률 · 시가총액은 응답에 들어 있지 않아 계산해서 씁니다.
/// (NAVER_API.md의 `실시간 시세` 항목)
@immutable
class Quote {
  const Quote({
    required this.symbol,
    required this.currentPrice,
    required this.previousClose,
    required this.open,
    required this.high,
    required this.low,
    required this.accumulatedVolume,
    required this.listedShareCount,
  });

  final String symbol;

  /// 현재가 (`nv`)
  final int currentPrice;

  /// 전일 종가 (`pcv`)
  final int previousClose;

  /// 시가 (`ov`)
  final int open;

  /// 고가 (`hv`)
  final int high;

  /// 저가 (`lv`)
  final int low;

  /// 누적 거래량 (`aq`)
  final int accumulatedVolume;

  /// 상장 주식 수 (`countOfListedStock`)
  final int listedShareCount;

  /// 전일 대비 등락액 = `nv - pcv`
  int get change => currentPrice - previousClose;

  /// 전일 대비 등락률(%) = `(nv - pcv) / pcv × 100`
  ///
  /// 전일 종가가 0인 종목(신규 상장 첫날 등)은 나눗셈이 성립하지 않으므로
  /// 0%로 둡니다.
  double get changeRatePercent {
    if (previousClose == 0) return 0;
    return change / previousClose * 100;
  }

  PriceDirection get direction => PriceDirection.ofChange(change);

  /// 시가총액 = `nv × countOfListedStock`
  int get marketCap => currentPrice * listedShareCount;

  @override
  String toString() => 'Quote($symbol, $currentPrice, $change)';
}
