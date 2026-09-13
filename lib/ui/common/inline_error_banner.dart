import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 목록 위에 얇게 깔리는 오류 안내입니다.
///
/// **Figma에 네트워크 에러 상태가 없어 직접 정한 부분입니다.**
/// 화면 전체를 에러로 덮지 않고 띠 하나만 얹은 이유는, 시세 조회가 실패해도
/// 관심 목록 자체(종목명 · 코드)는 로컬에 있어 계속 보여줄 수 있기
/// 때문입니다. 이미 받아 둔 시세가 있다면 그것도 그대로 남습니다.
/// 색은 `feedbackWarning`을 씁니다.
class InlineErrorBanner extends StatelessWidget {
  const InlineErrorBanner({
    required this.message,
    required this.onRetry,
    super.key,
  });

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      width: double.infinity,
      color: colors.surfaceRaised,
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space3,
      ),
      child: Row(
        children: <Widget>[
          Icon(
            Icons.error_outline_rounded,
            size: dimens.iconSm,
            color: colors.feedbackWarning,
          ),
          SizedBox(width: dimens.space2),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: colors.textSecondary,
                fontSize: 13,
                fontWeight: AppTypography.regular,
                height: 1.4,
              ),
            ),
          ),
          SizedBox(width: dimens.space2),
          InkWell(
            onTap: onRetry,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: dimens.space2,
                vertical: dimens.space1,
              ),
              child: Text(
                '다시 시도',
                style: TextStyle(
                  color: colors.accentDefault,
                  fontSize: 13,
                  fontWeight: AppTypography.medium,
                  height: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
