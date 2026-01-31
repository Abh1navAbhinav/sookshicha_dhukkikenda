import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:sookshicha_dhukkikenda/injection.config.dart';

/// Global service locator instance
final GetIt sl = GetIt.instance;

/// Initialize all dependencies
/// This should be called before runApp
@InjectableInit(
  initializerName: 'init',
  preferRelativeImports: true,
  asExtension: true,
)
Future<void> configureDependencies() async => sl.init();

/// Module for registering third-party dependencies
@module
abstract class RegisterModule {
  @lazySingleton
  Connectivity get connectivity => Connectivity();
}
