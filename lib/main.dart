import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sookshicha_dhukkikenda/core/services/firebase_initializer.dart';
import 'package:sookshicha_dhukkikenda/core/services/local_storage_service.dart';
import 'package:sookshicha_dhukkikenda/core/utils/logger.dart';
import 'package:sookshicha_dhukkikenda/injection.dart';
import 'package:sookshicha_dhukkikenda/presentation/bloc/app_bloc_observer.dart';
import 'package:sookshicha_dhukkikenda/presentation/bloc/auth/auth_cubit.dart';
import 'package:sookshicha_dhukkikenda/presentation/bloc/auth/auth_state.dart';
import 'package:sookshicha_dhukkikenda/presentation/bloc/contracts/contracts_cubit.dart';
import 'package:sookshicha_dhukkikenda/presentation/bloc/dashboard/dashboard_barrel.dart';
import 'package:sookshicha_dhukkikenda/presentation/pages/auth/login_screen.dart';
import 'package:sookshicha_dhukkikenda/presentation/pages/dashboard/dashboard_screen.dart';
import 'package:sookshicha_dhukkikenda/presentation/theme/calm_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Bloc observer for debugging
  Bloc.observer = const AppBlocObserver();

  try {
    // Initialize dependency injection
    await configureDependencies();

    // Initialize local storage (Hive)
    final localStorage = sl<LocalStorageService>();
    await localStorage.init();

    // Initialize Firebase
    try {
      await FirebaseInitializer.initialize();
      FirestoreConfig.enableOfflinePersistence();
    } catch (e) {
      AppLogger.e(
        'Firebase initialization failed (likely missing configuration)',
        e,
      );
    }

    AppLogger.i('App initialized successfully');
  } catch (e, stackTrace) {
    AppLogger.e('Failed to initialize app', e, stackTrace);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sookshicha Dhukkikenda',
      debugShowCheckedModeBanner: false,
      theme: CalmTheme.lightTheme,
      home: BlocProvider(
        create: (context) => sl<AuthCubit>(),
        child: BlocBuilder<AuthCubit, AuthState>(
          buildWhen: (previous, current) =>
              current is Authenticated ||
              current is Unauthenticated ||
              current is AuthInitial,
          builder: (context, state) {
            if (state is Authenticated) {
              return MultiBlocProvider(
                providers: [
                  BlocProvider(create: (context) => sl<DashboardCubit>()),
                  // Provide ContractsCubit for contract actions (pin, delete, etc.)
                  BlocProvider(create: (context) => sl<ContractsCubit>()),
                ],
                child: const DashboardScreen(),
              );
            }

            if (state is AuthInitial) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            return const LoginScreen();
          },
        ),
      ),
    );
  }
}
