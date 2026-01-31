import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:injectable/injectable.dart';
import 'package:sookshicha_dhukkikenda/core/error/exceptions.dart';
import 'package:sookshicha_dhukkikenda/core/utils/logger.dart';

/// Abstract class for Firestore operations
abstract class FirestoreService {
  /// Get a document by ID from a collection
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String documentId,
  );

  /// Get all documents from a collection
  Future<List<Map<String, dynamic>>> getCollection(String collection);

  /// Query documents from a collection
  Future<List<Map<String, dynamic>>> queryCollection(
    String collection, {
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  });

  /// Create a new document
  Future<String> createDocument(String collection, Map<String, dynamic> data);

  /// Set a document (create or overwrite)
  Future<void> setDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  );

  /// Update an existing document
  Future<void> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  );

  /// Delete a document
  Future<void> deleteDocument(String collection, String documentId);

  /// Stream a document
  Stream<Map<String, dynamic>?> streamDocument(
    String collection,
    String documentId,
  );

  /// Stream a collection
  Stream<List<Map<String, dynamic>>> streamCollection(String collection);

  /// Batch write operations
  Future<void> batchWrite(List<BatchOperation> operations);
}

/// Query filter for Firestore queries
class QueryFilter {
  const QueryFilter({
    required this.field,
    required this.operator,
    required this.value,
  });

  final String field;
  final FilterOperator operator;
  final dynamic value;
}

/// Filter operators for Firestore queries
enum FilterOperator {
  isEqualTo,
  isNotEqualTo,
  isLessThan,
  isLessThanOrEqualTo,
  isGreaterThan,
  isGreaterThanOrEqualTo,
  arrayContains,
  arrayContainsAny,
  whereIn,
  whereNotIn,
  isNull,
}

/// Batch operation for Firestore batch writes
class BatchOperation {
  const BatchOperation._({
    required this.type,
    required this.collection,
    required this.documentId,
    this.data,
  });

  factory BatchOperation.create(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) => BatchOperation._(
    type: BatchOperationType.create,
    collection: collection,
    documentId: documentId,
    data: data,
  );

  factory BatchOperation.update(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) => BatchOperation._(
    type: BatchOperationType.update,
    collection: collection,
    documentId: documentId,
    data: data,
  );

  factory BatchOperation.delete(String collection, String documentId) =>
      BatchOperation._(
        type: BatchOperationType.delete,
        collection: collection,
        documentId: documentId,
      );

  final BatchOperationType type;
  final String collection;
  final String documentId;
  final Map<String, dynamic>? data;
}

enum BatchOperationType { create, update, delete }

/// Implementation of FirestoreService
@LazySingleton(as: FirestoreService)
class FirestoreServiceImpl implements FirestoreService {
  FirestoreServiceImpl(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<Map<String, dynamic>?> getDocument(
    String collection,
    String documentId,
  ) async {
    try {
      final doc = await _firestore.collection(collection).doc(documentId).get();
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to get document', e);
      throw ServerException(
        message: 'Failed to get document: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> getCollection(String collection) async {
    try {
      final snapshot = await _firestore.collection(collection).get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to get collection', e);
      throw ServerException(
        message: 'Failed to get collection: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<List<Map<String, dynamic>>> queryCollection(
    String collection, {
    List<QueryFilter>? filters,
    String? orderBy,
    bool descending = false,
    int? limit,
  }) async {
    try {
      Query<Map<String, dynamic>> query = _firestore.collection(collection);

      if (filters != null) {
        for (final filter in filters) {
          query = _applyFilter(query, filter);
        }
      }

      if (orderBy != null) {
        query = query.orderBy(orderBy, descending: descending);
      }

      if (limit != null) {
        query = query.limit(limit);
      }

      final snapshot = await query.get();
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to query collection', e);
      throw ServerException(
        message: 'Failed to query collection: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<String> createDocument(
    String collection,
    Map<String, dynamic> data,
  ) async {
    try {
      final docRef = await _firestore.collection(collection).add({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to create document', e);
      throw ServerException(
        message: 'Failed to create document: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<void> setDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(documentId).set({
        ...data,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to set document', e);
      throw ServerException(
        message: 'Failed to set document: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<void> updateDocument(
    String collection,
    String documentId,
    Map<String, dynamic> data,
  ) async {
    try {
      await _firestore.collection(collection).doc(documentId).update({
        ...data,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to update document', e);
      throw ServerException(
        message: 'Failed to update document: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Future<void> deleteDocument(String collection, String documentId) async {
    try {
      await _firestore.collection(collection).doc(documentId).delete();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to delete document', e);
      throw ServerException(
        message: 'Failed to delete document: ${e.message}',
        code: e.code,
      );
    }
  }

  @override
  Stream<Map<String, dynamic>?> streamDocument(
    String collection,
    String documentId,
  ) {
    return _firestore.collection(collection).doc(documentId).snapshots().map((
      doc,
    ) {
      if (!doc.exists) return null;
      return {'id': doc.id, ...doc.data()!};
    });
  }

  @override
  Stream<List<Map<String, dynamic>>> streamCollection(String collection) {
    return _firestore.collection(collection).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => {'id': doc.id, ...doc.data()}).toList();
    });
  }

  @override
  Future<void> batchWrite(List<BatchOperation> operations) async {
    try {
      final batch = _firestore.batch();

      for (final operation in operations) {
        final docRef = _firestore
            .collection(operation.collection)
            .doc(operation.documentId);

        switch (operation.type) {
          case BatchOperationType.create:
            batch.set(docRef, {
              ...operation.data!,
              'createdAt': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            });
          case BatchOperationType.update:
            batch.update(docRef, {
              ...operation.data!,
              'updatedAt': FieldValue.serverTimestamp(),
            });
          case BatchOperationType.delete:
            batch.delete(docRef);
        }
      }

      await batch.commit();
    } on FirebaseException catch (e) {
      AppLogger.e('Failed to execute batch write', e);
      throw ServerException(
        message: 'Failed to execute batch write: ${e.message}',
        code: e.code,
      );
    }
  }

  Query<Map<String, dynamic>> _applyFilter(
    Query<Map<String, dynamic>> query,
    QueryFilter filter,
  ) {
    switch (filter.operator) {
      case FilterOperator.isEqualTo:
        return query.where(filter.field, isEqualTo: filter.value);
      case FilterOperator.isNotEqualTo:
        return query.where(filter.field, isNotEqualTo: filter.value);
      case FilterOperator.isLessThan:
        return query.where(filter.field, isLessThan: filter.value);
      case FilterOperator.isLessThanOrEqualTo:
        return query.where(filter.field, isLessThanOrEqualTo: filter.value);
      case FilterOperator.isGreaterThan:
        return query.where(filter.field, isGreaterThan: filter.value);
      case FilterOperator.isGreaterThanOrEqualTo:
        return query.where(filter.field, isGreaterThanOrEqualTo: filter.value);
      case FilterOperator.arrayContains:
        return query.where(filter.field, arrayContains: filter.value);
      case FilterOperator.arrayContainsAny:
        return query.where(
          filter.field,
          arrayContainsAny: filter.value as List,
        );
      case FilterOperator.whereIn:
        return query.where(filter.field, whereIn: filter.value as List);
      case FilterOperator.whereNotIn:
        return query.where(filter.field, whereNotIn: filter.value as List);
      case FilterOperator.isNull:
        return query.where(filter.field, isNull: filter.value as bool);
    }
  }
}
