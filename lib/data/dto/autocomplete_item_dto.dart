import '../../domain/stock_ref.dart';
import 'json_reader.dart';

/// `GET https://ac.stock.naver.com/ac` 의 `items[]` 한 건입니다.
///
/// 응답에는 국내 주식뿐 아니라 해외 종목 · 지수 · 시장지표가 함께 들어오기
/// 때문에, 이 DTO는 원본을 그대로 담기만 하고 걸러내는 판단은
/// [isDomesticStock]에 모아 두었습니다.
class AutocompleteItemDto {
  const AutocompleteItemDto({
    required this.code,
    required this.name,
    required this.typeCode,
    required this.typeName,
    required this.url,
    required this.nationCode,
    required this.category,
  });

  factory AutocompleteItemDto.fromJson(Map<String, dynamic> json) =>
      AutocompleteItemDto(
        code: JsonReader.stringOr(json['code']),
        name: JsonReader.stringOr(json['name']),
        typeCode: JsonReader.stringOr(json['typeCode']),
        typeName: JsonReader.stringOr(json['typeName']),
        url: JsonReader.stringOr(json['url']),
        nationCode: JsonReader.stringOr(json['nationCode']),
        category: JsonReader.stringOr(json['category']),
      );

  final String code;
  final String name;
  final String typeCode;

  /// `코스피` · `코스닥` 처럼 화면에 그대로 쓰는 시장명입니다.
  final String typeName;
  final String url;

  /// `KOR`이면 국내입니다.
  final String nationCode;

  /// `stock` · `index` · `marketindicator` 등입니다.
  final String category;

  static final RegExp _sixDigits = RegExp(r'^\d{6}$');

  /// 국내 주식이면서 6자리 종목코드를 가진 항목만 통과시킵니다.
  ///
  /// 지수(`index`)와 시장지표(`marketindicator`)는 상세 화면에서 쓰는
  /// 시세 · 일별 시세 endpoint가 받지 않는 코드라, 검색 결과에 남겨 두면
  /// 눌렀을 때 빈 화면이 됩니다. 그래서 여기서 걸러냅니다.
  bool get isDomesticStock =>
      nationCode == 'KOR' &&
      category == 'stock' &&
      _sixDigits.hasMatch(code);

  StockRef toDomain() =>
      StockRef(symbol: code, name: name, market: typeName);
}
