import 'package:dartz/dartz.dart';
import 'package:equatable/equatable.dart';
import 'package:sookshicha_dhukkikenda/core/error/failures.dart';

/// Abstract class for Use Cases following Clean Architecture principles.
///
/// T is the return type of the use case.
/// Params are the parameters required by the use case.
///
/// All use cases must implement the call method which returns
/// an Either type with Failure on the left and success type on the right.
abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

/// Use this class when a use case doesn't require any parameters
class NoParams extends Equatable {
  const NoParams();

  @override
  List<Object?> get props => [];
}

/// Abstract class for Use Cases that return a Stream
abstract class StreamUseCase<T, Params> {
  Stream<Either<Failure, T>> call(Params params);
}
