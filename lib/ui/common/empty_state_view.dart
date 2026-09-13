import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 관심 · 검색 · 검색결과 세 화면이 공유하는 빈 상태입니다.
///
/// 아이콘 · 제목 · 안내 문구의 구성이 셋 다 같아서 한 위젯으로 묶었습니다.
/// 문구만 달라집니다.
class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    required this.icon,
    required this.title,
    required this.description,
    super.key,
  });

  final IconData icon;

  /// `관심 종목이 없습니다` 처럼 굵게 들어가는 한 줄입니다.
  final String title;

  /// 제목 아래 두 줄 안내입니다. 줄바꿈은 호출하는 쪽에서 넣습니다.
  final String description;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: dimens.space6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Icon(icon, size: 44, color: colors.textDisabled),
            SizedBox(height: dimens.space4),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 18,
                fontWeight: AppTypography.bold,
                height: 1.4,
              ),
            ),
            SizedBox(height: dimens.space2),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.textTertiary,
                fontSize: 13,
                fontWeight: AppTypography.regular,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
