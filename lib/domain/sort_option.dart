/// 관심 목록 정렬 기준입니다. 시안의 정렬 바텀시트 항목과 1:1로 대응합니다.
enum SortOption {
  price('현재가순'),
  changeRate('등락률순'),
  name('가나다순');

  const SortOption(this.label);

  /// 바텀시트 항목과 헤더 칩에 함께 쓰는 문구입니다.
  final String label;

  /// 저장해 둔 값을 되살릴 때 씁니다. 모르는 값이면 기본값으로 떨어집니다.
  static SortOption fromStorage(String? name) => SortOption.values.firstWhere(
        (SortOption option) => option.name == name,
        orElse: () => SortOption.name,
      );
}
