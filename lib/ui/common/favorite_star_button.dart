import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 관심 등록 / 해제 별 아이콘입니다.
///
/// 검색 결과 행과 상세 화면 헤더가 같은 위젯을 씁니다. 어느 쪽에서 눌러도
/// 같은 상태(`favoritesProvider`)를 바꾸기 때문에 세 화면의 별이 함께
/// 바뀝니다.
class FavoriteStarButton extends StatelessWidget {
  const FavoriteStarButton({
    required this.isFavorite,
    required this.onTap,
    this.size = 24,
    super.key,
  });

  final bool isFavorite;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;

    return Semantics(
      button: true,
      label: isFavorite ? '관심 해제' : '관심 등록',
      child: InkResponse(
        onTap: onTap,
        radius: size,
        // 아이콘 자체는 작지만 손가락으로 누를 영역은 넉넉히 잡습니다.
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(
            isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
            size: size,
            color: isFavorite ? colors.favoriteActive : colors.favoriteInactive,
          ),
        ),
      ),
    );
  }
}
