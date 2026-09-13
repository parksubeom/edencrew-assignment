import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/naver_http_client.dart';
import '../data/naver_stock_api.dart';
import '../data/stock_repository.dart';

/// 앱이 쓰는 의존성을 한곳에 묶어 둔 파일입니다.
///
/// 화면은 여기 정의된 provider만 바라보고, 구현체를 직접 만들지 않습니다.
/// 테스트에서 `overrideWith`로 가짜 구현을 끼우기 위해서입니다.

/// `main()`에서 실제 인스턴스로 덮어씁니다.
///
/// [SharedPreferences.getInstance]가 비동기라 `Notifier.build()`(동기)에서
/// 바로 쓸 수 없습니다. 그래서 앱을 띄우기 전에 한 번 받아 두고 주입하는
/// 방식을 택했습니다.
final Provider<SharedPreferences> sharedPreferencesProvider =
    Provider<SharedPreferences>(
      (Ref ref) => throw UnimplementedError(
        'main()에서 sharedPreferencesProvider를 덮어써야 합니다.',
      ),
    );

final Provider<NaverHttpClient> naverHttpClientProvider =
    Provider<NaverHttpClient>((Ref ref) {
      final NaverHttpClient client = NaverHttpClient();
      ref.onDispose(client.close);
      return client;
    });

final Provider<NaverStockApi> naverStockApiProvider = Provider<NaverStockApi>(
  (Ref ref) => NaverStockApi(ref.watch(naverHttpClientProvider)),
);

/// 캐시를 들고 있어야 하므로 앱이 사는 동안 하나만 존재해야 합니다.
/// (autoDispose를 쓰지 않는 이유입니다.)
final Provider<StockRepository> stockRepositoryProvider =
    Provider<StockRepository>(
      (Ref ref) => StockRepository(ref.watch(naverStockApiProvider)),
    );
