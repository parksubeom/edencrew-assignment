import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../domain/stock_ref.dart';
import '../../../state/favorites_provider.dart';
import '../../../theme/theme.dart';
import '../../common/favorite_star_button.dart';
import 'highlighted_name.dart';

/// 검색 결과의 행 하나입니다.
///
/// 관심 여부를 이 행이 직접 구독합니다(`select`). 관심 목록 전체를 구독하면
/// 다른 종목의 별을 눌렀을 때 결과 목록 전체가 다시 그려지기 때문입니다.
/// 검색 직후에도 현재 관심 상태가 그대로 반영되는 것은, 별 모양이 검색
/// 응답이 아니라 `favoritesProvider`에서 나오기 때문입니다.
class SearchResultRow extends ConsumerWidget {
  const SearchResultRow({
    required this.stock,
    required this.query,
    required this.onTap,
    required this.onToggleFavorite,
    super.key,
  });

  final StockRef stock;

  /// 이름에서 하이라이트할 검색어입니다.
  final String query;

  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;
    final bool isFavorite = watchIsFavorite(ref, stock.symbol);

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
            padding: EdgeInsets.only(
              left: dimens.space4,
              right: dimens.space2,
              top: dimens.space3,
              bottom: dimens.space3,
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      HighlightedName(
                        name: stock.name,
                        query: query,
                        style: TextStyle(
                          color: colors.textPrimary,
                          fontSize: 16,
                          fontWeight: AppTypography.medium,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        stock.symbolWithMarket,
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
                  ),
                ),
                SizedBox(width: dimens.space2),
                FavoriteStarButton(
                  isFavorite: isFavorite,
                  onTap: onToggleFavorite,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
