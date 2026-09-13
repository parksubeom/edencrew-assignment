import 'package:flutter/material.dart';

import '../../domain/price_direction.dart';
import '../../theme/theme.dart';

/// 등락 방향에 맞는 토큰을 골라 줍니다.
///
/// 상승 / 하락 / 보합 세 갈래를 화면마다 다시 쓰지 않도록 모아 두었습니다.
/// **상승이 빨강, 하락이 파랑**이라는 국내 시장 관행이 한곳에만 적히도록
/// 하는 목적도 있습니다.
extension PriceDirectionColors on AppColors {
  Color textColorOf(PriceDirection direction) => switch (direction) {
    PriceDirection.up => priceUpText,
    PriceDirection.down => priceDownText,
    PriceDirection.flat => priceFlatText,
  };

  Color backgroundColorOf(PriceDirection direction) => switch (direction) {
    PriceDirection.up => priceUpBg,
    PriceDirection.down => priceDownBg,
    PriceDirection.flat => priceFlatBg,
  };

  Color chartColorOf(PriceDirection direction) => switch (direction) {
    PriceDirection.up => chartLineUp,
    PriceDirection.down => chartLineDown,
    PriceDirection.flat => chartLineFlat,
  };
}

/// 상세 화면 현재가 옆에 붙는 방향 아이콘입니다. (▲ / ▼)
///
/// 보합일 때는 시안에 아이콘이 없어 표시하지 않습니다.
IconData? priceDirectionIcon(PriceDirection direction) => switch (direction) {
  PriceDirection.up => Icons.arrow_drop_up,
  PriceDirection.down => Icons.arrow_drop_down,
  PriceDirection.flat => null,
};
