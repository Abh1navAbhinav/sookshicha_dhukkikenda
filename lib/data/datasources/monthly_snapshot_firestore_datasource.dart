import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';

import '../../core/error/exceptions.dart';
import '../../core/services/firebase_auth_service.dart';
import '../../core/utils/logger.dart';
import '../models/monthly_snapshot_dto.dart';

/// Abstract interface for MonthlySnapshot Firestore data source.
///
/// Handles all Firestore operations for monthly snapshots, including:
/// - User-scoped collection access
/// - CRUD operations with YYYY-MM document IDs
/// - Range queries for historical analysis
/// - Real-time streaming
abstract class MonthlySnapshotFirestoreDataSource {
  /// Get a snapshot for a specific month.
  Future<MonthlySnapshotDto?> getSnapshotForMonth(int month, int year);

  /// Get snapshots within a date range.
  Future<List<MonthlySnapshotDto>> getSnapshotsInRange(
    int startMonth,
    int startYear,
    int endMonth,
    int endYear,
  );

  /// Get the most recent N snapshots.
  Future<List<MonthlySnapshotDto>> getRecentSnapshots(int count);

  /// Get the latest snapshot.
  Future<MonthlySnapshotDto?> getLatestSnapshot();

  /// Get all snapshots for a year.
  Future<List<MonthlySnapshotDto>> getSnapshotsForYear(int year);

  /// Save a snapshot (upsert).
  Future<void> saveSnapshot(MonthlySnapshotDto snapshot);

  /// Delete a snapshot.
  Future<void> deleteSnapshot(int month, int year);

  /// Delete all snapshots.
  Future<void> deleteAllSnapshots();

  /// Stream a specific snapshot.
  Stream<MonthlySnapshotDto?> watchSnapshot(int month, int year);

  /// Stream all snapshots.
  Stream<List<MonthlySnapshotDto>> watchAllSnapshots();

  /// Check if a snapshot exists.
  Future<bool> hasSnapshot(int month, int year);

  /// Batch save multiple snapshots.
  Future<void> batchSaveSnapshots(List<MonthlySnapshotDto> snapshots);

  /// Get snapshots with deficit.
  Future<List<MonthlySnapshotDto>> getDeficitSnapshots();

  /// Get all snapshots for aggregate calculation.
  Future<List<MonthlySnapshotDto>> getAllSnapshots();
}

