import '../entities/mountain.dart';

class SearchMountains {
  const SearchMountains();

  List<Mountain> call(List<Mountain> source, String query) {
    final trimmed = query.trim().toLowerCase();
    if (trimmed.isEmpty) return source;
    return source
        .where((m) =>
            m.name.toLowerCase().contains(trimmed) ||
            m.description.toLowerCase().contains(trimmed))
        .toList(growable: false);
  }
}
