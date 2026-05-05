import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_try/final_project/services/database.dart';
import 'package:flutter_try/final_project/services/openai_service.dart';
import 'package:flutter_try/final_project/ai_model/message.dart';

class FinancialAIService {
  final OpenAIService _api = OpenAIService();
  final DatabaseMethods _db = DatabaseMethods();

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<Map<String, dynamic>> fetchFinancialSummary({DateTime? month}) async {
    final uid = _userId;
    if (uid == null) return {};

    final targetMonth = month ?? DateTime.now();
    final List<Map<String, dynamic>> transactions =
        await _db.getAllTransactions(uid, month: targetMonth).first;

    double totalIncome = 0;
    double totalExpenses = 0;
    final Map<String, double> expensesByCategory = {};
    final Map<String, double> incomeByCategory = {};

    for (final t in transactions) {
      final type = t['type'] as String? ?? '';
      final amount = (t['amount'] as num?)?.toDouble() ?? 0;
      final category = t['category'] as String? ?? 'Others';

      if (type == 'Expenses') {
        totalExpenses += amount;
        expensesByCategory[category] =
            (expensesByCategory[category] ?? 0) + amount;
      } else if (type == 'Income') {
        totalIncome += amount;
        incomeByCategory[category] =
            (incomeByCategory[category] ?? 0) + amount;
      }
    }

    final double balance =
        uid.isNotEmpty ? await _db.getBalanceStream(uid).first : 0.0;

    return {
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'balance': balance,
      'expensesByCategory': expensesByCategory,
      'incomeByCategory': incomeByCategory,
      'month': targetMonth,
    };
  }

