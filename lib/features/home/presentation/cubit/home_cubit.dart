import 'package:flutter_bloc/flutter_bloc.dart';

import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  static const int tabCount = 5;
  // Home / Mountains / Map / Community / Profile

  HomeCubit() : super(const HomeState());

  void selectTab(int index) {
    final clamped = index.clamp(0, tabCount - 1);
    if (clamped == state.tabIndex) return;
    emit(HomeState(tabIndex: clamped));
  }
}
