// Импорт основных виджетов Flutter
import 'package:flutter/material.dart';
// Импорт для работы с провайдерами состояния
import 'package:provider/provider.dart';
// Импорт провайдера чата
import '../providers/chat_provider.dart';
// Импорт модели сообщения
import '../models/message.dart';

/// Экран статистики использования токенов по моделям
class StatisticsScreen extends StatelessWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1E1E1E),
      appBar: AppBar(
        backgroundColor: const Color(0xFF262626),
        foregroundColor: Colors.white,
        title: const Text(
          'Статистика использования токенов',
          style: TextStyle(fontSize: 16),
        ),
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, _) {
          final stats = _aggregateStats(chatProvider.messages);
          final totalTokens = stats.values.fold<int>(
            0,
            (sum, s) => sum + (s['tokens'] as int),
          );
          final totalCost = stats.values.fold<double>(
            0.0,
            (sum, s) => sum + (s['cost'] as double),
          );
          final totalResponses = stats.values.fold<int>(
            0,
            (sum, s) => sum + (s['count'] as int),
          );
          final isVsetgpt =
              chatProvider.baseUrl?.contains('vsetgpt.ru') == true;

          if (stats.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pie_chart_outline,
                    size: 64,
                    color: Colors.white24,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Нет данных для отображения',
                    style: TextStyle(
                      color: Colors.white54,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Отправьте сообщения в чате,\nчтобы увидеть статистику',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(
                context,
                totalTokens: totalTokens,
                totalCost: totalCost,
                responseCount: totalResponses,
                balance: chatProvider.balance,
                isVsetgpt: isVsetgpt,
              ),
              const SizedBox(height: 24),
              const Text(
                'Использование по моделям',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...stats.entries.map(
                (e) => _buildModelCard(
                  context,
                  modelId: e.key,
                  count: e.value['count'] as int,
                  tokens: e.value['tokens'] as int,
                  cost: e.value['cost'] as double,
                  isVsetgpt: isVsetgpt,
                  totalTokens: totalTokens,
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Map<String, Map<String, dynamic>> _aggregateStats(List<ChatMessage> messages) {
    final map = <String, Map<String, dynamic>>{};
    for (final msg in messages) {
      if (msg.modelId == null) continue;
      // Учитываем только ответы AI (с токенами)
      if (!msg.isUser) {
        map.putIfAbsent(
          msg.modelId!,
          () => {'count': 0, 'tokens': 0, 'cost': 0.0},
        );
        map[msg.modelId!]!['count'] = map[msg.modelId!]!['count']! + 1;
        if (msg.tokens != null) {
          map[msg.modelId!]!['tokens'] =
              map[msg.modelId!]!['tokens']! + msg.tokens!;
        }
        if (msg.cost != null) {
          map[msg.modelId!]!['cost'] =
              map[msg.modelId!]!['cost']! + msg.cost!;
        }
      }
    }
    // Сортировка по количеству токенов (убывание)
    final entries = map.entries.toList()
      ..sort((a, b) => (b.value['tokens'] as int).compareTo(a.value['tokens'] as int));
    return Map.fromEntries(entries);
  }

  Widget _buildSummaryCard(
    BuildContext context, {
    required int totalTokens,
    required double totalCost,
    required int responseCount,
    required String balance,
    required bool isVsetgpt,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Общая статистика',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                balance,
                style: const TextStyle(
                  color: Color(0xFF33CC33),
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStatRow('Ответов модели', '$responseCount'),
          _buildStatRow('Всего токенов', _formatNumber(totalTokens)),
          _buildStatRow(
            'Общая стоимость',
            isVsetgpt
                ? '${totalCost < 1e-8 ? '0.0' : totalCost.toStringAsFixed(4)}₽'
                : '\$${totalCost < 1e-8 ? '0.0' : totalCost.toStringAsFixed(4)}',
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 13),
          ),
        ],
      ),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}K';
    return n.toString();
  }

  Widget _buildModelCard(
    BuildContext context, {
    required String modelId,
    required int count,
    required int tokens,
    required double cost,
    required bool isVsetgpt,
    required int totalTokens,
  }) {
    final share = totalTokens > 0 ? (tokens / totalTokens * 100) : 0.0;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF333333),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white12, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            modelId,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _buildMiniStat('Ответов', count.toString()),
              ),
              Expanded(
                child: _buildMiniStat('Токенов', _formatNumber(tokens)),
              ),
              Expanded(
                child: _buildMiniStat(
                  'Стоимость',
                  isVsetgpt
                      ? '${cost < 1e-8 ? '0' : cost.toStringAsFixed(4)}₽'
                      : '\$${cost < 1e-8 ? '0' : cost.toStringAsFixed(4)}',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share / 100,
              minHeight: 6,
              backgroundColor: Colors.white12,
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A73E8)),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${share.toStringAsFixed(1)}% от общего числа токенов',
            style: const TextStyle(color: Colors.white54, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white54, fontSize: 11),
        ),
        Text(
          value,
          style: const TextStyle(color: Colors.white, fontSize: 13),
        ),
      ],
    );
  }
}
