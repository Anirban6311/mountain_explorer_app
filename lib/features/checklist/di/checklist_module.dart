import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import '../data/datasources/checklist_remote_data_source.dart';
import '../data/repositories/checklist_repository_impl.dart';
import '../domain/repositories/checklist_repository.dart';
import '../domain/usecases/checklist_usecases.dart';
import '../presentation/cubit/checklist_cubit.dart';

void registerChecklistModule(GetIt getIt) {
  if (getIt.isRegistered<ChecklistRepository>()) return;

  getIt.registerLazySingleton<ChecklistRemoteDataSource>(
    () => FirestoreChecklistRemoteDataSource(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<ChecklistRepository>(
    () => ChecklistRepositoryImpl(getIt<ChecklistRemoteDataSource>()),
  );

  final repo = getIt<ChecklistRepository>();
  getIt.registerLazySingleton(() => WatchChecklist(repo));
  getIt.registerLazySingleton(() => AddChecklistItem(repo));
  getIt.registerLazySingleton(() => ToggleChecklistItem(repo));
  getIt.registerLazySingleton(() => DeleteChecklistItem(repo));

  getIt.registerLazySingleton<ChecklistCubit>(
    () => ChecklistCubit(
      watchChecklist: getIt<WatchChecklist>(),
      addChecklistItem: getIt<AddChecklistItem>(),
      toggleChecklistItem: getIt<ToggleChecklistItem>(),
      deleteChecklistItem: getIt<DeleteChecklistItem>(),
    ),
    dispose: (c) => c.close(),
  );
}
