import 'dart:async';

import 'package:basic_crud_flutter/features/mountains/domain/repositories/mountains_repository.dart';
import 'package:basic_crud_flutter/features/mountains/domain/usecases/watch_liked_mountain_ids.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockRepo extends Mock implements MountainsRepository {}

void main() {
  late _MockRepo repo;
  late WatchLikedMountainIds usecase;

  setUp(() {
    repo = _MockRepo();
    usecase = WatchLikedMountainIds(repo);
  });

  test('forwards the repo stream', () async {
    final controller = StreamController<Set<String>>();
    when(() => repo.watchLikedMountainIds(any()))
        .thenAnswer((_) => controller.stream);

    final received = <Set<String>>[];
    final sub = usecase('u1').listen(received.add);

    controller.add({'shimla'});
    controller.add({'shimla', 'manali'});
    await Future<void>.delayed(Duration.zero);

    expect(received, [
      {'shimla'},
      {'shimla', 'manali'},
    ]);
    await sub.cancel();
    await controller.close();
  });
}
