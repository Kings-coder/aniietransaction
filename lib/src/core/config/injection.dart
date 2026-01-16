library;

import 'package:bloctutorial/src/features/onboarding/data/implements/implements.dart';
import 'package:bloctutorial/src/features/onboarding/data/sources/sources.dart';
import 'package:bloctutorial/src/features/onboarding/domain/repositories/repositories.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

import '../../features/auth/data/implements/auth_repository_impl.dart';
import '../../features/auth/data/sources/sources.dart';
import '../../features/auth/domain/repositories/authRepositories.dart';
import '../../features/auth/domain/usecases/login_usecases.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';

class DependencyInjection {
  static Future<void> init() async {
    WidgetsFlutterBinding.ensureInitialized();
  }
}

final sl = GetIt.instance;
Future<void> init() async {
  // Core
  sl


    // Data sources
    ..registerLazySingleton<AuthRemoteDataSource>(
        () => AuthRemoteDataSourceImp())
   ..registerLazySingleton<OnboardingLocalDataSource>(() => OnboardingLocalDataSourceImpl())   
        ;
        

  // Repositories
  sl.registerLazySingleton<AuthRepository>(() => AuthRepositoryImp());
  sl.registerLazySingleton<OnboardingRepository>(() =>  OnBoardingRepositoryImpl(sl()));

  // Usecases
  sl.registerLazySingleton(() => UserLoginUsecase(sl()));

  // Bloc
  sl.registerFactory(() => AuthBloc());
}
