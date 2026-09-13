import 'package:flutter/material.dart';

import '../../../core/formatters.dart';
import '../../../domain/quote.dart';
import '../../../state/watchlist_providers.dart';
import '../../../theme/theme.dart';
import '../../common/price_colors.dart';
import '../../common/skeleton_box.dart';

/// 관심 목록의 행 하나입니다.
///
/// 시세를 아직 받지 못했으면(`item.quote == null`) 오른쪽을 스켈레톤으로
/// 그립니다. 스켈레톤과 실제 값의 높이를 같게 맞춰, 시세가 도착해도 행이
/// 덜컥 움직이지 않게 했습니다.
class WatchlistRow extends StatelessWidget {
  const WatchlistRow({required this.item, required this.onTap, super.key});

  final WatchlistItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return InkWell(
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: colors.borderSubtle,
              width: dimens.borderHairline,
            ),
          ),
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: dimens.rowMinHeight),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: dimens.space4,
              vertical: 10,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: <Widget>[
                Expanded(child: _StockLabel(item: item)),
                SizedBox(width: dimens.space3),
                if (item.quote case final Quote quote)
                  _PriceLabel(quote: quote)
                else
                  const _PriceSkeleton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// 왼쪽: 종목명과 `종목코드 · 시장`
class _StockLabel extends StatelessWidget {
  const _StockLabel({required this.item});

  final WatchlistItem item;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          item.stock.name,
          // 긴 종목명은 줄바꿈하지 않고 말줄임합니다. 행 높이가 종목마다
          // 달라지면 목록의 리듬이 깨지고, 오른쪽 시세와 세로 정렬도
          // 어긋나기 때문입니다.
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: AppTypography.medium,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          item.stock.symbolWithMarket,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.textTertiary,
            fontSize: 12,
            fontWeight: AppTypography.regular,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

/// 오른쪽: 현재가와 `등락액 (등락률)`
class _PriceLabel extends StatelessWidget {
  const _PriceLabel({required this.quote});

  final Quote quote;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Text(
          Formatters.price(quote.currentPrice),
          style: TextStyle(
            color: colors.textPrimary,
            fontSize: 16,
            fontWeight: AppTypography.medium,
            height: 1.35,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          Formatters.changeWithRate(
            quote.change,
            quote.changeRatePercent,
            quote.direction,
          ),
          style: TextStyle(
            color: colors.textColorOf(quote.direction),
            fontSize: 12,
            fontWeight: AppTypography.regular,
            height: 1.35,
          ),
        ),
      ],
    );
  }
}

class _PriceSkeleton extends StatelessWidget {
  const _PriceSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SkeletonBox(width: 66, height: 16),
        SizedBox(height: 4),
        SkeletonBox(width: 48, height: 12),
      ],
    );
  }
}
