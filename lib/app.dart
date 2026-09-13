import 'package:flutter/material.dart';

import 'theme/theme.dart';
import 'ui/common/app_bottom_nav.dart';
import 'ui/search/search_screen.dart';
import 'ui/watchlist/watchlist_screen.dart';

class EdencrewAssignmentApp extends StatelessWidget {
  const EdencrewAssignmentApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '이든크루 평가 과제',
      theme: AppTheme.dark,
      debugShowCheckedModeBanner: false,
      home: const HomeShell(),
    );
  }
}

/// 하단 탭 바가 붙어 있는 껍데기입니다. 관심 / 검색 화면을 바꿔 끼웁니다.
///
/// `IndexedStack`을 쓴 이유는 탭을 오갈 때 각 화면의 상태를 살려 두기
/// 위해서입니다. 검색어를 입력하고 관심 탭을 봤다가 돌아왔을 때 검색 결과와
/// 스크롤 위치가 그대로 남습니다.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.colors.surfaceBase,
      body: IndexedStack(
        index: _currentIndex,
        children: const <Widget>[WatchlistScreen(), SearchScreen()],
      ),
      bottomNavigationBar: AppBottomNav(
        currentIndex: _currentIndex,
        onSelect: (int index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
