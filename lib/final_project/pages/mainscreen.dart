import 'package:flutter/material.dart';
import 'package:flutter_try/final_project/pages/home_page.dart';
import 'package:random_string/random_string.dart';
import 'package:flutter_try/final_project/services/database.dart';
import 'package:flutter_try/final_project/services/shared_pref.dart';
import 'package:flutter_try/final_project/pages/history_page.dart';
import 'package:flutter_try/final_project/pages/chart_page.dart';
import 'package:flutter_try/final_project/pages/financial_chat_page.dart';
import 'package:flutter_try/final_project/pages/profile_page.dart';
import 'package:flutter_try/final_project/services/category_manager.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math' as math;

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  Widget _buildPage(int index) {
    switch (index) {
      case 0: return const Home();
      case 1: return const HistoryPage();
      case 3: return const FinancialAIPage();
      case 4: return const ChartPage();
      default: return const Home();
    }
  }

  void _showAddTransaction(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const AddTransactionSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.transparent,
      extendBody: true,
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
        child: _buildPage(_currentIndex),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            if (index == 2) {
              _showAddTransaction(context);
            } else {
              setState(() => _currentIndex = index);
            }
          },
          selectedItemColor: const Color(0xFFEAD25B),
          unselectedItemColor: Colors.grey.shade400,
          backgroundColor: Colors.white,
          elevation: 0,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle:
              const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle: const TextStyle(fontSize: 11),
          items: [
            const BottomNavigationBarItem(
                icon: Icon(Icons.home_rounded, size: 26), label: 'Home'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.history_rounded, size: 26), label: 'History'),
            BottomNavigationBarItem(
              icon: Container(
                width: size.width * 0.12,
                height: size.width * 0.12,
                decoration: const BoxDecoration(
                  color: Color(0xFFEAD25B),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
              ),
              label: '',
            ),
            const BottomNavigationBarItem(
                icon: Icon(Icons.message_rounded, size: 26), label: 'ChatBot'),
            const BottomNavigationBarItem(
                icon: Icon(Icons.bar_chart_rounded, size: 26), label: 'Chart'),
          ],
        ),
      ),
    );
  }
}

class AddTransactionSheet extends StatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  State<AddTransactionSheet> createState() => _AddTransactionSheetState();
}

