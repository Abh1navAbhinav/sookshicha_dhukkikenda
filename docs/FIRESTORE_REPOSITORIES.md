# Firestore Repository Implementation

## Engineering Notes

### Date: 2026-01-31
### Author: AI Assistant
### Module: Data Layer - Firebase Firestore Repositories

---

## Overview

This document explains the design decisions, architecture, and trade-offs made in implementing the Firebase Firestore repositories for the contract-based personal finance app.

---

## 1. Firestore Structure

### Collection Hierarchy

```
users/
  └── {userId}/
      ├── contracts/
      │   ├── {contractId}        # Auto-generated document ID
      │   ├── {contractId}
      │   └── ...
      └── monthlySnapshots/
          ├── 2026-01             # YYYY-MM format (e.g., January 2026)
          ├── 2026-02             # February 2026
          └── ...
```

### Document Schemas

#### Contract Document
```json
{
  "name": "Home Loan - HDFC",
  "type": "reducing",           // reducing | growing | fixed
  "status": "active",           // active | paused | closed
  "startDate": Timestamp,
  "endDate": Timestamp | null,
  "monthlyAmount": 45000.0,
  "metadata": {
    "metadataType": "reducing",
    "principalAmount": 5000000,
    "interestRatePercent": 8.5,
    "tenureMonths": 240,
    // ... other type-specific fields
  },
  "description": "Primary residence loan",
  "tags": ["loan", "home", "hdfc"],
  "createdAt": Timestamp,       // Server timestamp
  "updatedAt": Timestamp        // Server timestamp
}
```

#### MonthlySnapshot Document
```json
{
  "month": 1,
  "year": 2026,
  "totalIncome": 150000.0,
  "mandatoryOutflow": 85000.0,
  "activeContractCount": 5,
  "reducingOutflow": 45000.0,   // EMIs, loans
  "growingOutflow": 25000.0,    // SIPs, investments
  "fixedOutflow": 15000.0,      // Subscriptions, insurance
  "contractBreakdown": [
    {
      "contractId": "abc123",
      "contractName": "Home Loan",
      "contractType": "reducing",
      "amount": 45000.0,
      "principalPortion": 12000.0,
      "interestPortion": 33000.0,
      "newBalance": 4800000.0
    }
    // ... more contributions
  ],
  "generatedAt": Timestamp,
  "updatedAt": Timestamp
}
```

---

## 2. Why This Structure Scales

### User-Scoped Subcollections

**Choice**: `users/{userId}/contracts` instead of `contracts` with `userId` field

**Advantages**:
1. **Security Rules**: Simple, declarative rules based on path
   ```javascript
   match /users/{userId}/contracts/{contractId} {
     allow read, write: if request.auth.uid == userId;
   }
   ```
2. **Query Performance**: No composite indexes needed for user filtering
3. **Data Isolation**: Natural sharding by user
4. **Cost Optimization**: Only user's data is returned (no wasted reads)