/// Implementation of MonthlySnapshotFirestoreDataSource.
///
/// Uses user-scoped collection path: users/{userId}/monthlySnapshots
/// Document IDs follow YYYY-MM format for natural ordering.
@LazySingleton(as: MonthlySnapshotFirestoreDataSource)
class MonthlySnapshotFirestoreDataSourceImpl
    implements MonthlySnapshotFirestoreDataSource {
  MonthlySnapshotFirestoreDataSourceImpl(this._firestore, this._authService);

  final FirebaseFirestore _firestore;
  final FirebaseAuthService _authService;

  /// Collection name for monthly snapshots.
  static const String _snapshotsCollection = 'monthlySnapshots';

  /// Get the user-scoped snapshots collection reference.
  ///
  /// Path: users/{userId}/monthlySnapshots
  /// Throws [AuthException] if user is not authenticated.
  CollectionReference<Map<String, dynamic>> get _snapshotsRef {
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
        .collection(_snapshotsCollection);
  }

  @override
  Future<MonthlySnapshotDto?> getSnapshotForMonth(int month, int year) async {
    try {
      final docId = MonthlySnapshotDto.createDocumentId(month, year);
      final doc = await _snapshotsRef.doc(docId).get();
      if (!doc.exists) return null;
      return MonthlySnapshotDto.fromFirestore(doc);
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to get snapshot for month', e);
      throw ServerException(
        message: 'Failed to get snapshot: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<List<MonthlySnapshotDto>> getSnapshotsInRange(
    int startMonth,
    int startYear,
    int endMonth,
    int endYear,
  ) async {
    try {
      final startDocId = MonthlySnapshotDto.createDocumentId(
        startMonth,
        startYear,
      );
      final endDocId = MonthlySnapshotDto.createDocumentId(endMonth, endYear);

      // Use document ID (YYYY-MM) for range query - natural string ordering works
      final snapshot = await _snapshotsRef
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startDocId)
          .where(FieldPath.documentId, isLessThanOrEqualTo: endDocId)
          .orderBy(FieldPath.documentId)
          .get();

      return snapshot.docs
          .map((doc) => MonthlySnapshotDto.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to get snapshots in range', e);
      throw ServerException(
        message: 'Failed to get snapshots in range: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<List<MonthlySnapshotDto>> getRecentSnapshots(int count) async {
    try {
      final snapshot = await _snapshotsRef
          .orderBy(FieldPath.documentId, descending: true)
          .limit(count)
          .get();

      return snapshot.docs
          .map((doc) => MonthlySnapshotDto.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to get recent snapshots', e);
      throw ServerException(
        message: 'Failed to get recent snapshots: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<MonthlySnapshotDto?> getLatestSnapshot() async {
    try {
      final snapshot = await _snapshotsRef
          .orderBy(FieldPath.documentId, descending: true)
          .limit(1)
          .get();

      if (snapshot.docs.isEmpty) return null;
      return MonthlySnapshotDto.fromFirestore(snapshot.docs.first);
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to get latest snapshot', e);
      throw ServerException(
        message: 'Failed to get latest snapshot: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<List<MonthlySnapshotDto>> getSnapshotsForYear(int year) async {
    try {
      final startDocId = MonthlySnapshotDto.createDocumentId(1, year);
      final endDocId = MonthlySnapshotDto.createDocumentId(12, year);

      final snapshot = await _snapshotsRef
          .where(FieldPath.documentId, isGreaterThanOrEqualTo: startDocId)
          .where(FieldPath.documentId, isLessThanOrEqualTo: endDocId)
          .orderBy(FieldPath.documentId)
          .get();

      return snapshot.docs
          .map((doc) => MonthlySnapshotDto.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to get snapshots for year', e);
      throw ServerException(
        message: 'Failed to get snapshots for year: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<void> saveSnapshot(MonthlySnapshotDto snapshot) async {
    try {
      final docId = snapshot.documentId;
      final data = snapshot.toFirestore();
      data['updatedAt'] = FieldValue.serverTimestamp();

      // Use set with merge to upsert
      await _snapshotsRef.doc(docId).set(data, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to save snapshot', e);
      throw ServerException(
        message: 'Failed to save snapshot: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<void> deleteSnapshot(int month, int year) async {
    try {
      final docId = MonthlySnapshotDto.createDocumentId(month, year);
      await _snapshotsRef.doc(docId).delete();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to delete snapshot', e);
      throw ServerException(
        message: 'Failed to delete snapshot: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<void> deleteAllSnapshots() async {
    try {
      final snapshot = await _snapshotsRef.get();
      final batch = _firestore.batch();

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to delete all snapshots', e);
      throw ServerException(
        message: 'Failed to delete all snapshots: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Stream<MonthlySnapshotDto?> watchSnapshot(int month, int year) {
    final docId = MonthlySnapshotDto.createDocumentId(month, year);
    return _snapshotsRef.doc(docId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return MonthlySnapshotDto.fromFirestore(doc);
    });
  }

  @override
  Stream<List<MonthlySnapshotDto>> watchAllSnapshots() {
    return _snapshotsRef
        .orderBy(FieldPath.documentId, descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => MonthlySnapshotDto.fromFirestore(doc))
              .toList();
        });
  }

  @override
  Future<bool> hasSnapshot(int month, int year) async {
    try {
      final docId = MonthlySnapshotDto.createDocumentId(month, year);
      final doc = await _snapshotsRef.doc(docId).get();
      return doc.exists;
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to check snapshot existence', e);
      throw ServerException(
        message: 'Failed to check snapshot: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<void> batchSaveSnapshots(List<MonthlySnapshotDto> snapshots) async {
    try {
      final batch = _firestore.batch();

      for (final snapshot in snapshots) {
        final docRef = _snapshotsRef.doc(snapshot.documentId);
        final data = snapshot.toFirestore();
        data['updatedAt'] = FieldValue.serverTimestamp();
        batch.set(docRef, data, SetOptions(merge: true));
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to batch save snapshots', e);
      throw ServerException(
        message: 'Failed to batch save snapshots: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<List<MonthlySnapshotDto>> getDeficitSnapshots() async {
    try {
      // Firestore doesn't support computed field queries, so we fetch all
      // and filter locally. For large datasets, consider a 'isDeficit' field.
      final snapshot = await _snapshotsRef
          .orderBy(FieldPath.documentId, descending: true)
          .get();

      return snapshot.docs
          .map((doc) => MonthlySnapshotDto.fromFirestore(doc))
          .where((dto) => dto.totalIncome < dto.mandatoryOutflow)
          .toList();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to get deficit snapshots', e);
      throw ServerException(
        message: 'Failed to get deficit snapshots: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<List<MonthlySnapshotDto>> getAllSnapshots() async {
    try {
      final snapshot = await _snapshotsRef.orderBy(FieldPath.documentId).get();

      return snapshot.docs
          .map((doc) => MonthlySnapshotDto.fromFirestore(doc))
          .toList();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to get all snapshots', e);
      throw ServerException(
        message: 'Failed to get all snapshots: ${e.message}',
        code: e.code,
      );
    }
  }
}
