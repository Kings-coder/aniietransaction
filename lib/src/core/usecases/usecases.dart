library usecases;

import 'package:bloctutorial/src/core/types/typedefs.dart';

abstract class UsecaseWithParams<Type, Params> {
 ResultFuture<Type> call(Params params);
}

abstract class UsecaseWithoutParams<Type> {
 ResultFuture<Type> call();
}