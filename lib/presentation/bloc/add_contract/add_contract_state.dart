import 'package:equatable/equatable.dart';

abstract class AddContractState extends Equatable {
  const AddContractState();

  @override
  List<Object?> get props => [];
}

class AddContractInitial extends AddContractState {
  const AddContractInitial();
}

class AddContractSubmitting extends AddContractState {
  const AddContractSubmitting();
}

class AddContractSuccess extends AddContractState {
  const AddContractSuccess({required this.contractId});
  final String contractId;

  @override
  List<Object?> get props => [contractId];
}

class AddContractError extends AddContractState {
  const AddContractError({required this.message});
  final String message;

  @override
  List<Object?> get props => [message];
}
