import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:sookshicha_dhukkikenda/core/services/firebase_initializer.dart';
import 'package:sookshicha_dhukkikenda/core/services/local_storage_service.dart';
import 'package:sookshicha_dhukkikenda/core/utils/logger.dart';
import 'package:sookshicha_dhukkikenda/injection.dart';
import 'package:sookshicha_dhukkikenda/presentation/bloc/app_bloc_observer.dart';
import 'package:sookshicha_dhukkikenda/presentation/theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Bloc observer for debugging
  Bloc.observer = const AppBlocObserver();

  try {
    // Initialize Firebase
    await FirebaseInitializer.initialize();

    // Configure Firestore for offline persistence
    FirestoreConfig.enableOfflinePersistence();

    // Initialize dependency injection
    await configureDependencies();

    // Initialize local storage (Hive)
    final localStorage = sl<LocalStorageService>();
    await localStorage.init();

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
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      home: const Scaffold(body: Center(child: Text('App is ready!'))),
    );
  }
}
