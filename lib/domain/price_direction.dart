/// 등락 방향입니다.
///
/// 국내 시장 관행을 따라 **상승은 빨강, 하락은 파랑**으로 표시합니다.
/// 색상 토큰은 `AppColors.priceUp* / priceDown* / priceFlat*`에 대응합니다.
enum PriceDirection {
  up,
  down,
  flat;

  /// 등락액으로 방향을 정합니다.
  ///
  /// 등락률로 정하지 않는 이유는, 반올림해서 0.00%로 보이는 값도 실제로는
  /// 등락이 있을 수 있어 색과 부호가 어긋날 수 있기 때문입니다.
  static PriceDirection ofChange(num change) {
    if (change > 0) return PriceDirection.up;
    if (change < 0) return PriceDirection.down;
    return PriceDirection.flat;
  }
}
