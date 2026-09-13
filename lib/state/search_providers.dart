import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/stock_ref.dart';
import 'providers.dart';

/// 검색어 상태입니다.
///
/// 입력창에 보이는 값([raw])과 실제로 요청에 쓴 값([committed])을 나눠
/// 들고 있습니다. 나눈 이유는 두 가지입니다.
///
/// - 글자를 칠 때마다 요청이 나가지 않도록 디바운스를 걸어야 합니다.
/// - `검색 결과 없음` 문구에는 **요청에 쓴 검색어**가 들어가야 합니다.
///   입력창의 최신 값을 쓰면, 아직 결과를 받지 못한 검색어가 문구에 먼저
///   나타나 결과와 문구가 어긋납니다.
@immutable
class SearchQuery {
  const SearchQuery({required this.raw, required this.committed});

  const SearchQuery.empty()
      : raw = '',
        committed = '';

  /// 입력창에 보이는 값 그대로입니다.
  final String raw;

  /// 디바운스를 통과해 실제 요청에 쓰인 값입니다.
  final String committed;

  bool get isEmpty => raw.trim().isEmpty;

  SearchQuery copyWith({String? raw, String? committed}) => SearchQuery(
        raw: raw ?? this.raw,
        committed: committed ?? this.committed,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchQuery &&
          other.raw == raw &&
          other.committed == committed;

  @override
  int get hashCode => Object.hash(raw, committed);
}

class SearchQueryNotifier extends Notifier<SearchQuery> {
  /// 한글은 자모가 조합되는 동안에도 onChanged가 계속 불립니다.
  /// 300ms면 한 글자를 마저 조립할 시간은 되면서, 입력을 멈춘 뒤
  /// 기다린다는 느낌은 들지 않는 값이라 선택했습니다.
  static const Duration debounceDuration = Duration(milliseconds: 300);

  Timer? _debounce;

  @override
  SearchQuery build() {
    ref.onDispose(() => _debounce?.cancel());
    return const SearchQuery.empty();
  }

  void onChanged(String value) {
    _debounce?.cancel();

    // 입력을 지우면 기다리지 않고 바로 초기 상태로 되돌립니다.
    if (value.trim().isEmpty) {
      state = const SearchQuery.empty();
      return;
    }

    state = state.copyWith(raw: value);
    _debounce = Timer(
      debounceDuration,
      () => state = state.copyWith(committed: value.trim()),
    );
  }

  void clear() {
    _debounce?.cancel();
    state = const SearchQuery.empty();
  }
}

final NotifierProvider<SearchQueryNotifier, SearchQuery> searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, SearchQuery>(SearchQueryNotifier.new);

/// 검색 결과입니다.
///
/// [SearchQuery.committed]만 구독하므로, 타이핑 중에는 요청이 나가지 않고
/// 디바운스를 통과한 순간에만 한 번 실행됩니다.
final FutureProvider<List<StockRef>> searchResultsProvider =
    FutureProvider<List<StockRef>>((Ref ref) async {
  final String query =
      ref.watch(searchQueryProvider.select((SearchQuery it) => it.committed));
  if (query.isEmpty) return const <StockRef>[];

  final List<StockRef> results =
      await ref.watch(stockRepositoryProvider).search(query);

  // 검색 결과에서 바로 상세로 들어가는 경로가 있어서, 이름과 시장을 미리
  // 캐시에 넣어 둡니다. 상세 화면에서 메타데이터를 다시 받지 않아도 됩니다.
  for (final StockRef result in results) {
    ref.read(stockRepositoryProvider).cacheMeta(result);
  }
  return results;
});
