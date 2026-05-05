import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_try/final_project/ai_model/message.dart';
import 'package:flutter_try/final_project/services/financial_ai_service.dart';

const List<_QuickPrompt> _kQuickPrompts = [
  _QuickPrompt(
    icon: Icons.bar_chart_rounded,
    label: 'Buod ng Buwan',
    message: 'Bigyan mo ako ng kumpletong buod at pagsusuri ng aking mga gastos ngayong buwan.',
  ),
  _QuickPrompt(
    icon: Icons.savings_rounded,
    label: 'Paano Makatipid',
    message: 'Saan ako maaaring mag-tipid? Bigyan mo ako ng mga praktikal na paraan para mapataas ang aking ipon.',
  ),
  _QuickPrompt(
    icon: Icons.warning_amber_rounded,
    label: 'Labis na Gastos?',
    message: 'Nagagastos ba ako nang labis sa anumang kategorya? Ano ang dapat kong bantayan?',
  ),
  _QuickPrompt(
    icon: Icons.calendar_month_rounded,
    label: 'Plano sa Susunod',
    message: 'Batay sa aking gastos ngayong buwan, paano ko dapat ayusin ang aking badyet sa susunod na buwan?',
  ),
];

class _QuickPrompt {
  final IconData icon;
  final String label;
  final String message;
  const _QuickPrompt({
    required this.icon,
    required this.label,
    required this.message,
  });
}

const List<Color> _kCategoryColors = [
  Color(0xFFEAD25B),
  Color(0xFFE07B5A),
  Color(0xFF5A9BE0),
  Color(0xFF6CC97A),
  Color(0xFFB05AE0),
  Color(0xFF5ADCE0),
  Color(0xFFE05A9B),
  Color(0xFFE0A85A),
];

class FinancialAIPage extends StatefulWidget {
  const FinancialAIPage({super.key});

  @override
  State<FinancialAIPage> createState() => _FinancialAIPageState();
}

class _FinancialAIPageState extends State<FinancialAIPage> {
  final FinancialAIService _aiService = FinancialAIService();
  final TextEditingController _inputController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  final List<Message> _history = [];

  Map<String, dynamic> _summary = {};
  Map<String, dynamic>? _prevSummary;

  bool _isLoadingData = true;
  bool _isAnalyzing = false;
  bool _isSending = false;
  bool _analysisGenerated = false;

  int _touchedPieIndex = -1;

  @override
  void initState() {
    super.initState();
    _loadAndAnalyze();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadAndAnalyze() async {
    if (!mounted) return;
    setState(() {
      _isLoadingData = true;
      _analysisGenerated = false;
      _history.clear();
      _touchedPieIndex = -1;
    });

    try {
      final now = DateTime.now();
      final prevMonth = DateTime(now.year, now.month - 1);

      final results = await Future.wait([
        _aiService.fetchFinancialSummary(month: now),
        _aiService.fetchFinancialSummary(month: prevMonth),
      ]);

      if (!mounted) return;

      _summary = results[0];
      _prevSummary =
          ((results[1]['totalIncome'] as double? ?? 0) > 0 ||
                  (results[1]['totalExpenses'] as double? ?? 0) > 0)
              ? results[1]
              : null;

      setState(() => _isLoadingData = false);
      await _runAutoAnalysis();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingData = false);
      _addAssistantMessage(
        'Hindi ma-load ang iyong datos sa pananalapi. Pakitingnan ang iyong koneksyon at subukang muli.',
      );
    }
  }

  Future<void> _runAutoAnalysis() async {
    if (!mounted) return;
    setState(() => _isAnalyzing = true);
    try {
      final reply = await _aiService.generateAnalysis(
        _summary,
        prevSummary: _prevSummary,
      );
      if (!mounted) return;
      _addAssistantMessage(reply);
      setState(() => _analysisGenerated = true);
    } catch (e) {
      if (!mounted) return;
      _addAssistantMessage(
        'Hindi nagawa ang pagsusuri: ${e.toString().replaceAll("Exception: ", "")}',
      );
    }
    if (!mounted) return;
    setState(() => _isAnalyzing = false);
    _scrollToBottom();
  }

  Future<void> _sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    _inputController.clear();
    _addUserMessage(trimmed);
    if (!mounted) return;
    setState(() => _isSending = true);
    _scrollToBottom();

