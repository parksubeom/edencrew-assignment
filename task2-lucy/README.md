# 과제 2 — Lucy Studio `목표가 알림`

메일에 zip을 첨부하려고 했으나, Gmail이 압축 파일 안의 `assets/script/common.js`
(Lucy 프로젝트 템플릿에 원래 포함된 파일)를 이유로 첨부 자체를 차단해서
여기에 함께 올려 둡니다.

## 파일

| 파일 | 설명 |
| --- | --- |
| [`targetAlert_assets.zip`](targetAlert_assets.zip) | 제출물. `cloneProject/assets` 전체를 압축한 것으로, 메일에 첨부하려던 파일과 동일합니다. |

압축을 풀면 최상위가 `assets/` 입니다. Lucy Studio에서 클론한 프로젝트의
`assets` 폴더를 이것으로 교체하면 됩니다.

## 들어 있는 것

```
assets/
├── page/
│   ├── targetAlert.lfp          # 목표가 알림 화면
│   └── targetAlertDialog.lfp    # 목표가 알림 추가 다이얼로그
├── component/
│   └── C001.lfc                 # 목록 행 컴포넌트 (아래 "남은 것" 참고)
└── theme/
    └── color_themes.json        # 과제 1의 디자인 토큰 15개를 등록
```

페이지 이름은 `targetAlert` 입니다.

## 구현한 것

- 빈 상태 / 등록 다이얼로그 / 등록된 목록 세 가지 상태
- 우측 상단 `+` → `openSizedDialog`로 추가 다이얼로그, 입력값을 목록에 반영
- 과제 1의 디자인 토큰 15개를 `color_themes.json`에 등록하고 화면에서 참조
- 실기기(Lucy Player)에서 동작 확인

실기기에서 확인하며 고친 것들:

- 헤더가 상태 표시줄 아래로 들어가서 `SafeArea` + `Jet.backgroundColor` 적용
- `TextField` 테두리가 두 겹으로 보여서 decoration만 사용하도록 수정
- 키보드가 입력창을 덮어서 다이얼로그를 `openSizedDialog(320, 340)` + `ScrollView`로 변경

## 남은 것

**"행을 컴포넌트로 분리" 항목은 완성하지 못했습니다.**

`Component` 위젯으로 `C001.lfc`를 참조하면, 페이지 스크립트에서 컴포넌트
내부 위젯에 접근할 수 없어(`row_name is not defined`) 목록이 채워지지
않았습니다. 문서를 다시 읽어 보니 `Component`와 `FormContainer`는 각각
독립된 컨텍스트라 "부모에서 위젯에 직접 접근할 수 없습니다"라고 되어 있고,
그 경우의 정식 해법인 **노출 변수 + 속성 바인딩**은 Binding 탭이 Free
플랜에서 비활성이라 등록할 수 없었습니다.

동작하는 쪽을 우선해서 `ListView`의 행 템플릿을 인라인으로 두었고,
분리해 둔 `C001.lfc`는 작업 흔적으로 zip에 함께 넣어 두었습니다.
Free 플랜에서 가능한 다른 경로가 있다면 알려주시면 보완하겠습니다.
