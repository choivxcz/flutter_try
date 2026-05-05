import 'package:cloud_firestore/cloud_firestore.dart';

class DatabaseMethods {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get currentMonthKey {
    final now = DateTime.now();
    return "${now.year}-${now.month.toString().padLeft(2, '0')}";
  }

  String monthKey(DateTime date) {
    return "${date.year}-${date.month.toString().padLeft(2, '0')}";
  }

  Future addUserInfo(Map<String, dynamic> userInfoMap, String id) async {
    final data = {...userInfoMap, "balance": 0.0};
    await _db.collection("users").doc(id).set(data);
  }

  Future addExpenseInfo(
    Map<String, dynamic> expenseInfoMap,
    String userId,
    String expenseId, {
    DateTime? month,
  }) async {
    final key = month != null ? monthKey(month) : currentMonthKey;
    final data = {
      ...expenseInfoMap,
      "createdAt": expenseInfoMap['createdAt'] ?? DateTime.now().toIso8601String(),
    };
    await _db
        .collection("users")
        .doc(userId)
        .collection("months")
        .doc(key)
        .collection("expenses")
        .doc(expenseId)
        .set(data);
    await _db
        .collection("users")
        .doc(userId)
        .collection("months")
        .doc(key)
        .set({"monthKey": key}, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getExpenses(String userId, {DateTime? month}) {
    final key = month != null ? monthKey(month) : currentMonthKey;
    return _db
        .collection("users")
        .doc(userId)
        .collection("months")
        .doc(key)
        .collection("expenses")
        .snapshots();
  }

  Future addIncomeInfo(
    Map<String, dynamic> incomeInfoMap,
    String userId,
    String incomeId, {
    DateTime? month,
  }) async {
    final key = month != null ? monthKey(month) : currentMonthKey;
    final data = {
      ...incomeInfoMap,
      "createdAt": incomeInfoMap['createdAt'] ?? DateTime.now().toIso8601String(),
    };
    await _db
        .collection("users")
        .doc(userId)
        .collection("months")
        .doc(key)
        .collection("incomes")
        .doc(incomeId)
        .set(data);
    await _db
        .collection("users")
        .doc(userId)
        .collection("months")
        .doc(key)
        .set({"monthKey": key}, SetOptions(merge: true));
  }

  Stream<QuerySnapshot> getIncomes(String userId, {DateTime? month}) {
    final key = month != null ? monthKey(month) : currentMonthKey;
    return _db
        .collection("users")
        .doc(userId)
        .collection("months")
        .doc(key)
        .collection("incomes")
        .snapshots();
  }

  Stream<List<Map<String, dynamic>>> getAllTransactions(
    String userId, {
    DateTime? month,
  }) {
    final key = month != null ? monthKey(month) : currentMonthKey;
    return _db
        .collection("users")
        .doc(userId)
        .collection("months")
        .doc(key)
        .collection("expenses")
        .snapshots()
        .asyncMap((expenseSnap) async {
      final incomeSnap = await _db
          .collection("users")
          .doc(userId)
          .collection("months")
          .doc(key)
          .collection("incomes")
          .get();

      final all = <Map<String, dynamic>>[
        ...expenseSnap.docs
            .map((d) => {...d.data(), '_id': d.id, '_collection': 'expenses'})
            .where((t) => t['archived'] != true),
        ...incomeSnap.docs
            .map((d) => {...d.data(), '_id': d.id, '_collection': 'incomes'})
            .where((t) => t['archived'] != true),
      ];

      all.sort((a, b) {
        final aCreated = DateTime.tryParse(a['createdAt'] as String? ?? '');
        final bCreated = DateTime.tryParse(b['createdAt'] as String? ?? '');
        if (aCreated != null && bCreated != null) {
          return bCreated.compareTo(aCreated);
        }
        final aDate = DateTime.tryParse(a['date'] as String? ?? '') ?? DateTime(0);
        final bDate = DateTime.tryParse(b['date'] as String? ?? '') ?? DateTime(0);
        return bDate.compareTo(aDate);
      });

      return all;
    });
  }

  Stream<List<Map<String, dynamic>>> getArchivedTransactions(
    String userId, {
    DateTime? month,
  }) {
    final key = month != null ? monthKey(month) : currentMonthKey;
    return _db
        .collection("users")
        .doc(userId)
        .collection("months")
        .doc(key)
        .collection("expenses")
        .snapshots()
        .asyncMap((expenseSnap) async {
      final incomeSnap = await _db
          .collection("users")
          .doc(userId)
          .collection("months")
          .doc(key)
          .collection("incomes")
          .get();

      final all = <Map<String, dynamic>>[
        ...expenseSnap.docs
            .map((d) => {...d.data(), '_id': d.id, '_collection': 'expenses'})
            .where((t) => t['archived'] == true),
        ...incomeSnap.docs
            .map((d) => {...d.data(), '_id': d.id, '_collection': 'incomes'})
            .where((t) => t['archived'] == true),
      ];

      all.sort((a, b) {
        final aCreated = DateTime.tryParse(a['createdAt'] as String? ?? '');
        final bCreated = DateTime.tryParse(b['createdAt'] as String? ?? '');
        if (aCreated != null && bCreated != null) {
          return bCreated.compareTo(aCreated);
        }
        final aDate = DateTime.tryParse(a['date'] as String? ?? '') ?? DateTime(0);
        final bDate = DateTime.tryParse(b['date'] as String? ?? '') ?? DateTime(0);
        return bDate.compareTo(aDate);
      });

      return all;
    });
  }

  Future<void> archiveTransaction(
    String userId,
    String monthKey,
    String transactionId,
    String collection, {
    required double amount,
    required String type,
  }) async {
    await _db
        .collection("users")
        .doc(userId)
        .collection("months")
        .doc(monthKey)
        .collection(collection)
        .doc(transactionId)
        .update({"archived": true});

    final adjustment = type == 'Expenses' ? amount : -amount;
    await updateBalance(userId, adjustment);
  }

  Future<void> unarchiveTransaction(
    String userId,
    String monthKey,
    String transactionId,
    String collection, {
    required double amount,
    required String type,
  }) async {
    await _db
        .collection("users")
        .doc(userId)
        .collection("months")
        .doc(monthKey)
        .collection(collection)
        .doc(transactionId)
        .update({"archived": false});

    final adjustment = type == 'Expenses' ? -amount : amount;
    await updateBalance(userId, adjustment);
  }

  Future<List<String>> getAvailableMonths(String userId) async {
    final snapshot = await _db
        .collection("users")
        .doc(userId)
        .collection("months")
        .where("monthKey", isGreaterThanOrEqualTo: "")
        .get();
    final keys = snapshot.docs.map((doc) => doc.id).toList();
    keys.sort((a, b) => b.compareTo(a));
    return keys;
  }

  Future updateMonthlySummary(
    String userId,
    Map<String, dynamic> summaryMap, {
    DateTime? month,
  }) async {
    final key = month != null ? monthKey(month) : currentMonthKey;
    await _db
        .collection("users")
        .doc(userId)
        .collection("months")
        .doc(key)
        .set(summaryMap, SetOptions(merge: true));
  }

  Future<Map<String, dynamic>?> getMonthlySummary(
    String userId, {
    DateTime? month,
  }) async {
    final key = month != null ? monthKey(month) : currentMonthKey;
    final doc = await _db
        .collection("users")
        .doc(userId)
        .collection("months")
        .doc(key)
        .get();
    return doc.data();
  }

  Stream<DocumentSnapshot> getMonthlySummaryStream(
    String userId, {
    DateTime? month,
  }) {
    final key = month != null ? monthKey(month) : currentMonthKey;
    return _db
        .collection("users")
        .doc(userId)
        .collection("months")
        .doc(key)
        .snapshots();
  }

  Future cashAmountInfo(
      Map<String, dynamic> cashAmountInfoMap, String userId) async {
    await updateMonthlySummary(userId, {"cashAmount": cashAmountInfoMap});
  }

  Future cardAmountInfo(
      Map<String, dynamic> cardAmountInfoMap, String userId) async {
    await updateMonthlySummary(userId, {"cardAmount": cardAmountInfoMap});
  }

  Future<void> updateBalance(String userId, double amount) async {
    await _db.runTransaction((transaction) async {
      final userRef = _db.collection("users").doc(userId);
      final snapshot = await transaction.get(userRef);
      final currentBalance =
          (snapshot.data()?['balance'] as num?)?.toDouble() ?? 0.0;
      transaction.update(userRef, {"balance": currentBalance + amount});
    });
  }

  Stream<double> getBalanceStream(String userId) {
    return _db
        .collection("users")
        .doc(userId)
        .snapshots()
        .map((doc) => (doc.data()?['balance'] as num?)?.toDouble() ?? 0.0);
  }
}