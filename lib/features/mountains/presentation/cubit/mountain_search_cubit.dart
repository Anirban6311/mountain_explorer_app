import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/mountain.dart';
import '../../domain/usecases/search_mountains.dart';
import 'mountain_search_state.dart';

class MountainSearchCubit extends Cubit<MountainSearchState> {
  final SearchMountains _searchMountains;

  MountainSearchCubit({required SearchMountains searchMountains})
      : _searchMountains = searchMountains,
        super(const MountainSearchState());

  void setSource(List<Mountain> source) {
    emit(MountainSearchState(
      source: source,
      query: state.query,
      results: _searchMountains(source, state.query),
    ));
  }

  void updateQuery(String query) {
    emit(MountainSearchState(
      source: state.source,
      query: query,
      results: _searchMountains(state.source, query),
    ));
  }
}
