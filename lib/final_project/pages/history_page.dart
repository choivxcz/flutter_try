import 'package:flutter/material.dart';
import 'package:flutter_try/final_project/services/database.dart';
import 'package:flutter_try/final_project/pages/archived_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  List<String> _availableMonths = [];
  String? _selectedMonth;
  bool _loadingMonths = true;

  final DatabaseMethods _db = DatabaseMethods();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    String? id = _userId;
    if (id == null) {
      await FirebaseAuth.instance
          .authStateChanges()
          .firstWhere((u) => u != null);
      id = FirebaseAuth.instance.currentUser?.uid;
    }
    if (id == null) {
      if (!mounted) return;
      setState(() => _loadingMonths = false);
      return;
    }
    final months = await _db.getAvailableMonths(id);
    if (!mounted) return;
    setState(() {
      _availableMonths = months;
      _selectedMonth = months.isNotEmpty ? months.first : null;
      _loadingMonths = false;
    });
  }

  Future<void> _refresh() async {
    setState(() => _loadingMonths = true);
    await _loadData();
  }

  String _formatMonthKey(String key) {
    const monthNames = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    final parts = key.split('-');
    if (parts.length != 2) return key;
    final month = int.tryParse(parts[1]) ?? 0;
    return "${monthNames[month]} ${parts[0]}";
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

  @override
  Widget build(BuildContext context) {
    if (_userId == null) {
      return const Scaffold(
        body: Center(child: Text('No user logged in.')),
      );
    }

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      "History",
                      style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.inventory_2_rounded,
                              color: Color(0xFFEAD25B)),
                          tooltip: 'View Archived',
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ArchivedPage(userId: _userId!),
                              ),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh_rounded,
                              color: Color(0xFFEAD25B)),
                          tooltip: 'Refresh',
                          onPressed: _refresh,
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              if (_loadingMonths)
                const Center(child: CircularProgressIndicator())
              else if (_availableMonths.isEmpty)
                const Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.history_rounded,
                            size: 60, color: Color(0xFFEAD25B)),
                        SizedBox(height: 12),
                        Text("No transactions yet.",
                            style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ),
                )
              else ...[
                SizedBox(
                  height: 40,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _availableMonths.length,
                    itemBuilder: (context, i) {
                      final month = _availableMonths[i];
                      final isSelected = month == _selectedMonth;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedMonth = month),
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFFEAD25B)
                                : Colors.white.withValues(alpha: 0.7),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _formatMonthKey(month),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black54,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const SizedBox(height: 16),

                Expanded(
                  child: _selectedMonth == null
                      ? const Center(
                          child: Text("Select a month to view history."))
                      : _TransactionList(
                          userId: _userId!,
                          monthKey: _selectedMonth!,
                          db: _db,
                          getCategoryIcon: _getCategoryIcon,
                        ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _TransactionList extends StatelessWidget {
  final String userId;
  final String monthKey;
  final DatabaseMethods db;
  final IconData Function(String) getCategoryIcon;

  const _TransactionList({
    required this.userId,
    required this.monthKey,
    required this.db,
    required this.getCategoryIcon,
  });

  Future<void> _confirmArchive(
      BuildContext context, Map<String, dynamic> t) async {
    final docId = t['_id'] as String?;
    final collection = t['_collection'] as String?;
    if (docId == null || collection == null) return;

    final category = t['category'] as String? ?? 'this transaction';
    final amount = (t['amount'] as num?)?.toDouble() ?? 0.0;
    final type = t['type'] as String? ?? 'Expenses';

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.archive_rounded,
                  color: Colors.orange.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Archive Transaction',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Are you sure you want to archive "$category"? '
          'It will be removed from your history and its amount will be reversed from your balance.',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel',
                style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            icon: const Icon(Icons.archive_rounded, size: 16),
            label: const Text('Archive'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await db.archiveTransaction(
        userId,
        monthKey,
        docId,
        collection,
        amount: amount,
        type: type,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$category" archived. Balance updated.'),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final parts = monthKey.split('-');
    final month = DateTime(int.parse(parts[0]), int.parse(parts[1]));

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db.getAllTransactions(userId, month: month),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return const Center(
            child: Text("No transactions for this month.",
                style: TextStyle(color: Colors.grey)),
          );
        }

        double totalExpenses = 0;
        double totalIncome = 0;
        for (final t in transactions) {
          final amount = (t['amount'] as num?)?.toDouble() ?? 0;
          if (t['type'] == 'Expenses') {
            totalExpenses += amount;
          } else {
            totalIncome += amount;
          }
        }

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Income",
                              style:
                                  TextStyle(color: Colors.green, fontSize: 12)),
                          Text(
                            "₱${totalIncome.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Expenses",
                              style:
                                  TextStyle(color: Colors.red, fontSize: 12)),
                          Text(
                            "₱${totalExpenses.toStringAsFixed(2)}",
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: transactions.length,
                itemBuilder: (context, i) {
                  final t = transactions[i];
                  final isExpense = t['type'] == 'Expenses';
                  final amount = (t['amount'] as num?)?.toDouble() ?? 0;
                  final category = t['category'] as String? ?? 'Other';
                  final note = t['note'] as String? ?? '';
                  final dateStr = t['date'] as String? ?? '';
                  final date = DateTime.tryParse(dateStr);
                  final dateLabel = date != null
                      ? "${date.day}/${date.month}/${date.year}"
                      : '';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.only(
                        left: 14, top: 12, bottom: 12, right: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: Colors.grey.shade200),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.03),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isExpense
                                ? Colors.red.shade50
                                : Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            getCategoryIcon(category),
                            color: isExpense ? Colors.red : Colors.green,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),

                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(category,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15)),
                              if (note.isNotEmpty)
                                Text(note,
                                    style: TextStyle(
                                        color: Colors.grey.shade500,
                                        fontSize: 12)),
                              Text(dateLabel,
                                  style: TextStyle(
                                      color: Colors.yellowAccent.shade700,
                                      fontSize: 11)),
                            ],
                          ),
                        ),

                        Text(
                          "${isExpense ? '-' : '+'}₱${amount.toStringAsFixed(2)}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isExpense ? Colors.red : Colors.green,
                          ),
                        ),

                        IconButton(
                          onPressed: () => _confirmArchive(context, t),
                          icon: Icon(Icons.archive_rounded,
                              size: 20, color: Colors.grey.shade400),
                          tooltip: 'Archive',
                          splashRadius: 20,
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8),
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}