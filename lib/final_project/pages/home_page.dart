import 'package:flutter/material.dart';
import 'package:flutter_try/final_project/services/database.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_try/final_project/pages/profile_page.dart';
import 'dart:math' as math;

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  final DatabaseMethods _db = DatabaseMethods();
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  String get _displayName {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return '';
    if (user.displayName != null && user.displayName!.trim().isNotEmpty) {
      return user.displayName!.trim();
    }
    final email = user.email ?? '';
    return email.contains('@') ? email.split('@').first : email;
  }

  String _searchQuery = '';

  Stream<double> get _monthlyExpensesStream {
    if (_userId == null) return Stream.value(0.0);
    return _db.getExpenses(_userId!).map((snapshot) {
      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['archived'] == true) continue;
        if (data['type'] == 'Expenses') {
          total += (data['amount'] as num?)?.toDouble() ?? 0;
        }
      }
      return total;
    });
  }

  Stream<double> get _monthlyIncomeStream {
    if (_userId == null) return Stream.value(0.0);
    return _db.getIncomes(_userId!).map((snapshot) {
      double total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        if (data['archived'] == true) continue;
        total += (data['amount'] as num?)?.toDouble() ?? 0;
      }
      return total;
    });
  }

  Stream<List<Map<String, dynamic>>> get _recentTransactionsStream {
    if (_userId == null) return Stream.value([]);
    return _db
        .getAllTransactions(_userId!)
        .map((list) => list.take(5).toList());
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Groceries':      return Icons.local_grocery_store;
      case 'Shopping':       return Icons.shopping_bag;
      case 'Medicine':       return Icons.medical_services;
      case 'Entertainment':  return Icons.theaters;
      case 'Utilities':      return Icons.lightbulb;
      case 'Transportation': return Icons.directions_car;
      case 'Salary':         return Icons.account_balance_wallet;
      case 'Freelance':      return Icons.laptop;
      case 'Business':       return Icons.business;
      case 'Investment':     return Icons.trending_up;
      default:               return Icons.category;
    }
  }

  void _showAddExpenseDialog() {
    final amountController = TextEditingController();
    final noteController   = TextEditingController();
  }

  String _formatDate(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    const months = [
      '', 'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = date.minute.toString().padLeft(2, '0');
    final ampm = date.hour < 12 ? 'AM' : 'PM';
    return "${date.day} ${months[date.month]} ${date.year} - $hour:$minute $ampm";
  }

  void _showSearchSheet(
    BuildContext context,
    List<Map<String, dynamic>> allTransactions,
    Size size,
  ) {
    final searchController = TextEditingController(text: _searchQuery);
    List<Map<String, dynamic>> filtered = _filterTransactions(
      allTransactions,
      _searchQuery,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                top: size.height * 0.025,
                left: size.width * 0.05,
                right: size.width * 0.05,
                bottom: MediaQuery.of(ctx).viewInsets.bottom +
                    size.height * 0.025,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: searchController,
                    autofocus: true,
                    decoration: InputDecoration(
                      hintText: 'Search by category or amount…',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: size.width * 0.035,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: Colors.black45,
                        size: size.width * 0.05,
                      ),
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              icon: Icon(Icons.clear_rounded,
                                  color: Colors.black38,
                                  size: size.width * 0.045),
                              onPressed: () {
                                searchController.clear();
                                setSheetState(() {
                                  filtered = allTransactions;
                                });
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      contentPadding: EdgeInsets.symmetric(
                        vertical: size.height * 0.015,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (query) {
                      setSheetState(() {
                        filtered = _filterTransactions(allTransactions, query);
                      });
                      setState(() => _searchQuery = query);
                    },
                  ),

                  SizedBox(height: size.height * 0.018),

                  Text(
                    filtered.isEmpty
                        ? 'No results'
                        : '${filtered.length} result${filtered.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: size.width * 0.03,
                    ),
                  ),

                  SizedBox(height: size.height * 0.01),

                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: size.height * 0.45,
                    ),
                    child: filtered.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(
                                vertical: size.height * 0.03),
                            child: Center(
                              child: Text(
                                'No transactions found.',
                                style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: size.width * 0.035,
                                ),
                              ),
                            ),
                          )
                        : ListView.builder(
                            shrinkWrap: true,
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final t = filtered[i];
                              final isExpense = t['type'] == 'Expenses';
                              final amount =
                                  (t['amount'] as num?)?.toDouble() ?? 0;
                              final category =
                                  t['category'] as String? ?? 'Other';
                              final dateStr = t['date'] as String? ?? '';
                              final dateLabel = _formatDate(dateStr);

                              return Container(
                                margin: EdgeInsets.only(
                                    bottom: size.height * 0.012),
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.03,
                                  vertical: size.height * 0.012,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: size.width * 0.11,
                                      height: size.width * 0.11,
                                      decoration: BoxDecoration(
                                        color: isExpense
                                            ? const Color(0xFFEA8A5B)
                                                .withValues(alpha: 0.85)
                                            : const Color(0xFFBBEA5B)
                                                .withValues(alpha: 0.85),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(category),
                                        color: Colors.white,
                                        size: size.width * 0.055,
                                      ),
                                    ),
                                    SizedBox(width: size.width * 0.03),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: size.width * 0.037,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (dateLabel.isNotEmpty)
                                            Text(
                                              dateLabel,
                                              style: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontSize: size.width * 0.028,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    Text(
                                      "${isExpense ? '-' : '+'}₱${amount.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: size.width * 0.037,
                                        color: isExpense
                                            ? Colors.red.shade400
                                            : Colors.green.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  List<Map<String, dynamic>> _filterTransactions(
    List<Map<String, dynamic>> transactions,
    String query,
  ) {
    if (query.trim().isEmpty) return transactions;
    final q = query.trim().toLowerCase();
    return transactions.where((t) {
      final category = (t['category'] as String? ?? '').toLowerCase();
      final amount =
          (t['amount'] as num?)?.toDouble().toStringAsFixed(2) ?? '';
      return category.contains(q) || amount.contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.7, 1.0],
            colors: [
              Color(0xFFFFFAF0),
              Color(0xFFFFFAF0),
              Color(0xFFEAD25B),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.05,
              vertical: size.height * 0.015,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const ProfilePage()));
                      },
                      child: CircleAvatar(
                        radius: size.width * 0.06,
                        backgroundColor: Colors.grey.shade300,
                        child: Icon(Icons.person_rounded,
                            color: Colors.white, size: size.width * 0.07),
                      ),
                    ),
                    SizedBox(width: size.width * 0.03),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Welcome back!",
                          style: TextStyle(
                            fontSize: size.width * 0.03,
                            color: Colors.black54,
                          ),
                        ),
                        Text(
                          _displayName,
                          style: TextStyle(
                            fontSize: size.width * 0.04,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                    const Spacer(),
                    Icon(Icons.send_rounded,
                        color: Colors.black45, size: size.width * 0.055),
                    SizedBox(width: size.width * 0.03),
                    Icon(Icons.menu_rounded,
                        color: Colors.black45, size: size.width * 0.055),
                  ],
                ),

                SizedBox(height: size.height * 0.022),

                StreamBuilder<double>(
                  stream: _db.getBalanceStream(_userId!),
                  builder: (context, snapshot) {
                    final balance = snapshot.data ?? 0.0;
                    return ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: Container(
                        width: double.infinity,
                        padding: EdgeInsets.all(size.width * 0.055),
                        decoration:
                            const BoxDecoration(color: Color(0xFFEAD25B)),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -15,
                              top: -35,
                              child: Transform.rotate(
                                angle: math.pi / 5,
                                child: Container(
                                  width: 6,
                                  height: 170,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 15,
                              top: -35,
                              child: Transform.rotate(
                                angle: math.pi / 5,
                                child: Container(
                                  width: 6,
                                  height: 170,
                                  decoration: BoxDecoration(
                                    color:
                                        Colors.white.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              right: 42,
                              top: -35,
                              child: Transform.rotate(
                                angle: math.pi / 5,
                                child: Container(
                                  width: 4,
                                  height: 170,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      "Available balance",
                                      style: TextStyle(
                                        fontSize: size.width * 0.032,
                                        color: Colors.black54,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    SizedBox(width: size.width * 0.015),
                                    Icon(Icons.visibility_off_outlined,
                                        size: size.width * 0.04,
                                        color: Colors.black38),
                                  ],
                                ),
                                SizedBox(height: size.height * 0.012),
                                FittedBox(
                                  child: Text(
                                    "₱${balance.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: size.width * 0.07,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: size.height * 0.015),

                Row(
                  children: [
                    Expanded(
                      child: StreamBuilder<double>(
                        stream: _monthlyExpensesStream,
                        builder: (context, snapshot) {
                          final expenses = snapshot.data ?? 0.0;
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.04,
                              vertical: size.height * 0.015,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFBBEA5B),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: size.width * 0.07,
                                      height: size.width * 0.07,
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.45),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                          Icons.arrow_downward_rounded,
                                          size: size.width * 0.038,
                                          color: Colors.black87),
                                    ),
                                    SizedBox(width: size.width * 0.015),
                                    Text(
                                      "Expenses",
                                      style: TextStyle(
                                        fontSize: size.width * 0.03,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: size.height * 0.008),
                                FittedBox(
                                  child: Text(
                                    "-₱${expenses.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: size.width * 0.042,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),

                    SizedBox(width: size.width * 0.03),

                    Expanded(
                      child: StreamBuilder<double>(
                        stream: _monthlyIncomeStream,
                        builder: (context, snapshot) {
                          final income = snapshot.data ?? 0.0;
                          return Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.04,
                              vertical: size.height * 0.015,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEA8A5B),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: size.width * 0.07,
                                      height: size.width * 0.07,
                                      decoration: BoxDecoration(
                                        color: Colors.white
                                            .withValues(alpha: 0.35),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                          Icons.trending_up_rounded,
                                          size: size.width * 0.038,
                                          color: Colors.black87),
                                    ),
                                    SizedBox(width: size.width * 0.015),
                                    Text(
                                      "Income",
                                      style: TextStyle(
                                        fontSize: size.width * 0.03,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                                SizedBox(height: size.height * 0.008),
                                FittedBox(
                                  child: Text(
                                    "+₱${income.toStringAsFixed(2)}",
                                    style: TextStyle(
                                      fontSize: size.width * 0.042,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                SizedBox(height: size.height * 0.022),

                Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(size.width * 0.045),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _recentTransactionsStream,
                        builder: (context, snapshot) {
                          final transactions = snapshot.data ?? [];
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "Recent Transaction",
                                style: TextStyle(
                                  fontSize: size.width * 0.042,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black87,
                                ),
                              ),
                              GestureDetector(
                                onTap: () => _showSearchSheet(
                                    context, transactions, size),
                                child: Container(
                                  width: size.width * 0.09,
                                  height: size.width * 0.09,
                                  decoration: BoxDecoration(
                                    color: Colors.grey.shade100,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(Icons.search_rounded,
                                      size: size.width * 0.045,
                                      color: Colors.black54),
                                ),
                              ),
                            ],
                          );
                        },
                      ),

                      SizedBox(height: size.height * 0.015),

                      StreamBuilder<List<Map<String, dynamic>>>(
                        stream: _recentTransactionsStream,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator(
                                    color: Color(0xFFEAD25B)));
                          }
                          final transactions = snapshot.data ?? [];
                          if (transactions.isEmpty) {
                            return Padding(
                              padding: EdgeInsets.symmetric(
                                  vertical: size.height * 0.02),
                              child: Center(
                                child: Text(
                                  "No transactions yet.",
                                  style: TextStyle(
                                      color: Colors.grey.shade400,
                                      fontSize: size.width * 0.035),
                                ),
                              ),
                            );
                          }

                          return Column(
                            children: transactions.map((t) {
                              final isExpense = t['type'] == 'Expenses';
                              final amount =
                                  (t['amount'] as num?)?.toDouble() ?? 0;
                              final category =
                                  t['category'] as String? ?? 'Other';
                              final dateStr = t['date'] as String? ?? '';
                              final dateLabel = _formatDate(dateStr);

                              return Container(
                                margin: EdgeInsets.only(
                                    bottom: size.height * 0.012),
                                padding: EdgeInsets.symmetric(
                                  horizontal: size.width * 0.03,
                                  vertical: size.height * 0.012,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade50,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: size.width * 0.11,
                                      height: size.width * 0.11,
                                      decoration: BoxDecoration(
                                        color: isExpense
                                            ? const Color(0xFFEA8A5B)
                                                .withValues(alpha: 0.85)
                                            : const Color(0xFFBBEA5B)
                                                .withValues(alpha: 0.85),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(category),
                                        color: Colors.white,
                                        size: size.width * 0.055,
                                      ),
                                    ),

                                    SizedBox(width: size.width * 0.03),

                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            category,
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              fontSize: size.width * 0.037,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          if (dateLabel.isNotEmpty)
                                            Text(
                                              dateLabel,
                                              style: TextStyle(
                                                color: Colors.grey.shade400,
                                                fontSize: size.width * 0.028,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),

                                    Text(
                                      "${isExpense ? '-' : '+'}₱${amount.toStringAsFixed(2)}",
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: size.width * 0.037,
                                        color: isExpense
                                            ? Colors.red.shade400
                                            : Colors.green.shade500,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          );
                        },
                      ),
                    ],
                  ),
                ),

                SizedBox(height: size.height * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }
}