import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../core/error/exceptions.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/utils/logger.dart';
import '../models/contract_dto.dart';

/// Abstract interface for Contract Firestore data source.
///
/// Handles all Firestore operations for contracts, including:
/// - User-scoped collection access
/// - CRUD operations
/// - Query building
/// - Real-time streaming
abstract class ContractFirestoreDataSource {
  /// Get all contracts for the current user.
  Future<List<ContractDto>> getAllContracts();

  /// Get contracts filtered by status.
  Future<List<ContractDto>> getContractsByStatus(String status);

  /// Get contracts filtered by type.
  Future<List<ContractDto>> getContractsByType(String type);

  /// Get a single contract by ID.
  Future<ContractDto?> getContractById(String contractId);

  /// Create a new contract and return its ID.
  Future<String> createContract(ContractDto contract);

  /// Update an existing contract.
  Future<void> updateContract(ContractDto contract);

  /// Delete a contract.
  Future<void> deleteContract(String contractId);

  /// Update contract status.
  Future<void> updateContractStatus(String contractId, String status);

  /// Stream all contracts for real-time updates.
  Stream<List<ContractDto>> watchAllContracts();

  /// Stream contracts filtered by status.
  Stream<List<ContractDto>> watchContractsByStatus(String status);

  /// Stream a single contract.
  Stream<ContractDto?> watchContract(String contractId);

  /// Batch update multiple contracts.
  Future<void> batchUpdateContracts(List<ContractDto> contracts);

  /// Get contracts ending within specified days.
  Future<List<ContractDto>> getContractsEndingSoon(int days);
}

/// Implementation of ContractFirestoreDataSource.
///
/// Uses user-scoped collection path: users/{userId}/contracts
/// All operations are scoped to the authenticated user.
@LazySingleton(as: ContractFirestoreDataSource)
class ContractFirestoreDataSourceImpl implements ContractFirestoreDataSource {
  ContractFirestoreDataSourceImpl(this._firestore, this._authService);

  final FirebaseFirestore _firestore;
  final FirebaseAuthService _authService;

  /// Collection name for contracts.
  static const String _contractsCollection = 'contracts';

  /// Get the user-scoped contracts collection reference.
  ///
  /// Path: users/{userId}/contracts
  /// Throws [AuthException] if user is not authenticated.
  CollectionReference<Map<String, dynamic>> get _contractsRef {
    final userId = _authService.currentUser?.uid;
    if (userId == null) {
      throw const AuthException(
        message: 'User not authenticated',
        code: 'unauthenticated',
      );
    }
    return _firestore
        .collection('users')
        .doc(userId)
        .collection(_contractsCollection);
  }

  @override
  Future<List<ContractDto>> getAllContracts() async {
    try {
      final snapshot = await _contractsRef.get();

      return snapshot.docs
          .map((doc) => ContractDto.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to get all contracts', e);
      throw ServerException(
        message: 'Failed to get contracts: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<List<ContractDto>> getContractsByStatus(String status) async {
    try {
      final snapshot = await _contractsRef
          .where('status', isEqualTo: status)
          .get();

      return snapshot.docs
          .map((doc) => ContractDto.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to get contracts by status', e);
      throw ServerException(
        message: 'Failed to get contracts by status: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<List<ContractDto>> getContractsByType(String type) async {
    try {
      final snapshot = await _contractsRef.where('type', isEqualTo: type).get();

      return snapshot.docs
          .map((doc) => ContractDto.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to get contracts by type', e);
      throw ServerException(
        message: 'Failed to get contracts by type: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<ContractDto?> getContractById(String contractId) async {
    try {
      final doc = await _contractsRef.doc(contractId).get();
      if (!doc.exists) return null;
      return ContractDto.fromFirestore(doc);
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to get contract by ID', e);
      throw ServerException(
        message: 'Failed to get contract: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<String> createContract(ContractDto contract) async {
    try {
      final data = contract.toFirestore();
      data['createdAt'] = FieldValue.serverTimestamp();
      data['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _contractsRef.add(data);
      return docRef.id;
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to create contract', e);
      throw ServerException(
        message: 'Failed to create contract: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<void> updateContract(ContractDto contract) async {
    try {
      final data = contract.toUpdateMap();
      data['updatedAt'] = FieldValue.serverTimestamp();

      await _contractsRef.doc(contract.id).update(data);
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to update contract', e);
      throw ServerException(
        message: 'Failed to update contract: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<void> deleteContract(String contractId) async {
    try {
      await _contractsRef.doc(contractId).delete();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to delete contract', e);
      throw ServerException(
        message: 'Failed to delete contract: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<void> updateContractStatus(String contractId, String status) async {
    try {
      await _contractsRef.doc(contractId).update({
        'status': status,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to update contract status', e);
      throw ServerException(
        message: 'Failed to update contract status: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Stream<List<ContractDto>> watchAllContracts() {
    return _contractsRef.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => ContractDto.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Stream<List<ContractDto>> watchContractsByStatus(String status) {
    return _contractsRef.where('status', isEqualTo: status).snapshots().map((
      snapshot,
    ) {
      return snapshot.docs
          .map((doc) => ContractDto.fromFirestore(doc))
          .toList();
    });
  }

  @override
  Stream<ContractDto?> watchContract(String contractId) {
    return _contractsRef.doc(contractId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ContractDto.fromFirestore(doc);
    });
  }

  @override
  Future<void> batchUpdateContracts(List<ContractDto> contracts) async {
    try {
      final batch = _firestore.batch();

      for (final contract in contracts) {
        final docRef = _contractsRef.doc(contract.id);
        final data = contract.toUpdateMap();
        data['updatedAt'] = FieldValue.serverTimestamp();
        batch.update(docRef, data);
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to batch update contracts', e);
      throw ServerException(
        message: 'Failed to batch update contracts: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<List<ContractDto>> getContractsEndingSoon(int days) async {
    try {
      final now = DateTime.now();
      final futureDate = now.add(Duration(days: days));

      final snapshot = await _contractsRef.get();

      final docs = snapshot.docs.where((doc) {
        final data = doc.data();
        if (data['status'] != 'active') return false;
        final endDate = data['endDate'] as Timestamp?;
        if (endDate == null) return false;
        final date = endDate.toDate();
        return date.isAfter(now) && date.isBefore(futureDate);
      }).toList();

      return docs.map((doc) => ContractDto.fromFirestore(doc)).toList();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to get contracts ending soon', e);
      throw ServerException(
        message: 'Failed to get contracts ending soon: ${e.message}',
        code: e.code,
      );
    }
  }
}
