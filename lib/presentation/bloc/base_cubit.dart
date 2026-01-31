import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

/// Base state class for Cubits
/// All Cubit states should extend this class
abstract class BaseState extends Equatable {
  const BaseState();

  @override
  List<Object?> get props => [];
}

/// Generic loading state
class LoadingState extends BaseState {
  const LoadingState();
}

/// Generic initial state
class InitialState extends BaseState {
  const InitialState();
}

/// Generic error state
class ErrorState extends BaseState {
  const ErrorState({required this.message, this.code});

  final String message;
  final String? code;

  @override
  List<Object?> get props => [message, code];
}

/// Base Cubit class with common functionality
abstract class BaseCubit<State extends BaseState> extends Cubit<State> {
  BaseCubit(super.initialState);

  /// Safe emit that checks if the cubit is still active
  void safeEmit(State state) {
    if (!isClosed) {
      emit(state);
    }
  }
}
