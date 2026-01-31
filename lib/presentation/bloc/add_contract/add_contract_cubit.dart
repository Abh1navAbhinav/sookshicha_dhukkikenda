import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:uuid/uuid.dart';

import '../../../domain/entities/contract/contract.dart';
import '../../../domain/entities/contract/contract_status.dart';
import '../../../domain/entities/contract/contract_type.dart';
import '../../../domain/entities/contract/metadata/contract_metadata.dart';
import '../../../domain/repositories/contract_repository.dart';
import '../../../domain/usecases/monthly_execution_engine.dart';
import 'add_contract_state.dart';

@injectable
class AddContractCubit extends Cubit<AddContractState> {
  AddContractCubit({required ContractRepository contractRepository})
    : _contractRepository = contractRepository,
      super(const AddContractInitial());

  final ContractRepository _contractRepository;

  Future<void> submitContract({
    required String name,
    required ContractType type,
    required double monthlyAmount,
    required DateTime startDate,
    DateTime? endDate,
    String? description,
    required ContractMetadata metadata,
  }) async {
    emit(const AddContractSubmitting());

    final contract = Contract(
      id: const Uuid().v4(),
      name: name,
      type: type,
      status: ContractStatus.active,
      startDate: startDate,
      endDate: endDate,
      monthlyAmount: monthlyAmount,
      metadata: metadata,
      description: description,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    // Catch up contract if it started in the past
    final now = DateTime.now();
    const engine = MonthlyExecutionEngine();
    final caughtUpContract = engine.catchUpContract(
      contract,
      now.month,
      now.year,
    );

    final result = await _contractRepository.createContract(caughtUpContract);

    result.fold(
      (failure) => emit(AddContractError(message: failure.message)),
      (id) => emit(AddContractSuccess(contractId: id)),
    );
  }
}
