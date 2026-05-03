import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import '../../../core/services/battery_service.dart';
import '../../../core/services/connectivity_service.dart';
import '../../../core/services/location_service.dart';
import '../../../core/storage/local_db.dart';
import '../../trek/domain/repositories/trek_repository.dart';
import '../../trek/domain/usecases/latest_trek_breadcrumbs.dart';
import '../data/datasources/emergency_contacts_remote_data_source.dart';
import '../data/datasources/sms_data_source.dart';
import '../data/datasources/sos_alerts_remote_data_source.dart';
import '../data/datasources/sos_breadcrumbs_remote_data_source.dart';
import '../data/datasources/sos_outbox_local_data_source.dart';
import '../data/repositories/emergency_contacts_repository_impl.dart';
import '../data/repositories/sos_outbox_repository_impl.dart';
import '../data/repositories/sos_repository_impl.dart';
import '../data/repositories/sos_tracking_repository_impl.dart';
import '../domain/repositories/emergency_contacts_repository.dart';
import '../domain/repositories/sos_outbox_repository.dart';
import '../domain/repositories/sos_repository.dart';
import '../domain/repositories/sos_tracking_repository.dart';
import '../domain/usecases/add_contact.dart';
import '../domain/usecases/cancel_sos.dart';
import '../domain/usecases/delete_contact.dart';
import '../domain/usecases/fire_sos.dart';
import '../domain/usecases/flush_expired_alerts.dart';
import '../domain/usecases/process_sos_outbox.dart';
import '../domain/usecases/set_primary_contact.dart';
import '../domain/usecases/start_sos_tracking.dart';
import '../domain/usecases/stop_sos_tracking.dart';
import '../domain/usecases/update_contact.dart';
import '../domain/usecases/watch_active_sos_alert.dart';
import '../domain/usecases/watch_contacts.dart';
import '../presentation/cubit/emergency_contacts_cubit.dart';
import '../presentation/cubit/sos_cubit.dart';

void registerSosModule(GetIt getIt) {
  if (getIt.isRegistered<SosRepository>()) return;

  getIt.registerLazySingleton<EmergencyContactsRemoteDataSource>(
    () => FirestoreEmergencyContactsRemoteDataSource(
      getIt<FirebaseFirestore>(),
    ),
  );
  getIt.registerLazySingleton<SosAlertsRemoteDataSource>(
    () => FirestoreSosAlertsRemoteDataSource(getIt<FirebaseFirestore>()),
  );
  getIt.registerLazySingleton<SmsDataSource>(
    () => const UrlLauncherSmsDataSource(),
  );
  getIt.registerLazySingleton<SosOutboxLocalDataSource>(
    () => SqfliteSosOutboxLocalDataSource(getIt<LocalDb>()),
  );
  getIt.registerLazySingleton<SosBreadcrumbsRemoteDataSource>(
    () => FirestoreSosBreadcrumbsRemoteDataSource(getIt<FirebaseFirestore>()),
  );

  getIt.registerLazySingleton<EmergencyContactsRepository>(
    () => EmergencyContactsRepositoryImpl(
      ds: getIt<EmergencyContactsRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<SosOutboxRepository>(
    () => SosOutboxRepositoryImpl(
      localDs: getIt<SosOutboxLocalDataSource>(),
      remoteDs: getIt<SosAlertsRemoteDataSource>(),
    ),
  );
  getIt.registerLazySingleton<SosRepository>(
    () => SosRepositoryImpl(
      location: getIt<LocationService>(),
      battery: getIt<BatteryService>(),
      sms: getIt<SmsDataSource>(),
      alertsDs: getIt<SosAlertsRemoteDataSource>(),
      outbox: getIt<SosOutboxRepository>(),
      latestBreadcrumbs: getIt<LatestTrekBreadcrumbs>(),
    ),
  );
  // Iter 5b: live SOS-active breadcrumb stream. Mutually exclusive with
  // Trek's stream (decision #47) — coordinated via TrekRepository's
  // suspend()/resume() methods.
  getIt.registerLazySingleton<SosTrackingRepository>(
    () => SosTrackingRepositoryImpl(
      location: getIt<LocationService>(),
      battery: getIt<BatteryService>(),
      breadcrumbs: getIt<SosBreadcrumbsRemoteDataSource>(),
      trek: getIt<TrekRepository>(),
    ),
    dispose: (r) async {
      if (r is SosTrackingRepositoryImpl) await r.dispose();
    },
  );

  final contactsRepo = getIt<EmergencyContactsRepository>();
  getIt.registerLazySingleton(() => WatchContacts(contactsRepo));
  getIt.registerLazySingleton(() => AddContact(contactsRepo));
  getIt.registerLazySingleton(() => UpdateContact(contactsRepo));
  getIt.registerLazySingleton(() => DeleteContact(contactsRepo));
  getIt.registerLazySingleton(() => SetPrimaryContact(contactsRepo));

  final sosRepo = getIt<SosRepository>();
  getIt.registerLazySingleton(() => FireSos(sosRepo));
  getIt.registerLazySingleton(() => CancelSos(sosRepo));
  getIt.registerLazySingleton(() => FlushExpiredAlerts(sosRepo));
  getIt.registerLazySingleton(
    () => ProcessSosOutbox(getIt<SosOutboxRepository>()),
  );

  final trackingRepo = getIt<SosTrackingRepository>();
  getIt.registerLazySingleton(() => StartSosTracking(trackingRepo));
  getIt.registerLazySingleton(() => StopSosTracking(trackingRepo));
  getIt.registerLazySingleton(() => WatchActiveSosAlert(trackingRepo));

  getIt.registerFactory<EmergencyContactsCubit>(
    () => EmergencyContactsCubit(
      watch: getIt<WatchContacts>(),
      addContact: getIt<AddContact>(),
      updateContact: getIt<UpdateContact>(),
      deleteContact: getIt<DeleteContact>(),
      setPrimary: getIt<SetPrimaryContact>(),
    ),
  );

  // SosCubit is a singleton: it owns the connectivity subscription that
  // drives outbox retry, and survives navigation across the FAB,
  // countdown dialog, and (Iter 5) post-dispatch banner.
  getIt.registerLazySingleton<SosCubit>(
    () => SosCubit(
      fireSos: getIt<FireSos>(),
      cancelSos: getIt<CancelSos>(),
      processOutbox: getIt<ProcessSosOutbox>(),
      outbox: getIt<SosOutboxRepository>(),
      connectivity: getIt<ConnectivityService>(),
      location: getIt<LocationService>(),
      startTracking: getIt<StartSosTracking>(),
      stopTracking: getIt<StopSosTracking>(),
      flushExpired: getIt<FlushExpiredAlerts>(),
    ),
    dispose: (c) => c.close(),
  );
}
