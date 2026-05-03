import 'package:equatable/equatable.dart';

class HomeState extends Equatable {
  final int tabIndex;
  const HomeState({this.tabIndex = 0});

  @override
  List<Object?> get props => [tabIndex];
}