class _AddTransactionSheetState extends State<AddTransactionSheet> {
  String _selectedTab = 'Expenses';
  String _selectedCategory = 'Groceries';
  DateTime _selectedDate = DateTime.now();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  List<String> get _currentCategories {
    final cats = _selectedTab == 'Expenses'
        ? CategoryManager.expenseCategories
        : CategoryManager.incomeCategories;
    if (_searchQuery.isEmpty) return cats;
    return cats
        .where((c) => c.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
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

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  void _showAddCategoryDialog() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFFFAF0),
        title: const Text(
          "Add Category",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 6,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              border: InputBorder.none,
              hintText: "e.g. Pets, Allowance...",
              hintStyle: TextStyle(color: Colors.grey),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            onPressed: () {
              final name = controller.text.trim();
              if (name.isEmpty) return;
              final list = _selectedTab == 'Expenses'
                  ? CategoryManager.expenseCategories
                  : CategoryManager.incomeCategories;
              if (!list.contains(name)) {
                setState(() => list.add(name));
              }
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEAD25B),
              foregroundColor: Colors.black87,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: const Text("Add", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showDeleteCategoryDialog() {
    final list = _selectedTab == 'Expenses'
        ? CategoryManager.expenseCategories
        : CategoryManager.incomeCategories;

    if (list.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("You must keep at least one category.")),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: const Color(0xFFFFFAF0),
        title: const Text(
          "Delete Category",
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Text(
          'Remove "$_selectedCategory" from the list?',
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text("Cancel", style: TextStyle(color: Colors.grey.shade500)),
          ),
          ElevatedButton(
            onPressed: () {
              setState(() {
                list.remove(_selectedCategory);
                _selectedCategory = list.first;
              });
              Navigator.pop(ctx);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD32F2F),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30)),
              elevation: 0,
            ),
            child: const Text("Delete", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  Future<void> pushingData() async {
    if (_amountController.text.isEmpty && _noteController.text.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill in all fields")),
      );
      return;
    }

    try {
      String transactionId = randomAlphaNumeric(10);
      Map<String, dynamic> transactionData = {
        'id': transactionId,
        'amount': double.parse(_amountController.text),
        'note': _noteController.text,
        'category': _selectedCategory,
        'type': _selectedTab,
        'monthKey': DatabaseMethods().monthKey(_selectedDate),
        'date': _selectedDate.toIso8601String(),
      };

      final String? userId = FirebaseAuth.instance.currentUser?.uid;

      if (userId == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("User not found, please log in again")),
        );
        return;
      }

      if (_selectedTab == 'Expenses') {
        String? currentExpenses =
            await SharedpreferenceHelper().getUserExpensesAmount();
        double newExpenses =
            (currentExpenses != null ? double.parse(currentExpenses) : 0) +
                double.parse(_amountController.text);
        await SharedpreferenceHelper()
            .saveUserExpensesAmount(newExpenses.toString());
        await DatabaseMethods().addExpenseInfo(
          transactionData, userId, transactionId,
          month: _selectedDate,
        );
      } else {
        await DatabaseMethods().addIncomeInfo(
          transactionData, userId, transactionId,
          month: _selectedDate,
        );
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Transaction saved!")),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error saving data: $e")),
      );
    }
  }

  double amountCard = 0.00;

  bool get _isToday {
    final now = DateTime.now();
    return _selectedDate.year == now.year &&
        _selectedDate.month == now.month &&
        _selectedDate.day == now.day;
  }

  String get _dateLabel {
    if (_isToday) return "Today";
    return "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}";
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Container(
          constraints: BoxConstraints(minHeight: size.height * 0.88),
          decoration: const BoxDecoration(
            color: Color(0xFFFFFAF0),
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(30),
              topRight: Radius.circular(30),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: size.width * 0.05,
              vertical: size.height * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.pop(context),
                      child: Container(
                        width: size.width * 0.09,
                        height: size.width * 0.09,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAD25B).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.arrow_back_ios_new_rounded,
                            size: 17, color: Color(0xFFEAD25B)),
                      ),
                    ),
                    const Text("Add Transaction",
                        style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                    const Icon(Icons.menu_rounded, size: 24, color: Colors.black87),
                  ],
                ),

                SizedBox(height: size.height * 0.022),
 
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(30),
                  ),
                  child: Row(
                    children: ['Expenses', 'Income'].map((tab) {
                      final isSelected = _selectedTab == tab;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() {
                            _selectedTab = tab;
                            _selectedCategory = tab == 'Expenses'
                                ? CategoryManager.expenseCategories.first
                                : CategoryManager.incomeCategories.first;
                            _searchQuery = '';
                            _searchController.clear();
                          }),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 11),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? const Color(0xFFEAD25B)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(25),
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                        color: const Color(0xFFEAD25B)
                                            .withValues(alpha: 0.4),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                      )
                                    ]
                                  : [],
                            ),
                            child: Center(
                              child: Text(
                                tab,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.grey.shade500,
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

                SizedBox(height: size.height * 0.018),

                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: "Search",
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(Icons.search_rounded,
                          color: Colors.grey.shade400, size: 22),
                      contentPadding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.02),

                Row(
                  children: [
                    const Text(
                      "Select Category",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Colors.black87),
                    ),
                    const Spacer(),
                    GestureDetector(
                      onTap: _showAddCategoryDialog,
                      child: Container(
                        width: size.width * 0.08,
                        height: size.width * 0.08,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAD25B),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFEAD25B).withValues(alpha: 0.4),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.add_rounded,
                            color: Colors.white, size: size.width * 0.045),
                      ),
                    ),
                    SizedBox(width: size.width * 0.025),
                    GestureDetector(
                      onTap: _showDeleteCategoryDialog,
                      child: Container(
                        width: size.width * 0.08,
                        height: size.width * 0.08,
                        decoration: BoxDecoration(
                          color: Colors.red.shade400,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.red.withValues(alpha: 0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(Icons.remove_rounded,
                            color: Colors.white, size: size.width * 0.045),
                      ),
                    ),
                  ],
                ),

                SizedBox(height: size.height * 0.014),

                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 3,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: _currentCategories.length,
                  itemBuilder: (context, i) {
                    final category = _currentCategories[i];
                    final isSelected = _selectedCategory == category;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedCategory = category),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? const Color(0xFFEAD25B).withValues(alpha: 0.25)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isSelected
                                ? const Color(0xFFEAD25B)
                                : Colors.transparent,
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: size.width * 0.12,
                              height: size.width * 0.12,
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? const Color(0xFFEAD25B).withValues(alpha: 0.3)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                _getCategoryIcon(category),
                                color: isSelected
                                    ? const Color(0xFFEAD25B)
                                    : Colors.grey.shade600,
                                size: size.width * 0.06,
                              ),
                            ),
                            SizedBox(height: size.height * 0.007),
                            Text(
                              category,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: size.width * 0.028,
                                fontWeight: isSelected
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: isSelected
                                    ? Colors.black87
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

                SizedBox(height: size.height * 0.02),

                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Amount:",
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: TextField(
                              controller: _amountController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: '0.00',
                                prefixText: '₱',
                                prefixStyle:
                                    TextStyle(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: size.width * 0.03),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Note:",
                              style: TextStyle(
                                  color: Colors.grey.shade500, fontSize: 13)),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 6,
                                  offset: const Offset(0, 2),
                                )
                              ],
                            ),
                            child: TextField(
                              controller: _noteController,
                              decoration: const InputDecoration(
                                border: InputBorder.none,
                                hintText: 'Enter a note...',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                SizedBox(height: size.height * 0.02),

                SizedBox(height: size.height * 0.018),

                GestureDetector(
                  onTap: () async {
                    DateTime? picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                      builder: (context, child) => Theme(
                        data: ThemeData.light().copyWith(
                          colorScheme: const ColorScheme.light(
                              primary: Color(0xFFEAD25B),
                              onPrimary: Colors.black),
                        ),
                        child: child!,
                      ),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                    }
                  },
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _dateLabel,
                        style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 14,
                            fontWeight: FontWeight.w500),
                      ),
                    ),
                  ),
                ),

                SizedBox(height: size.height * 0.03),

                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () async {
                      await pushingData();
                      if (!mounted) return;
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFEAD25B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30)),
                      elevation: 4,
                    ),
                    child: const Text('Save',
                        style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Colors.white)),
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

  Widget _accountCard(String title, String amount, Size size) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(size.width * 0.04),
        decoration: const BoxDecoration(color: Color(0xFFEAD25B)),
        child: Stack(
          children: [
            Positioned(
              right: -10,
              top: -20,
              child: Transform.rotate(
                angle: math.pi / 5,
                child: Container(
                  width: 5,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              top: -20,
              child: Transform.rotate(
                angle: math.pi / 5,
                child: Container(
                  width: 5,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87)),
                const SizedBox(height: 4),
                Text(amount,
                    style: TextStyle(
                        fontSize: 13,
                        color: Colors.black.withValues(alpha: 0.6))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}