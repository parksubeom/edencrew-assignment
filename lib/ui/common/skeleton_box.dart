import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 아직 값을 받지 못한 자리를 채우는 회색 막대입니다. (`feedbackSkeleton`)
///
/// 값이 들어올 자리와 같은 높이를 차지해서, 시세가 도착했을 때 행의 높이가
/// 바뀌지 않도록 합니다.
class SkeletonBox extends StatelessWidget {
  const SkeletonBox({
    required this.width,
    required this.height,
    super.key,
  });

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.colors.feedbackSkeleton,
        borderRadius: BorderRadius.circular(context.dimens.radiusSm),
      ),
    );
  }
}
