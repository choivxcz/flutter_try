import 'package:flutter/material.dart';
import 'package:flutter_try/final_project/services/database.dart';

class ArchivedPage extends StatefulWidget {
  final String userId;

  const ArchivedPage({super.key, required this.userId});

  @override
  State<ArchivedPage> createState() => _ArchivedPageState();
}

class _ArchivedPageState extends State<ArchivedPage> {
  final DatabaseMethods _db = DatabaseMethods();

  List<String> _availableMonths = [];
  String? _selectedMonth;
  bool _loadingMonths = true;

  @override
  void initState() {
    super.initState();
    _loadMonths();
  }

  Future<void> _loadMonths() async {
    setState(() => _loadingMonths = true);
    final months = await _db.getAvailableMonths(widget.userId);
    if (!mounted) return;
    setState(() {
      _availableMonths = months;
      _selectedMonth = months.isNotEmpty ? months.first : null;
      _loadingMonths = false;
    });
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

  Future<void> _confirmUnarchive(Map<String, dynamic> t) async {
    final docId = t['_id'] as String?;
    final collection = t['_collection'] as String?;
    if (docId == null || collection == null || _selectedMonth == null) return;

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
                color: Colors.teal.shade50,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.unarchive_rounded,
                  color: Colors.teal.shade700, size: 22),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Unarchive Transaction',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: Text(
          'Restore "$category" back to your history? '
          'Its amount will be re-applied to your balance.',
          style: const TextStyle(fontSize: 14, color: Colors.black87),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child:
                Text('Cancel', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.teal.shade600,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0,
            ),
            icon: const Icon(Icons.unarchive_rounded, size: 16),
            label: const Text('Restore'),
            onPressed: () => Navigator.pop(ctx, true),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _db.unarchiveTransaction(
        widget.userId,
        _selectedMonth!,
        docId,
        collection,
        amount: amount,
        type: type,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('"$category" restored to history. Balance updated.'),
            backgroundColor: Colors.teal.shade600,
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
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new_rounded),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      "Archived Transactions",
                      style: TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded,
                        color: Color(0xFFEAD25B)),
                    tooltip: 'Refresh',
                    onPressed: _loadMonths,
                  ),
                ],
              ),
            ),
          
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade100),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline_rounded,
                        size: 18, color: Colors.orange.shade700),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Tap the restore button to unarchive a transaction and re-apply it to your balance.',
                        style: TextStyle(
                            fontSize: 12, color: Colors.orange.shade800),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            if (_loadingMonths)
              const Center(child: CircularProgressIndicator())
            else if (_availableMonths.isEmpty)
              const Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.inventory_2_rounded,
                          size: 60, color: Color(0xFFEAD25B)),
                      SizedBox(height: 12),
                      Text("No archived transactions.",
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
                              : Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _formatMonthKey(month),
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isSelected
                                ? Colors.white
                                : Colors.black54,
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
                        child: Text("Select a month to view archives."))
                    : _ArchivedList(
                        userId: widget.userId,
                        monthKey: _selectedMonth!,
                        db: _db,
                        getCategoryIcon: _getCategoryIcon,
                        onUnarchive: _confirmUnarchive,
                      ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ArchivedList extends StatelessWidget {
  final String userId;
  final String monthKey;
  final DatabaseMethods db;
  final IconData Function(String) getCategoryIcon;
  final Future<void> Function(Map<String, dynamic>) onUnarchive;

  const _ArchivedList({
    required this.userId,
    required this.monthKey,
    required this.db,
    required this.getCategoryIcon,
    required this.onUnarchive,
  });

  @override
  Widget build(BuildContext context) {
    final parts = monthKey.split('-');
    final month = DateTime(int.parse(parts[0]), int.parse(parts[1]));

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: db.getArchivedTransactions(userId, month: month),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final transactions = snapshot.data ?? [];

        if (transactions.isEmpty) {
          return Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.inventory_2_outlined,
                    size: 56, color: Colors.grey.shade300),
                const SizedBox(height: 12),
                Text(
                  "No archived transactions\nfor this month.",
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
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
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: Colors.grey.shade300),
              ),
              child: Row(
                children: [

                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      getCategoryIcon(category),
                      color: Colors.grey.shade500,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          category,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                              color: Colors.grey.shade700),
                        ),
                        if (note.isNotEmpty)
                          Text(note,
                              style: TextStyle(
                                  color: Colors.grey.shade400, fontSize: 12)),
                        Text(dateLabel,
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 11)),
                      ],
                    ),
                  ),

                  Text(
                    "${isExpense ? '-' : '+'}₱${amount.toStringAsFixed(2)}",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                      color: Colors.grey.shade500,
                    ),
                  ),

                  IconButton(
                    onPressed: () => onUnarchive(t),
                    icon: Icon(Icons.unarchive_rounded,
                        size: 20, color: Colors.teal.shade400),
                    tooltip: 'Restore',
                    splashRadius: 20,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}