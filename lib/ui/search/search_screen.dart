import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_exception.dart';
import '../../domain/stock_ref.dart';
import '../../state/favorites_provider.dart';
import '../../state/search_providers.dart';
import '../../theme/theme.dart';
import '../common/app_toast.dart';
import '../common/empty_state_view.dart';
import '../common/inline_error_banner.dart';
import '../detail/detail_screen.dart';
import 'widgets/search_field.dart';
import 'widgets/search_result_row.dart';

/// 종목 검색 화면입니다. (`02 · 검색`)
///
/// 한 화면이 네 가지 모습을 가집니다. 검색 전 · 결과 목록 · 결과 없음 ·
/// 조회 중이며, 어떤 모습인지는 검색어 상태와 요청 결과로 정해집니다.
class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final TextEditingController _controller = TextEditingController();

  /// 마지막으로 띄운 토스트입니다. 사라지는 동안에도 문구가 보여야 해서
  /// 숨길 때 `null`로 지우지 않고 [_isToastVisible]만 내립니다.
  ToastMessage? _toast;
  bool _isToastVisible = false;
  Timer? _toastTimer;

  @override
  void dispose() {
    _toastTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onToggleFavorite(StockRef stock) {
    final bool isNowFavorite = ref
        .read(favoritesProvider.notifier)
        .toggle(stock);

    _showToast(
      ToastMessage(
        text: isNowFavorite ? '관심이 등록되었습니다' : '관심이 해제되었습니다',
        icon: isNowFavorite ? Icons.star_rounded : Icons.star_border_rounded,
        iconColor: isNowFavorite
            ? context.colors.favoriteActive
            : context.colors.textSecondary,
      ),
    );
  }

  /// 토스트를 띄웁니다.
  ///
  /// 이미 떠 있으면 새로 쌓지 않고 내용만 바꾸고 타이머를 다시 시작합니다.
  /// 별을 연달아 누를 때 토스트가 겹쳐 목록을 계속 가리는 것을 막습니다.
  void _showToast(ToastMessage message) {
    _toastTimer?.cancel();
    setState(() {
      _toast = message;
      _isToastVisible = true;
    });

    _toastTimer = Timer(ToastPresenter.visibleDuration, () {
      if (!mounted) return;
      setState(() => _isToastVisible = false);
    });
  }

  void _openDetail(StockRef stock) {
    Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => DetailScreen(stock: stock)));
  }

  @override
  Widget build(BuildContext context) {
    final AppDimens dimens = context.dimens;
    final SearchQuery query = ref.watch(searchQueryProvider);
    final AsyncValue<List<StockRef>> results = ref.watch(searchResultsProvider);

    return SafeArea(
      bottom: false,
      child: Stack(
        children: <Widget>[
          Column(
            children: <Widget>[
              Padding(
                padding: EdgeInsets.fromLTRB(
                  dimens.space4,
                  dimens.space2,
                  dimens.space4,
                  dimens.space3,
                ),
                child: SearchField(
                  controller: _controller,
                  onChanged: (String value) =>
                      ref.read(searchQueryProvider.notifier).onChanged(value),
                  onClear: () {
                    _controller.clear();
                    ref.read(searchQueryProvider.notifier).clear();
                  },
                ),
              ),
              if (results.hasError)
                InlineErrorBanner(
                  message: userMessageOf(results.error!),
                  onRetry: () => ref.invalidate(searchResultsProvider),
                ),
              Expanded(child: _buildBody(query, results)),
            ],
          ),
          Positioned(
            left: dimens.space4,
            right: dimens.space4,
            bottom: dimens.space3,
            child: ToastPresenter(message: _toast, visible: _isToastVisible),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(SearchQuery query, AsyncValue<List<StockRef>> results) {
    // 1. 검색어를 입력하기 전 — `02 · 검색_empty`
    if (query.isEmpty) {
      return const EmptyStateView(
        icon: Icons.search_rounded,
        title: '종목을 검색해 보세요',
        description: '종목명 또는 종목코드 6자리로\n검색하실 수 있습니다.',
      );
    }

    final List<StockRef>? data = results.value;

    // 2. 첫 조회 중 — 이전 결과가 없을 때만 인디케이터를 보여줍니다.
    //    (이미 결과가 있는 상태에서 검색어를 고치면, 새 결과가 올 때까지
    //     이전 목록을 그대로 두는 편이 덜 어지럽습니다.)
    if (data == null) {
      return Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.colors.textTertiary,
          ),
        ),
      );
    }

    // 3. 결과 없음 — `02 · 검색결과_empty`
    if (data.isEmpty) {
      return EmptyStateView(
        icon: Icons.search_off_rounded,
        title: '검색 결과가 없습니다',
        description:
            "'${_forDisplay(query.committed)}'와\n"
            '일치하는 검색 결과를 찾지 못했습니다.',
      );
    }

    // 4. 결과 목록
    return ListView.builder(
      padding: EdgeInsets.zero,
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: data.length,
      itemBuilder: (BuildContext context, int index) {
        final StockRef stock = data[index];
        return SearchResultRow(
          stock: stock,
          query: query.committed,
          onTap: () => _openDetail(stock),
          onToggleFavorite: () => _onToggleFavorite(stock),
        );
      },
    );
  }

  /// 빈 상태 문구에 넣을 검색어를 다듬습니다.
  ///
  /// **검색어가 매우 길 때의 처리는 시안에 없어 직접 정했습니다.**
  /// 문구 전체에 말줄임을 걸면 `찾지 못했습니다`까지 잘려 무슨 말인지 알 수
  /// 없게 됩니다. 그래서 잘라내는 대상을 검색어로 한정했습니다. 안내 문장은
  /// 항상 온전히 보입니다.
  static String _forDisplay(String query) {
    const int maxLength = 20;
    if (query.length <= maxLength) return query;
    return '${query.substring(0, maxLength)}…';
  }
}
