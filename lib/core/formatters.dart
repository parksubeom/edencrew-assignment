import 'package:intl/intl.dart';

import '../domain/price_direction.dart';

/// 화면에 숫자를 찍을 때 쓰는 포맷터 모음입니다.
///
/// 시세 값 자체는 실시간으로 바뀌므로 Figma의 숫자와 같을 수 없습니다.
/// 여기서 맞추는 것은 **표기 형식**입니다.
abstract final class Formatters {
  static final NumberFormat _decimal = NumberFormat('#,##0');
  static final NumberFormat _twoDecimals = NumberFormat('0.00');
  static final DateFormat _monthDay = DateFormat('MM.dd');
  static final DateFormat _compactDate = DateFormat('yyyyMMdd');

  /// 조 단위. 시가총액 축약에 사용합니다.
  static const int _jo = 1000000000000;

  /// 억 단위. 시가총액이 1조 미만일 때 사용합니다.
  static const int _eok = 100000000;

  /// `179,700`
  static String price(num value) => _decimal.format(value);

  /// `-400` · `+9,500` · `0`
  ///
  /// 보합일 때는 시안과 같이 부호 없이 `0`으로 찍습니다.
  static String signedChange(int change) {
    if (change == 0) return '0';
    final String sign = change > 0 ? '+' : '-';
    return '$sign${_decimal.format(change.abs())}';
  }

  /// 부호를 뗀 등락액입니다.
  ///
  /// 상세 화면처럼 방향을 아이콘(▲ / ▼)으로 보여주는 자리에서 씁니다.
  static String absoluteChange(int change) => _decimal.format(change.abs());

  /// `-0.22%` · `+2.36%` · `0.00%`
  ///
  /// 부호는 등락률이 아니라 [direction]으로 정합니다. 등락률이 -0.001%처럼
  /// 반올림하면 0.00이 되는 값일 때 `-0.00%`가 찍히는 것을 막기 위해서입니다.
  static String signedRate(double ratePercent, PriceDirection direction) {
    if (direction == PriceDirection.flat) return '0.00%';
    final String sign = direction == PriceDirection.up ? '+' : '-';
    return '$sign${_twoDecimals.format(ratePercent.abs())}%';
  }

  /// `-400 (-0.22%)` — 관심 화면 행에 쓰는 조합입니다.
  static String changeWithRate(
    int change,
    double ratePercent,
    PriceDirection direction,
  ) {
    return '${signedChange(change)} (${signedRate(ratePercent, direction)})';
  }

  /// 거래량 축약. `29,113,466` → `29,113천`
  ///
  /// 시안이 천 단위로 축약하고 있어 그대로 따랐습니다. 1,000 미만이면
  /// 축약할 것이 없으므로 원래 값을 그대로 찍습니다.
  static String compactVolume(int volume) {
    if (volume >= 1000) return '${_decimal.format(volume ~/ 1000)}천';
    return _decimal.format(volume);
  }

  /// 시가총액 축약. `1,063,…` → `1,063조`
  ///
  /// 시안에는 조 단위만 나오지만, 소형주는 1조 미만이라 그대로 두면 `0조`가
  /// 되어 버립니다. 그래서 조 → 억 → 원 순으로 단위를 낮추도록 했습니다.
  static String compactMarketCap(int amount) {
    if (amount >= _jo) return '${_decimal.format(amount ~/ _jo)}조';
    if (amount >= _eok) return '${_decimal.format(amount ~/ _eok)}억';
    return _decimal.format(amount);
  }

  /// `03.27` — 일별 시세 표의 날짜 형식입니다.
  static String monthDay(DateTime date) => _monthDay.format(date);

  /// `20260911` — 앱 내부에서 거래일을 비교할 때 쓰는 정규화 형식입니다.
  static String compactDate(DateTime date) => _compactDate.format(date);
}
