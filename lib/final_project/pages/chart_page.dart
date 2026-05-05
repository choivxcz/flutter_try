import 'package:flutter/material.dart';
import 'package:flutter_try/final_project/pages/mainscreen.dart';
import 'package:flutter_try/final_project/services/database.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ChartPage extends StatefulWidget {
  const ChartPage({super.key});

  @override
  State<ChartPage> createState() => _ChartPageState();
}

class _ChartPageState extends State<ChartPage> {
  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  DateTime _viewingMonth = DateTime(DateTime.now().year, DateTime.now().month);

  final DatabaseMethods _db = DatabaseMethods();

  final List<Color> _colorPool = [
    Colors.redAccent,
    Colors.blueAccent,
    Colors.orange,
    Colors.lightGreen,
    Colors.purpleAccent,
    Colors.teal,
    Colors.pinkAccent,
    Colors.amber,
    Colors.cyan,
    Colors.deepOrange,
  ];

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Groceries':      return Icons.local_grocery_store;
      case 'Shopping':       return Icons.shopping_bag;
      case 'Medicine':       return Icons.medical_services;
      case 'Entertainment':  return Icons.theaters;
      case 'Utilities':      return Icons.lightbulb;
      case 'Transportation': return Icons.directions_car;
      default:               return Icons.category;
    }
  }

  Stream<Map<String, double>> _expenseStream(String userId) {
    return _db
        .getExpenses(userId, month: _viewingMonth)
        .map((snapshot) {
      final Map<String, double> grouped = {};
      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        if (data['archived'] == true) continue;

        final type = data['type'] as String? ?? '';
        if (type != 'Expenses') continue;

        final category = data['category'] as String? ?? 'Other';
        final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
        grouped[category] = (grouped[category] ?? 0) + amount;
      }
      return grouped;
    });
  }

  List<PieChartSectionData> _buildSections(Map<String, double> data) {
    if (data.isEmpty) {
      return [
        PieChartSectionData(
          value: 1,
          color: Colors.grey.shade300,
          radius: 28,
          showTitle: false,
        ),
      ];
    }
    final entries = data.entries.toList();
    return List.generate(entries.length, (i) {
      return PieChartSectionData(
        value: entries[i].value,
        color: _colorPool[i % _colorPool.length],
        radius: 28,
        showTitle: false,
      );
    });
  }

  void _prevMonth() => setState(() {
        _viewingMonth = DateTime(_viewingMonth.year, _viewingMonth.month - 1);
      });

  void _nextMonth() {
    final now = DateTime.now();
    final next = DateTime(_viewingMonth.year, _viewingMonth.month + 1);
    if (!next.isAfter(DateTime(now.year, now.month))) {
      setState(() => _viewingMonth = next);
    }
  }

  String get _monthLabel {
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return "${months[_viewingMonth.month]} ${_viewingMonth.year}";
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isCurrentMonth =
        _viewingMonth.year == now.year && _viewingMonth.month == now.month;

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
        child: Container(
          margin: const EdgeInsets.only(left: 20.0, right: 20.0, bottom: 20.0),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    margin: const EdgeInsets.only(top: 55.0, right: 20.0),
                    child: IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          size: 30, color: Color(0xFFEAD25B)),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => MainScreen()),
                      ),
                    ),
                  ),
                  Container(
                    margin: const EdgeInsets.only(
                        top: 55.0, right: 20.0, left: 15.0),
                    child: const Text(
                      "Expenses",
                      style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 50),
                ],
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: _prevMonth,
                  ),
                  Text(
                    _monthLabel,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: isCurrentMonth
                          ? Colors.grey.shade300
                          : Colors.black,
                    ),
                    onPressed: isCurrentMonth ? null : _nextMonth,
                  ),
                ],
              ),

              const SizedBox(height: 8),

              Expanded(
                key: ValueKey(_viewingMonth),
                child: StreamBuilder<Map<String, double>>(
                  stream: _expenseStream(_userId!),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(child: Text('Error: ${snapshot.error}'));
                    }

                    final data = snapshot.data ?? {};
                    final total = data.values.fold(0.0, (sum, v) => sum + v);
                    final entries = data.entries.toList();

                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          SizedBox(
                            width: 220,
                            height: 220,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                PieChart(
                                  PieChartData(
                                    sectionsSpace: 4,
                                    centerSpaceRadius: 70,
                                    startDegreeOffset: -90,
                                    sections: _buildSections(data),
                                  ),
                                ),
                                Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      '₱${total.toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 20,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _monthLabel,
                                      style: const TextStyle(
                                          fontSize: 11, color: Colors.grey),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 20),

                          if (data.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 20),
                              child: Text(
                                'No expenses recorded for this month.',
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          else
                            ...List.generate(entries.length, (i) {
                              final category = entries[i].key;
                              final amount = entries[i].value;
                              final color = _colorPool[i % _colorPool.length];
                              final percent = total > 0
                                  ? (amount / total * 100).toStringAsFixed(1)
                                  : '0.0';

                              return Container(
                                margin: const EdgeInsets.only(bottom: 10),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 12),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.75),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 38,
                                      height: 38,
                                      decoration: BoxDecoration(
                                        color: color.withOpacity(0.15),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Icon(
                                        _getCategoryIcon(category),
                                        color: color,
                                        size: 20,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(category,
                                              style: const TextStyle(
                                                  fontSize: 15,
                                                  fontWeight: FontWeight.w500)),
                                          const SizedBox(height: 4),
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(4),
                                            child: LinearProgressIndicator(
                                              value: total > 0
                                                  ? amount / total
                                                  : 0,
                                              backgroundColor:
                                                  Colors.grey.shade300,
                                              color: color,
                                              minHeight: 6,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          '₱${amount.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 15),
                                        ),
                                        Text(
                                          '$percent%',
                                          style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 12),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}