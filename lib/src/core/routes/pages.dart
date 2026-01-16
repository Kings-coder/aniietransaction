// ignore_for_file: public_member_api_docs, sort_constructors_first
library;

import 'package:bloctutorial/src/features/home/presentation/bloc/home_bloc.dart';
import 'package:bloctutorial/src/features/home/presentation/pages/pages.dart';
import 'package:bloctutorial/src/features/onboarding/presentation/cubit/onboarding_cubit.dart';
import 'package:bloctutorial/src/features/onboarding/presentation/pages/pages.dart';
import 'package:bloctutorial/src/features/splash/presentation/cubit/splash_cubit.dart';
import 'package:bloctutorial/src/features/splash/presentation/pages/pages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../config/config.dart';
import '../error/exception.dart';
import 'routes.dart';

class AppRoute {
  static const initial = RoutesName.initial;
  static Route<dynamic> generate(RouteSettings? settings) {
    switch (settings?.name) {
      case RoutesName.initial:
        return _pageRoute(
          (context) => BlocProvider(
              create: (_) => sl<OnboardingCubit>(),
              child: const OnboardingPage()),
          settings: settings!,
        );
      case RoutesName.home:
        return _pageRoute(
          (context) => BlocProvider(
              create: (_) => sl<HomeBloc>(), child: const HomePage()),
          settings: settings!,
        );
      case RoutesName.login:
        return _pageRoute(
            (context) => BlocProvider(
                create: (_) => sl<SplashCubit>(), child: const SplashPage()),
            settings: settings!);
      default:
        // If there is no such named route in the switch statement
        throw const RouteException('Route not found!');
    }
  }
}

MaterialPageRoute _pageRoute(Widget Function(BuildContext) page,
    {required RouteSettings settings}) {
  return MaterialPageRoute(builder: (context) => page(context));
}