**Scaling Characteristics**:
- ✅ Horizontal scaling per user (each user's data is isolated)
- ✅ No hotspots from global queries
- ✅ Predictable read patterns
- ⚠️ Cross-user queries require Cloud Functions or admin SDK

### MonthlySnapshot Document ID Strategy

**Choice**: `YYYY-MM` format (e.g., `2026-01`)

**Advantages**:
1. **Idempotent Saves**: Same month always updates same document
2. **Natural Ordering**: String comparison gives chronological order
3. **Efficient Range Queries**: 
   ```dart
   // Get all snapshots for 2026
   where(FieldPath.documentId, isGreaterThanOrEqualTo: '2026-01')
   where(FieldPath.documentId, isLessThanOrEqualTo: '2026-12')
   ```
4. **No Additional Index**: Document ID queries are always indexed
5. **Human Readable**: Easy to debug in Firebase Console

### Why Not Timestamp-Based IDs?
- Timestamps require additional indexes for range queries
- Auto-generated IDs (`add()`) don't support upsert patterns
- Less readable in Firebase Console

---

## 3. Offline Strategy

### Firestore Offline Persistence

Firestore SDK provides built-in offline support that we leverage:

```dart
// Configuration in FirestoreConfig
FirebaseFirestore.instance.settings = Settings(
  persistenceEnabled: true,
  cacheSizeBytes: 100 * 1024 * 1024,  // 100 MB
);
```

### How It Works

```
┌─────────────────────────────────────────────────────────────┐
│                     APP (Flutter)                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│   1. User saves contract                                   │
│                    │                                        │
│                    ▼                                        │
│   ┌─────────────────────────────────────┐                  │
│   │   Firestore SDK (Local Cache)       │ ◄── Immediate    │
│   │   - Writes to IndexedDB/SQLite      │     write        │
│   │   - Returns immediately             │                  │
│   └─────────────────────────────────────┘                  │
│                    │                                        │
│                    │ (async, when online)                  │
│                    ▼                                        │
│   ┌─────────────────────────────────────┐                  │
│   │   Firebase Servers                   │                  │
│   │   - Server timestamp applied         │                  │
│   │   - Durably stored                   │                  │
│   └─────────────────────────────────────┘                  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

### Offline Behavior Summary

| Operation | Online | Offline |
|-----------|--------|---------|
| Read | Cache → Server | Cache only |
| Write | Cache → Server (async) | Cache only, queued |
| Stream | Real-time updates | Local changes only |
| Batch | All-or-nothing | Queued as unit |

### Server Timestamps

We use `FieldValue.serverTimestamp()` for audit fields:

```dart
// Data source implementation
data['createdAt'] = FieldValue.serverTimestamp();
data['updatedAt'] = FieldValue.serverTimestamp();
```

**When App is Online**: Firebase server provides authoritative timestamp
**When App is Offline**: Timestamp is null until sync, then backfilled

### Cache Size Consideration

**Default**: 100 MB
- Sufficient for typical personal finance data
- Approximately 50,000+ documents
- Automatic eviction of least-recently-used data

**Unlimited Option**: `Settings.CACHE_SIZE_UNLIMITED`
- Use for data-heavy apps
- Requires manual cache management

---

## 4. Trade-offs Made

### 1. Subcollection vs. Top-Level Collection

| Aspect | Subcollection (Chosen) | Top-Level + Field |
|--------|----------------------|-------------------|
| Security | ✅ Path-based rules | ⚠️ Field-based rules |
| Queries | ✅ No userId filter needed | ⚠️ Always needs userId |
| Cross-user | ❌ Requires admin SDK | ✅ Easy with admin SDK |
| Analytics | ❌ Complex aggregation | ✅ Collection group queries |

**Decision**: Subcollection chosen because:
- This is a personal app (no admin dashboards)
- Security is simpler and more robust
- Performance is better for user-specific queries

### 2. YYYY-MM Document IDs vs. Auto-Generated

| Aspect | YYYY-MM (Chosen) | Auto-Generated |
|--------|------------------|----------------|
| Upsert | ✅ Natural via set() | ❌ Requires query first |
| Range Query | ✅ Document ID index | ⚠️ Needs composite index |
| UUID Collision | ✅ None possible | ✅ None possible |
| Multiple per month | ❌ Limited to one | ✅ Unlimited |

**Decision**: YYYY-MM chosen because:
- One snapshot per month is our data model
- Range queries are common (yearly reports)
- Simpler upsert logic

### 3. DTO Layer vs. Direct Entity Mapping

| Aspect | DTO Layer (Chosen) | Direct Mapping |
|--------|-------------------|----------------|
| Maintenance | ⚠️ More code | ✅ Less code |
| Flexibility | ✅ Schema evolution | ❌ Tight coupling |
| Type safety | ✅ Firestore-specific | ⚠️ Mixed concerns |
| Testing | ✅ Easy to mock | ⚠️ Harder to mock |

**Decision**: DTO layer chosen because:
- Firestore has specific types (Timestamp vs DateTime)
- Easier to evolve Firestore schema independently
- Clean separation of concerns

### 4. Client-Side Aggregation for Deficit Detection

**Issue**: Firestore doesn't support computed field queries
```dart
// This is NOT possible in Firestore:
where('totalIncome - mandatoryOutflow < 0')
```

**Options Considered**:
1. **Precompute field** (e.g., `isDeficit: true`)
   - ✅ Efficient queries
   - ❌ Requires updating on income/outflow change
   
2. **Client-side filter** (Chosen)
   - ✅ Always accurate
   - ⚠️ Fetches all documents
   
3. **Cloud Function**
   - ✅ Server-side filtering
   - ❌ Additional infrastructure

**Decision**: Client-side chosen because:
- Snapshot count is limited (~12/year)
- Accuracy is more important than query efficiency
- Simpler architecture for MVP

---

## 5. Security Rules (Recommended)

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
      
      // Contracts subcollection
      match /contracts/{contractId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
      
      // Monthly snapshots subcollection
      match /monthlySnapshots/{snapshotId} {
        allow read, write: if request.auth != null && request.auth.uid == userId;
      }
    }
    
    // Default deny
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 6. Index Requirements

### Required Indexes

Most queries use single-field or document ID ordering, which are automatically indexed.

**Composite Index Needed**:
```
Collection: users/{userId}/contracts
Fields: status (ASC), createdAt (DESC)
```

**For getContractsEndingSoon**:
```
Collection: users/{userId}/contracts
Fields: status (ASC), endDate (ASC)
```

### How to Create

Via Firebase Console or `firestore.indexes.json`:
```json
{
  "indexes": [
    {
      "collectionGroup": "contracts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "createdAt", "order": "DESCENDING" }
      ]
    },
    {
      "collectionGroup": "contracts",
      "queryScope": "COLLECTION",
      "fields": [
        { "fieldPath": "status", "order": "ASCENDING" },
        { "fieldPath": "endDate", "order": "ASCENDING" }
      ]
    }
  ]
}
```

---

## 7. Testing Strategy

### Unit Tests
- Mock `FirebaseFirestore` and `FirebaseAuthService`
- Test DTO ↔ Entity mapping
- Test error handling (exception → failure conversion)

### Integration Tests
- Use Firebase Emulator Suite
- Test offline behavior with `disableNetwork()`
- Verify batch operations atomicity

### Example Test Setup
```dart
// Use Firebase Emulator
FirebaseFirestore.instance.useFirestoreEmulator('localhost', 8080);

// Test offline mode
await FirebaseFirestore.instance.disableNetwork();
// ... perform operations
await FirebaseFirestore.instance.enableNetwork();
```

---

## 8. Future Improvements

1. **Collection Group Queries**: For admin analytics across all users
2. **Incremental Sync**: Using `source: Source.serverAndCache`
3. **Conflict Resolution**: Custom merge logic for concurrent edits
4. **Data Export**: Backup functionality using Cloud Functions
5. **Real-time Sync Status**: UI indicator for pending writes

---

## Summary

This implementation provides:
- ✅ **User-scoped data isolation** with simple security rules
- ✅ **Offline-first architecture** leveraging Firestore SDK
- ✅ **Clean architecture** with domain/data layer separation
- ✅ **Optimized reads** through smart document ID strategies
- ✅ **Type-safe mapping** between DTOs and domain entities
- ✅ **Comprehensive error handling** with Either pattern