    try {
      final reply = await _aiService.sendQuestion(
        trimmed,
        _history,
        _summary,
        prevSummary: _prevSummary,
      );
      if (!mounted) return;
      _addAssistantMessage(reply);
    } catch (e) {
      if (!mounted) return;
      _addAssistantMessage(
        'Pagkakamali: ${e.toString().replaceAll("Exception: ", "")}',
      );
    }

    if (!mounted) return;
    setState(() => _isSending = false);
    _scrollToBottom();
  }

  void _addUserMessage(String content) {
    if (!mounted) return;
    setState(() => _history.add(Message(role: 'user', content: content)));
  }

  void _addAssistantMessage(String content) {
    if (!mounted) return;
    setState(
        () => _history.add(Message(role: 'assistant', content: _cleanAiText(content))));
  }

  String _cleanAiText(String raw) {
    String text = raw;
    text = text.replaceAllMapped(
        RegExp(r'\*\*(.+?)\*\*', dotAll: true), (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(
        RegExp(r'__(.+?)__', dotAll: true), (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(
        RegExp(r'(?<!\*)\*(?!\*)(.+?)(?<!\*)\*(?!\*)'),
        (m) => m.group(1) ?? '');
    text = text.replaceAllMapped(
        RegExp(r'(?<!_)_(?!_)(.+?)(?<!_)_(?!_)'), (m) => m.group(1) ?? '');
    text = text.replaceAll(RegExp(r'^#{1,6}\s+', multiLine: true), '');
    text = text.replaceAll(
        RegExp(r'^[\s]*[━─—=\-\*]{3,}[\s]*$', multiLine: true), '');
    text = _convertSymbolBullets(text);
    text = _convertDashBullets(text);
    text = text.replaceAll('|', ' ');
    text = text.replaceAll(RegExp(r'`+'), '');
    text = text.replaceAll(RegExp(r'[▲▼→←↑↓➔➝]'), '');
    text = text.replaceAllMapped(
        RegExp(r'([^\n])\n(\d+\. )'), (m) => '${m.group(1)}\n\n${m.group(2)}');
    text = text.replaceAll(RegExp(r'\n{3,}'), '\n\n');
    text = text.split('\n').map((l) => l.trimRight()).join('\n');
    text = text.replaceAll(RegExp(r'  +'), ' ');
    return text.trim();
  }

  String _convertSymbolBullets(String text) {
    final lines = text.split('\n');
    final out = <String>[];
    int counter = 1;
    bool inList = false;
    for (final line in lines) {
      final m = RegExp(r'^\s*[•●◆▶✓✔➤➜]\s+(.+)').firstMatch(line);
      if (m != null) {
        inList = true;
        out.add('$counter. ${m.group(1)!.trim()}');
        counter++;
      } else {
        if (inList && line.trim().isEmpty) {
          counter = 1;
          inList = false;
        }
        out.add(line);
      }
    }
    return out.join('\n');
  }

  String _convertDashBullets(String text) {
    final lines = text.split('\n');
    final out = <String>[];
    int counter = 1;
    bool inList = false;
    for (final line in lines) {
      final m = RegExp(r'^\s*[-\*]\s+(.+)').firstMatch(line);
      if (m != null) {
        inList = true;
        out.add('$counter. ${m.group(1)!.trim()}');
        counter++;
      } else {
        if (inList && line.trim().isEmpty) {
          counter = 1;
          inList = false;
        }
        out.add(line);
      }
    }
    return out.join('\n');
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOut,
        );
      }
    });
  }


  Widget _logoAvatar(double size) {
    return Image.asset(
      'assets2/images/aiLogo_final.png',
      width: size,
      height: size,
      fit: BoxFit.contain,
    );
  }

  @override
  Widget build(BuildContext context) {
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
            children: [
              _buildHeader(),
              if (_isLoadingData) _buildLoadingState() else _buildChat(),
              if (!_isLoadingData) _buildInputArea(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          _logoAvatar(48),
          const SizedBox(width: 12),
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Peso Pilot',
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87)),
              Text('Gabay sa iyong Pera',
                  style: TextStyle(fontSize: 12, color: Colors.black45)),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.refresh_rounded, color: Colors.black45),
            tooltip: 'I-refresh ang pagsusuri',
            onPressed: _isLoadingData || _isAnalyzing ? null : _loadAndAnalyze,
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingState() {
    return Expanded(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(color: Color(0xFFEAD25B)),
            const SizedBox(height: 16),
            Text('Sinusuri ang iyong pananalapi…',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _buildChat() {
    return Expanded(
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          if (_summary.isNotEmpty) _buildChartCard(),
          if (_history.where((m) => m.role == 'user').isEmpty && _analysisGenerated)
            _buildQuickPrompts(),
          ..._history.map((msg) => _buildBubble(msg)),
          if (_isAnalyzing || _isSending) _buildTypingIndicator(),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildChartCard() {
    final expCat = (_summary['expensesByCategory'] as Map<String, double>?) ?? {};
    final totalExpenses = (_summary['totalExpenses'] as double? ?? 0);
    final totalIncome = (_summary['totalIncome'] as double? ?? 0);
    final balance = (_summary['balance'] as double? ?? 0);

    final sortedExp = expCat.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final now = _summary['month'] as DateTime? ?? DateTime.now();
    const months = [
      '', 'Enero', 'Pebrero', 'Marso', 'Abril', 'Mayo', 'Hunyo',
      'Hulyo', 'Agosto', 'Setyembre', 'Oktubre', 'Nobyembre', 'Disyembre',
    ];
    final monthLabel = '${months[now.month]} ${now.year}';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withOpacity(0.07),
              blurRadius: 14,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
              color: Color(0xFFEAD25B),
              borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
            ),
            child: Row(
              children: [
                const Icon(Icons.insights_rounded, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Ulat sa Pananalapi — $monthLabel',
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            child: Row(
              children: [
                _summaryTile('Kita', totalIncome, const Color(0xFF4CAF50)),
                const SizedBox(width: 8),
                _summaryTile('Gastos', totalExpenses, const Color(0xFFE07B5A)),
                const SizedBox(width: 8),
                _summaryTile('Balanse', balance, const Color(0xFF5A9BE0)),
              ],
            ),
          ),
          if (sortedExp.isNotEmpty) ...[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('Breakdown ng Gastos',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey.shade700)),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 190,
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 3,
                        centerSpaceRadius: 46,
                        startDegreeOffset: -90,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, pieTouchResponse) {
                            setState(() {
                              if (!event.isInterestedForInteractions ||
                                  pieTouchResponse == null ||
                                  pieTouchResponse.touchedSection == null) {
                                _touchedPieIndex = -1;
                                return;
                              }
                              _touchedPieIndex =
                                  pieTouchResponse.touchedSection!.touchedSectionIndex;
                            });
                          },
                        ),
                        sections: List.generate(sortedExp.length, (i) {
                          final touched = i == _touchedPieIndex;
                          final color = _kCategoryColors[i % _kCategoryColors.length];
                          final pct = totalExpenses > 0
                              ? sortedExp[i].value / totalExpenses
                              : 0.0;
                          return PieChartSectionData(
                            value: sortedExp[i].value,
                            color: color,
                            radius: touched ? 40 : 28,
                            showTitle: touched,
                            title: touched ? '${(pct * 100).toStringAsFixed(1)}%' : '',
                            titleStyle: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          );
                        }),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 6,
                    child: Padding(
                      padding: const EdgeInsets.only(right: 14),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: List.generate(
                          sortedExp.length > 6 ? 6 : sortedExp.length,
                          (i) {
                            final color = _kCategoryColors[i % _kCategoryColors.length];
                            final pct = totalExpenses > 0
                                ? (sortedExp[i].value / totalExpenses * 100)
                                    .toStringAsFixed(1)
                                : '0.0';
                            return Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: Row(
                                children: [
                                  Container(
                                      width: 10,
                                      height: 10,
                                      decoration: BoxDecoration(
                                          color: color, shape: BoxShape.circle)),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(sortedExp[i].key,
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.black87),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  Text('$pct%',
                                      style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.grey.shade500,
                                          fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text('Gastos sa bawat Kategorya',
                  style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                      color: Colors.grey.shade700)),
            ),
            const SizedBox(height: 10),
            Padding(
              padding: const EdgeInsets.only(left: 14, right: 14, bottom: 16),
              child: Column(
                children: List.generate(
                  sortedExp.length > 5 ? 5 : sortedExp.length,
                  (i) {
                    final color = _kCategoryColors[i % _kCategoryColors.length];
                    final ratio =
                        totalExpenses > 0 ? sortedExp[i].value / totalExpenses : 0.0;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 9),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 92,
                            child: Text(sortedExp[i].key,
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.black87),
                                overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: LinearProgressIndicator(
                                value: ratio,
                                backgroundColor: Colors.grey.shade200,
                                color: color,
                                minHeight: 10,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('₱${_compact(sortedExp[i].value)}',
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade700)),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ] else
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Wala pang naitala na gastos ngayong buwan.',
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryTile(String label, double amount, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
        decoration: BoxDecoration(
          color: color.withOpacity(0.09),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: color, fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text('₱${_compact(amount)}',
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87),
                overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }

  String _compact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return value.toStringAsFixed(2);
  }

  Widget _buildQuickPrompts() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Text('Mga mabilis na tanong:',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w600)),
          ),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _kQuickPrompts.map((qp) {
              return GestureDetector(
                onTap: () => _sendMessage(qp.message),
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: const Color(0xFFEAD25B).withOpacity(0.6)),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(qp.icon, size: 15, color: const Color(0xFFEAD25B)),
                      const SizedBox(width: 6),
                      Text(qp.label,
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(Message msg) {
    final isUser = msg.role == 'user';
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _logoAvatar(36),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFEAD25B) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(16),
                  topRight: const Radius.circular(16),
                  bottomLeft: isUser
                      ? const Radius.circular(16)
                      : const Radius.circular(4),
                  bottomRight: isUser
                      ? const Radius.circular(4)
                      : const Radius.circular(16),
                ),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: isUser
                  ? Text(msg.content,
                      style: const TextStyle(
                          fontSize: 14, height: 1.55, color: Colors.black87))
                  : _buildFormattedText(msg.content),
            ),
          ),
          if (isUser) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildFormattedText(String content) {
    final paragraphs = content.split('\n\n');
    final widgets = <Widget>[];

    for (int p = 0; p < paragraphs.length; p++) {
      final para = paragraphs[p].trim();
      if (para.isEmpty) continue;

      final lines = para.split('\n');
      final isNumberedBlock = lines
          .where((l) => l.trim().isNotEmpty)
          .every((l) => RegExp(r'^\d+\.').hasMatch(l.trim()));

      if (isNumberedBlock && lines.length > 1) {
        for (int li = 0; li < lines.length; li++) {
          final line = lines[li].trim();
          if (line.isEmpty) continue;
          widgets.add(Padding(
            padding: EdgeInsets.only(bottom: li < lines.length - 1 ? 6 : 0),
            child: Text(line,
                style: const TextStyle(
                    fontSize: 14, height: 1.55, color: Colors.black87)),
          ));
        }
        if (p < paragraphs.length - 1) widgets.add(const SizedBox(height: 10));
      } else {
        widgets.add(Padding(
          padding: EdgeInsets.only(bottom: p < paragraphs.length - 1 ? 10 : 0),
          child: Text(para,
              style: const TextStyle(
                  fontSize: 14, height: 1.55, color: Colors.black87)),
        ));
      }
    }

    return Column(
        crossAxisAlignment: CrossAxisAlignment.start, children: widgets);
  }

  Widget _buildTypingIndicator() {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          _logoAvatar(36),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(4),
                bottomRight: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 8,
                    offset: const Offset(0, 2))
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(
                  3, (i) => _AnimatedDot(delay: Duration(milliseconds: i * 200))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(top: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: const Color(0xFFEAD25B).withOpacity(0.5)),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 8,
                      offset: const Offset(0, 2))
                ],
              ),
              child: TextField(
                controller: _inputController,
                enabled: !_isLoadingData && !_isAnalyzing,
                maxLines: 3,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: _sendMessage,
                decoration: InputDecoration(
                  hintText: 'Tanungin ang iyong financial advisor…',
                  hintStyle:
                      TextStyle(color: Colors.grey.shade400, fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: _isSending || _isLoadingData || _isAnalyzing
                ? null
                : () => _sendMessage(_inputController.text),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: _isSending || _isLoadingData || _isAnalyzing
                    ? Colors.grey.shade300
                    : const Color(0xFFEAD25B),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded,
                  color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedDot extends StatefulWidget {
  final Duration delay;
  const _AnimatedDot({required this.delay});

  @override
  State<_AnimatedDot> createState() => _AnimatedDotState();
}

class _AnimatedDotState extends State<_AnimatedDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        duration: const Duration(milliseconds: 600), vsync: this);
    Future.delayed(
        widget.delay, () { if (mounted) _ctrl.repeat(reverse: true); });
    _anim = Tween<double>(begin: 0, end: -6).animate(
        CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Transform.translate(
        offset: Offset(0, _anim.value),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 3),
          width: 7,
          height: 7,
          decoration:
              BoxDecoration(color: Colors.grey.shade400, shape: BoxShape.circle),
        ),
      ),
    );
  }
}