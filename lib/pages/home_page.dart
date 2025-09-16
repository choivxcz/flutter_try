import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_try/auth.dart';
import 'package:fl_chart/fl_chart.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController expenseController = TextEditingController();
  final TextEditingController categoryController = TextEditingController();

  final List<double> userExpenses = [];
  final List<String> userCategories = [];

  final User? user = Auth().currentUser;

  Widget _userChart() {
    return SizedBox(
      height: 300,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green,
          border: Border.all(
            color: Colors.tealAccent,
            width: 15,
          )
        ),
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: userExpenses.isNotEmpty
                ? userExpenses.reduce((a, b) => a > b ? a : b) + 5
                : 10,
            barTouchData: BarTouchData(enabled: true),
            titlesData: FlTitlesData( show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 40,
                  getTitlesWidget: (value, meta) {
                    int index = value.toInt();
                    if (index >= 0 && index < userCategories.length) {
                      return Text(
                        userCategories[index],
                        style: const TextStyle(fontSize: 12),
                      );
                    }
                    return const Text('');
                  },
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              ),
              topTitles: AxisTitles(
                sideTitles: SideTitles(showTitles: false),
              )
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(userExpenses.length, (index) {
              return BarChartGroupData(
                x: index,
                barRods: [
                  BarChartRodData(
                    toY: userExpenses[index],
                    color: Colors.amber,
                    width: 30,
                    borderRadius: BorderRadius.circular(4),
                  )
                ],
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _customTextField(String title, TextEditingController controller, {bool isNumber = false}) {
    return TextField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      decoration: InputDecoration(
        labelText: title,
        icon: const Icon(Icons.input),
        iconColor: const Color(0xFFCFC7FA),
        filled: true,
        fillColor: const Color(0xFFCFC7FA),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFCED9ED)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(width: 2, color: Color(0xFFCED9ED)),
        ),
      ),
    );
  }

  Widget _button(String title) {
    return GestureDetector(
      onTap: () {
        final double? expense = double.tryParse(expenseController.text);
        final String category = categoryController.text;

        if (expense != null && category.isNotEmpty) {
          setState(() {
            userExpenses.add(expense);
            userCategories.add(category);
          });
          expenseController.clear();
          categoryController.clear();
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFFCFC7FA),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFCED9ED)),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
        child: const Center(
          child: Text(
            'Submit',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _userChart(),
              const SizedBox(height: 20),
              _customTextField('Expense', expenseController, isNumber: true),
              const SizedBox(height: 20),
              _customTextField('Category', categoryController),
              const SizedBox(height: 20),
              _button('Submit'),
            ],
          ),
        ),
      ),
    );
  }
}
