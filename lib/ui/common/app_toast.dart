import 'package:flutter/material.dart';

import '../../theme/theme.dart';

/// 토스트에 띄울 내용입니다.
@immutable
class ToastMessage {
  const ToastMessage({
    required this.text,
    required this.icon,
    required this.iconColor,
  });

  final String text;
  final IconData icon;
  final Color iconColor;
}

/// 화면 하단에 잠깐 떠 있는 알림입니다.
///
/// 시안에는 떠 있는 모습만 있고 **얼마나 보이는지, 어떻게 사라지는지는
/// 정의되어 있지 않습니다.** 다음과 같이 정했습니다.
///
/// - 노출 시간 2초. 짧은 한 줄이라 읽기에 충분하고, 목록을 가리는 시간이
///   길어지지 않는 값입니다.
/// - 등장 · 퇴장은 180ms 동안 아래에서 살짝 올라오며 페이드합니다.
///   위치가 바뀌는 것이 아니라 나타났다 사라지는 것임을 보여주기 위해서입니다.
/// - 토스트가 떠 있는 동안 다른 종목의 별을 누르면, 새로 쌓지 않고 **내용만
///   바꾸고 타이머를 다시 시작**합니다. 별을 연달아 누를 때 토스트가 겹쳐
///   쌓이면 목록을 계속 가리기 때문입니다.
/// - 토스트는 탭 바 위에 뜹니다. 탭 바를 가리면 화면 전환이 막힙니다.
class AppToast extends StatelessWidget {
  const AppToast({required this.message, super.key});

  final ToastMessage message;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final AppDimens dimens = context.dimens;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: dimens.space4,
        vertical: dimens.space3,
      ),
      decoration: BoxDecoration(
        color: colors.surfaceOverlay,
        borderRadius: BorderRadius.circular(dimens.radiusLg),
      ),
      child: Row(
        children: <Widget>[
          Icon(message.icon, size: dimens.iconMd, color: message.iconColor),
          SizedBox(width: dimens.space2),
          Expanded(
            child: Text(
              message.text,
              style: TextStyle(
                color: colors.textPrimary,
                fontSize: 14,
                fontWeight: AppTypography.medium,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// 토스트의 등장 · 퇴장을 맡는 껍데기입니다.
///
/// 타이머는 이 위젯을 쓰는 화면이 관리합니다. 어떤 동작에 대한 토스트인지는
/// 화면이 알고 있고, 이 위젯은 보여주는 일만 하도록 나눴습니다.
///
/// [message]와 [visible]을 나눠 받는 이유는 **퇴장 애니메이션** 때문입니다.
/// 사라지는 180ms 동안에도 마지막 문구가 보여야 하므로, 숨길 때는 [visible]만
/// `false`로 내리고 [message]는 그대로 둡니다.
class ToastPresenter extends StatelessWidget {
  const ToastPresenter({
    required this.message,
    required this.visible,
    super.key,
  });

  static const Duration visibleDuration = Duration(seconds: 2);
  static const Duration transitionDuration = Duration(milliseconds: 180);

  /// 마지막으로 띄운 내용입니다. 한 번도 띄운 적이 없을 때만 `null`입니다.
  final ToastMessage? message;

  final bool visible;

  @override
  Widget build(BuildContext context) {
    final ToastMessage? current = message;
    if (current == null) return const SizedBox.shrink();

    return IgnorePointer(
      child: AnimatedSlide(
        duration: transitionDuration,
        curve: Curves.easeOut,
        offset: visible ? Offset.zero : const Offset(0, 0.4),
        child: AnimatedOpacity(
          duration: transitionDuration,
          opacity: visible ? 1 : 0,
          child: AppToast(message: current),
        ),
      ),
    );
  }
}
