import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sookshicha_dhukkikenda/core/services/firebase_initializer.dart';
import 'package:sookshicha_dhukkikenda/core/services/local_storage_service.dart';
import 'package:sookshicha_dhukkikenda/core/utils/logger.dart';
import 'package:sookshicha_dhukkikenda/injection.dart';
import 'package:sookshicha_dhukkikenda/presentation/bloc/app_bloc_observer.dart';
import 'package:sookshicha_dhukkikenda/presentation/bloc/dashboard/dashboard_barrel.dart';
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
      home: Builder(
        builder: (context) {
          try {
            final cubit = sl<DashboardCubit>();
            return BlocProvider(
              create: (context) => cubit,
              child: const DashboardScreen(),
            );
          } catch (e) {
            AppLogger.e('Failed to create DashboardCubit', e);
            return Scaffold(
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Colors.red,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Unable to start the application',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reason: ${e.toString()}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: () {
                          // Try one more time (force a rebuild)
                        },
                        child: const Text('Try Again'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }
        },
      ),
    );
  }
}
