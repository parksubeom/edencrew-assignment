import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../domain/stock_ref.dart';
import 'providers.dart';

/// 관심 목록을 로컬에 저장합니다.
///
/// 종목코드만 저장하면 앱을 다시 켰을 때 이름과 시장을 보여주기 위해 종목
/// 수만큼 메타데이터를 다시 받아야 합니다. 그래서 [StockRef] 전체를
/// 저장합니다.
class FavoriteStorage {
  const FavoriteStorage(this._preferences);

  final SharedPreferences _preferences;

  /// 저장 형식이 바뀌면 키를 올려 이전 값을 무시할 수 있게 버전을 붙였습니다.
  static const String key = 'favorites.v1';

  /// 직렬화 규칙을 [FavoriteStorage] 밖에서도 쓸 수 있게 static으로 둡니다.
  /// (테스트에서 저장된 상태를 만들 때 같은 규칙을 다시 적지 않기 위해서입니다.)
  static String encode(List<StockRef> favorites) =>
      jsonEncode(<Map<String, dynamic>>[
        for (final StockRef favorite in favorites) favorite.toJson(),
      ]);

  static List<StockRef> decode(String? raw) {
    if (raw == null || raw.isEmpty) return const <StockRef>[];
    try {
      final List<dynamic> decoded = jsonDecode(raw) as List<dynamic>;
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(StockRef.fromJson)
          .toList();
    } catch (_) {
      // 저장된 값이 깨졌다면 관심 목록이 비어 있는 상태로 시작합니다.
      // 앱이 못 뜨는 것보다 낫습니다.
      return const <StockRef>[];
    }
  }

  List<StockRef> load() => decode(_preferences.getString(key));

  Future<void> save(List<StockRef> favorites) =>
      _preferences.setString(key, encode(favorites));
}

final Provider<FavoriteStorage> favoriteStorageProvider =
    Provider<FavoriteStorage>(
      (Ref ref) => FavoriteStorage(ref.watch(sharedPreferencesProvider)),
    );

/// 앱 전체가 공유하는 관심 목록입니다.
///
/// 관심 화면 · 검색 화면 · 상세 화면이 모두 이 하나를 바라보기 때문에,
/// 어느 화면에서 별을 눌러도 세 화면의 별 아이콘이 함께 바뀝니다.
/// 화면마다 별도의 상태를 두지 않은 것이 상태 동기화 요구사항에 대한 답입니다.
class FavoritesNotifier extends Notifier<List<StockRef>> {
  @override
  List<StockRef> build() => ref.read(favoriteStorageProvider).load();

  bool contains(String symbol) =>
      state.any((StockRef favorite) => favorite.symbol == symbol);

  /// 관심을 등록하거나 해제합니다.
  ///
  /// 토스트 문구를 고르려면 "누른 결과가 등록인지 해제인지"를 알아야 해서,
  /// 등록되었으면 `true`를 돌려줍니다.
  bool toggle(StockRef stock) {
    final bool wasFavorite = contains(stock.symbol);
    state = wasFavorite
        ? <StockRef>[
            for (final StockRef favorite in state)
              if (favorite.symbol != stock.symbol) favorite,
          ]
        // 새로 등록한 종목은 뒤에 붙입니다. 정렬 기준이 `가나다순`이 아니어도
        // 방금 추가한 항목이 목록 어딘가로 사라지지 않게 하기 위해서입니다.
        : <StockRef>[...state, stock];

    unawaited(ref.read(favoriteStorageProvider).save(state));
    return !wasFavorite;
  }

  /// 저장 실패가 화면을 막지 않도록 결과를 기다리지 않습니다.
  /// 관심 목록은 메모리 상태가 이미 바뀌어 있고, 저장은 다음 실행을 위한
  /// 부수 작업이기 때문입니다.
  static void unawaited(Future<void> future) {
    future.catchError((Object _) {});
  }
}

final NotifierProvider<FavoritesNotifier, List<StockRef>> favoritesProvider =
    NotifierProvider<FavoritesNotifier, List<StockRef>>(FavoritesNotifier.new);

/// 특정 종목이 관심인지만 구독합니다.
///
/// 목록 전체를 구독하면 다른 종목이 추가될 때마다 모든 별 아이콘이 다시
/// 그려집니다. `select`로 필요한 값만 보게 해서 그 리빌드를 막습니다.
bool watchIsFavorite(WidgetRef ref, String symbol) => ref.watch(
  favoritesProvider.select(
    (List<StockRef> favorites) =>
        favorites.any((StockRef favorite) => favorite.symbol == symbol),
  ),
);
