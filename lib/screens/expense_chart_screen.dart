// Импорт основных виджетов Flutter
import 'dart:math' as math;
import 'package:flutter/material.dart';
// Импорт для работы с провайдерами состояния
import 'package:provider/provider.dart';
// Импорт пакета для графиков
import 'package:fl_chart/fl_chart.dart';
// Импорт провайдера чата
import '../providers/chat_provider.dart';
// Импорт модели сообщения
import '../models/message.dart';
// Импорт для форматирования дат
import 'package:intl/intl.dart';

/// Экран графика расхода по дням
class ExpenseChartScreen extends StatefulWidget {
  const ExpenseChartScreen({super.key});

  @override
  State<ExpenseChartScreen> createState() => _ExpenseChartScreenState();
}

class _ExpenseChartScreenState extends State<ExpenseChartScreen> {
  DateTime _dateFrom = DateTime.now().subtract(const Duration(days: 10));
  DateTime _dateTo = DateTime.now();
  int? _touchedBarIndex;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262626),
        foregroundColor: Colors.white,
        title: const Text(
          'Расход по дням',
          style: TextStyle(fontSize: 16),
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          final isVsetgpt =
              chatProvider.baseUrl?.contains('vsetgpt.ru') == true;
          final dailyData = _aggregateByDay(
            chatProvider.messages,
            _dateFrom,
            _dateTo,
          );

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildDateRangeSelector(context),
              const SizedBox(height: 24),
              if (dailyData.isEmpty)
                _buildEmptyState()
              else
                _buildChart(context, dailyData, isVsetgpt),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDateRangeSelector(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Период',
            style: TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildDateField(
                  label: 'С',
                  date: _dateFrom,
                  onTap: () => _pickDate(context, isFrom: true),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildDateField(
                  label: 'По',
                  date: _dateTo,
                  onTap: () => _pickDate(context, isFrom: false),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateField({
    required String label,
    required DateTime date,
    required VoidCallback onTap,
  }) {
    final fmt = DateFormat('dd.MM.yyyy');
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF262626),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(color: Colors.white54, fontSize: 11),
            ),
            Text(
              fmt.format(date),
              style: const TextStyle(color: Colors.white, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, {required bool isFrom}) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _dateFrom : _dateTo,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF1A73E8),
              surface: Color(0xFF333333),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && mounted) {
      setState(() {
        if (isFrom) {
          _dateFrom = picked;
          if (_dateFrom.isAfter(_dateTo)) _dateTo = _dateFrom;
        } else {
          _dateTo = picked;
          if (_dateTo.isBefore(_dateFrom)) _dateFrom = _dateTo;
        }
      });
    }
  }

  // Агрегация по дням: дата -> {cost, tokens, count}
  Map<DateTime, Map<String, dynamic>> _aggregateByDay(
    List<ChatMessage> messages,
    DateTime from,
    DateTime to,
  ) {
    final fromDate = DateTime(from.year, from.month, from.day);
    final toDate = DateTime(to.year, to.month, to.day);
    final map = <DateTime, Map<String, dynamic>>{};

    for (final msg in messages) {
      if (msg.isUser || msg.modelId == null) continue;
      final day =
          DateTime(msg.timestamp.year, msg.timestamp.month, msg.timestamp.day);
      if (day.isBefore(fromDate) || day.isAfter(toDate)) continue;

      map.putIfAbsent(day, () => {'cost': 0.0, 'tokens': 0, 'count': 0});
      map[day]!['cost'] = (map[day]!['cost'] as double) + (msg.cost ?? 0);
      map[day]!['tokens'] = (map[day]!['tokens'] as int) + (msg.tokens ?? 0);
      map[day]!['count'] = (map[day]!['count'] as int) + 1;
    }

    // Заполняем все дни в диапазоне (даже с нулевым расходом)
    for (var d = fromDate.add(const Duration(days: 0));
        !d.isAfter(toDate);
        d = d.add(const Duration(days: 1))) {
      map.putIfAbsent(d, () => {'cost': 0.0, 'tokens': 0, 'count': 0});
    }

    final sorted = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return Map.fromEntries(sorted);
  }

  Widget _buildEmptyState() {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(Icons.bar_chart, size: 48, color: Colors.white24),
          const SizedBox(height: 16),
          const Text(
            'Нет данных за выбранный период',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 8),
          const Text(
            'Отправьте сообщения в чате,\nчтобы увидеть расход по дням',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildChart(
    BuildContext context,
    Map<DateTime, Map<String, dynamic>> dailyData,
    bool isVsetgpt,
  ) {
    final entries = dailyData.entries.toList();
    final maxCost = entries.fold<double>(
      0,
      (m, e) => (e.value['cost'] as double) > m ? e.value['cost'] as double : m,
    );
    final maxY = maxCost > 0 ? (maxCost * 1.2).ceilToDouble() : 10.0;
    final fmt = DateFormat('dd.MM');

    return Container(
      height: 320,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxY,
          minY: 0,
          groupsSpace: 8,
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => const Color(0xFF424242),
              tooltipBorder: const BorderSide(color: Colors.white24),
              tooltipRoundedRadius: 8,
              tooltipPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final day = entries[group.x.toInt()].key;
                final cost = rod.toY;
                final data = entries[group.x.toInt()].value;
                final tokens = data['tokens'] as int;
                final count = data['count'] as int;
                final costStr = isVsetgpt
                    ? '${cost.toStringAsFixed(4)}₽'
                    : '\$${cost.toStringAsFixed(4)}';
                return BarTooltipItem(
                  '${fmt.format(day)}\n'
                  'Стоимость: $costStr\n'
                  'Токенов: $tokens\n'
                  'Ответов: $count',
                  const TextStyle(color: Colors.white, fontSize: 12),
                );
              },
            ),
            touchCallback: (event, response) {
              setState(() {
                if (response?.spot != null) {
                  _touchedBarIndex = response!.spot!.touchedBarGroupIndex;
                } else {
                  _touchedBarIndex = null;
                }
              });
            },
          ),
          titlesData: FlTitlesData(
            show: true,
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final idx = value.toInt();
                  if (idx >= 0 && idx < entries.length) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Transform.rotate(
                        angle: -math.pi / 2.5,
                        alignment: Alignment.topCenter,
                        child: Text(
                          fmt.format(entries[idx].key),
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    );
                  }
                  return const SizedBox();
                },
                reservedSize: 42,
                interval: 1,
              ),
            ),
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final str = value >= 1
                      ? value.toStringAsFixed(0)
                      : value.toStringAsFixed(4);
                  return Transform.rotate(
                    angle: -math.pi / 4,
                    alignment: Alignment.centerRight,
                    child: Text(
                      isVsetgpt ? '$str₽' : '\$$str',
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 10,
                      ),
                    ),
                  );
                },
                reservedSize: 42,
                interval: maxY > 0 ? maxY / 5 : 1,
              ),
            ),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          ),
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxY > 0 ? maxY / 5 : 1,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.white.withOpacity(0.3),
              strokeWidth: 0.5,
            ),
          ),
          borderData: FlBorderData(show: false),
          barGroups: entries.asMap().entries.map((e) {
            final idx = e.key;
            final cost = (e.value.value['cost'] as double);
            final isTouched = _touchedBarIndex == idx;
            return BarChartGroupData(
              x: idx,
              barRods: [
                BarChartRodData(
                  toY: cost,
                  width: 18,
                  color: isTouched
                      ? const Color(0xFF1A73E8)
                      : const Color(0xFF1A73E8).withOpacity(0.7),
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(4)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    fromY: 0,
                    toY: maxY,
                    color: Colors.white.withOpacity(0.05),
                  ),
                ),
              ],
              showingTooltipIndicators: isTouched ? [0] : [],
            );
          }).toList(),
        ),
        duration: const Duration(milliseconds: 200),
      ),
    );
  }
}
