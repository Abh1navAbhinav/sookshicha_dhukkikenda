// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:cloud_firestore/cloud_firestore.dart' as _i974;
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:firebase_auth/firebase_auth.dart' as _i59;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

import 'core/network/api_client.dart' as _i871;
import 'core/network/network_info.dart' as _i75;
import 'core/services/firebase_auth_service.dart' as _i560;
import 'core/services/firebase_initializer.dart' as _i959;
import 'core/services/firestore_config.dart' as _i348;
import 'core/services/firestore_service.dart' as _i535;
import 'core/services/local_storage_service.dart' as _i473;
import 'data/datasources/contract_firestore_datasource.dart' as _i445;
import 'data/datasources/monthly_snapshot_firestore_datasource.dart' as _i141;
import 'data/repositories/contract_repository_impl.dart' as _i364;
import 'data/repositories/monthly_snapshot_repository_impl.dart' as _i999;
import 'domain/repositories/contract_repository.dart' as _i875;
import 'domain/repositories/monthly_snapshot_repository.dart' as _i863;
import 'injection.dart' as _i464;
import 'presentation/bloc/add_contract/add_contract_cubit.dart' as _i136;
import 'presentation/bloc/auth/auth_cubit.dart' as _i501;
import 'presentation/bloc/contract_detail/contract_detail_cubit.dart' as _i604;
import 'presentation/bloc/contracts/contracts_cubit.dart' as _i151;
import 'presentation/bloc/dashboard/dashboard_cubit.dart' as _i989;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final firebaseModule = _$FirebaseModule();
    final registerModule = _$RegisterModule();
    gh.lazySingleton<_i59.FirebaseAuth>(() => firebaseModule.firebaseAuth);
    gh.lazySingleton<_i974.FirebaseFirestore>(
      () => firebaseModule.firebaseFirestore,
    );
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i473.LocalStorageService>(
      () => _i473.LocalStorageServiceImpl(),
    );
    gh.lazySingleton<_i535.FirestoreService>(
      () => _i535.FirestoreServiceImpl(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i560.FirebaseAuthService>(
      () => _i560.FirebaseAuthServiceImpl(gh<_i59.FirebaseAuth>()),
    );
    gh.lazySingleton<_i348.FirestorePersistenceManager>(
      () =>
          _i348.FirestorePersistenceManagerImpl(gh<_i974.FirebaseFirestore>()),
    );
    gh.lazySingleton<_i75.NetworkInfo>(
      () => _i75.NetworkInfoImpl(gh<_i895.Connectivity>()),
    );
    gh.lazySingleton<_i141.MonthlySnapshotFirestoreDataSource>(
      () => _i141.MonthlySnapshotFirestoreDataSourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i560.FirebaseAuthService>(),
      ),
    );
    gh.lazySingleton<_i871.ApiClient>(
      () => _i871.ApiClient(gh<_i75.NetworkInfo>()),
    );
    gh.lazySingleton<_i445.ContractFirestoreDataSource>(
      () => _i445.ContractFirestoreDataSourceImpl(
        gh<_i974.FirebaseFirestore>(),
        gh<_i560.FirebaseAuthService>(),
      ),
    );
    gh.factory<_i501.AuthCubit>(
      () => _i501.AuthCubit(gh<_i560.FirebaseAuthService>()),
    );
    gh.lazySingleton<_i863.MonthlySnapshotRepository>(
      () => _i999.MonthlySnapshotRepositoryImpl(
        gh<_i141.MonthlySnapshotFirestoreDataSource>(),
      ),
    );
    gh.lazySingleton<_i875.ContractRepository>(
      () =>
          _i364.ContractRepositoryImpl(gh<_i445.ContractFirestoreDataSource>()),
    );
    gh.factory<_i989.DashboardCubit>(
      () => _i989.DashboardCubit(
        contractRepository: gh<_i875.ContractRepository>(),
        snapshotRepository: gh<_i863.MonthlySnapshotRepository>(),
      ),
    );
    gh.factory<_i136.AddContractCubit>(
      () => _i136.AddContractCubit(
        contractRepository: gh<_i875.ContractRepository>(),
      ),
    );
    gh.factory<_i604.ContractDetailCubit>(
      () => _i604.ContractDetailCubit(
        contractRepository: gh<_i875.ContractRepository>(),
      ),
    );
    gh.factory<_i151.ContractsCubit>(
      () => _i151.ContractsCubit(
        contractRepository: gh<_i875.ContractRepository>(),
      ),
    );
    return this;
  }
}

class _$FirebaseModule extends _i959.FirebaseModule {}

class _$RegisterModule extends _i464.RegisterModule {}