  String buildSystemPrompt(
    Map<String, dynamic> summary, {
    Map<String, dynamic>? prevSummary,
  }) {
    final month = summary['month'] as DateTime? ?? DateTime.now();
    final totalIncome = (summary['totalIncome'] as double? ?? 0);
    final totalExpenses = (summary['totalExpenses'] as double? ?? 0);
    final balance = (summary['balance'] as double? ?? 0);
    final expCat =
        (summary['expensesByCategory'] as Map<String, double>?) ?? {};
    final incCat = (summary['incomeByCategory'] as Map<String, double>?) ?? {};

    final netSavings = totalIncome - totalExpenses;
    final savingsRate = totalIncome > 0
        ? (netSavings / totalIncome * 100).toStringAsFixed(1)
        : '0.0';

    final recommendedSavingsAmt = totalIncome * 0.20;
    final recommendedSavingsPct = '20.0';
    final additionalSavingsNeeded =
        (recommendedSavingsAmt - netSavings).clamp(0, double.infinity);

    final sortedExp = expCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategory = sortedExp.isNotEmpty ? sortedExp.first.key : 'None';

    final expBreakdown = sortedExp.isEmpty
        ? 'No expenses recorded this month.'
        : sortedExp.map((e) {
            final pct = totalExpenses > 0
                ? (e.value / totalExpenses * 100).toStringAsFixed(1)
                : '0.0';
            return '${e.key}: ₱${e.value.toStringAsFixed(2)} ($pct% of total expenses)';
          }).join('\n');

    final sortedInc = incCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final incBreakdown = sortedInc.isEmpty
        ? 'No income recorded this month.'
        : sortedInc
            .map((e) => '${e.key}: ₱${e.value.toStringAsFixed(2)}')
            .join('\n');

    String prevContext = '';
    if (prevSummary != null) {
      final prevMonth = prevSummary['month'] as DateTime;
      final prevExpenses = (prevSummary['totalExpenses'] as double? ?? 0);
      final prevIncome = (prevSummary['totalIncome'] as double? ?? 0);
      final prevNet = prevIncome - prevExpenses;
      final prevExpCat =
          (prevSummary['expensesByCategory'] as Map<String, double>?) ?? {};
      final prevSorted = prevExpCat.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      final expDiff = totalExpenses - prevExpenses;
      final expTrend = expDiff > 0
          ? 'increased by ₱${expDiff.abs().toStringAsFixed(2)}'
          : 'decreased by ₱${expDiff.abs().toStringAsFixed(2)}';
      final savDiff = netSavings - prevNet;
      final savTrend = savDiff >= 0
          ? 'improved by ₱${savDiff.abs().toStringAsFixed(2)}'
          : 'dropped by ₱${savDiff.abs().toStringAsFixed(2)}';

      prevContext = '''

COMPARISON WITH LAST MONTH (${_monthName(prevMonth.month)} ${prevMonth.year}):
Previous Total Expenses: ₱${prevExpenses.toStringAsFixed(2)}
Previous Net Savings: ₱${prevNet.toStringAsFixed(2)}
Top Expense Category Last Month: ${prevSorted.isNotEmpty ? prevSorted.first.key : 'None'}
Expense Change: Your total spending has $expTrend compared to last month.
Savings Change: Your net savings have $savTrend compared to last month.
''';
    }

    return '''You are a professional and friendly personal financial advisor. Your job is to help the user clearly understand their finances and take smart steps to save more money and manage their spending better. Always speak in simple, easy-to-understand English — avoid complex financial jargon. Be warm, direct, and encouraging, like a trusted advisor who genuinely wants the user to succeed.

FINANCIAL DATA FOR ${_monthName(month.month).toUpperCase()} ${month.year}:
Current Balance: ₱${balance.toStringAsFixed(2)}
Total Income: ₱${totalIncome.toStringAsFixed(2)}
Total Expenses: ₱${totalExpenses.toStringAsFixed(2)}
Net Savings This Month: ₱${netSavings.toStringAsFixed(2)}
Current Savings Rate: $savingsRate% of income saved
Recommended Savings Target: $recommendedSavingsPct% of income = ₱${recommendedSavingsAmt.toStringAsFixed(2)}
Additional Savings Needed to Hit Target: ₱${additionalSavingsNeeded.toStringAsFixed(2)}
Highest Spending Category: $topCategory
$prevContext
EXPENSE BREAKDOWN:
$expBreakdown

INCOME SOURCES:
$incBreakdown

RESPONSE FORMATTING RULES — FOLLOW THESE EXACTLY:

Structure every response using these exact section headers written in ALL CAPS followed by a colon on their own line:

OVERVIEW:
WHERE YOUR MONEY WENT:
YOUR SAVINGS GOAL:
WHAT YOU SHOULD DO NEXT MONTH:
FINAL THOUGHTS:

Under each section, write in short, clear paragraphs or use numbered steps (1. 2. 3.). Keep all sentences short and easy to follow.

When giving savings advice, always include:
The exact ₱ amount the user should aim to save next month.
The percentage that amount represents of their income.
Which specific spending category they should cut back on and by how much.

Use plain numbers and percentages. Example: "Aim to save at least ₱2,500 next month, which is 20% of your income."

Do NOT use markdown symbols such as **, *, #, or dashes as decoration. Do NOT use bullet dashes. Only use numbered lists (1. 2. 3.) when listing steps or items.

Keep the tone professional yet easy to understand — honest, caring, and solution-focused.

End every response with exactly one short motivating sentence on its own line.''';
  }

  Future<String> generateAnalysis(
    Map<String, dynamic> summary, {
    Map<String, dynamic>? prevSummary,
  }) async {
    final systemPrompt = buildSystemPrompt(summary, prevSummary: prevSummary);
    final messages = [
      Message(role: 'system', content: systemPrompt),
      Message(
        role: 'user',
        content:
            'Please give me a complete financial report for this month. '
            'Tell me where I spent the most money and whether I should be concerned. '
            'Tell me exactly how much I need to save next month in ₱ (Philippine Peso) and as a percentage of my income '
            'to reach a healthy savings level. Give me 3 to 5 clear, specific steps I can take next month '
            'to reduce my spending and grow my savings. Keep everything simple and easy to understand.',
      ),
    ];
    return await _api.sendMessage(messages);
  }

  Future<String> sendQuestion(
    String question,
    List<Message> history,
    Map<String, dynamic> summary, {
    Map<String, dynamic>? prevSummary,
  }) async {
    final systemPrompt = buildSystemPrompt(summary, prevSummary: prevSummary);
    final messages = [
      Message(role: 'system', content: systemPrompt),
      ...history.skip(history.length > 8 ? history.length - 8 : 0),
      Message(role: 'user', content: question),
    ];
    return await _api.sendMessage(messages);
  }

  String _monthName(int month) {
    const months = [
      '',
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    return months[month];
  }
}