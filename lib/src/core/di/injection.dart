import 'package:get_it/get_it.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/transaction/data/datasources/mock_api_service.dart';
import '../../features/transaction/data/datasources/transaction_storage.dart';
import '../../features/transaction/domain/repositories/transaction_repository.dart';
import '../../features/transaction/presentation/bloc/transaction_bloc.dart';


final sl = GetIt.instance;

/// Initialize all dependencies.
/// 
/// Call this before runApp() to set up the dependency injection container.
Future<void> initializeDependencies() async {
  // External dependencies
  final sharedPreferences = await SharedPreferences.getInstance();
  sl.registerSingleton<SharedPreferences>(sharedPreferences);

  // Data sources
  sl.registerLazySingleton<TransactionStorage>(
    () => TransactionStorage(sl<SharedPreferences>()),
  );
  
  sl.registerLazySingleton<MockApiService>(
    () => MockApiService(),
  );

  // Repositories
  sl.registerLazySingleton<TransactionRepository>(
    () => TransactionRepository(
      apiService: sl<MockApiService>(),
      storage: sl<TransactionStorage>(),
    ),
  );

  // BLoCs
  sl.registerFactory<TransactionBloc>(
    () => TransactionBloc(repository: sl<TransactionRepository>()),
  );
}
