import 'package:flutter/foundation.dart';

import 'price_direction.dart';

/// 일별 시세 한 거래일분입니다.
@immutable
class DailyPrice {
  const DailyPrice({
    required this.date,
    required this.close,
    required this.open,
    required this.high,
    required this.low,
    required this.volume,
    required this.change,
  });

  /// 거래일입니다. 시각은 의미가 없어 자정으로 정규화해 둡니다.
  final DateTime date;

  final int close;
  final int open;
  final int high;
  final int low;
  final int volume;

  /// 전일 대비 등락액입니다.
  ///
  /// HTML의 `전일비` 칸은 절댓값만 들어 있고 방향은
  /// `<em class="bu_pup | bu_pdn | bu_pn">`으로 표시되어 있어,
  /// 파서에서 부호를 붙여 둡니다.
  final int change;

  /// 일별 시세 표의 `등락` 칸 색을 정합니다.
  PriceDirection get direction => PriceDirection.ofChange(change);

  /// 캔들 색을 정합니다. 종가가 시가보다 높으면 양봉입니다.
  PriceDirection get candleDirection => PriceDirection.ofChange(close - open);

  @override
  String toString() => 'DailyPrice($date, $close)';
}
