import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../models/app_models.dart';
import '../../providers/transaction_provider.dart';
import '../utils/app_theme.dart';

class FinancialOverviewWidget extends StatelessWidget {
  const FinancialOverviewWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<TransactionProvider>(
      builder: (context, transactionProvider, child) {
        if (transactionProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        return SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFinancialSummary(transactionProvider),
              const SizedBox(height: 20),
              _buildChartSection(transactionProvider),
              const SizedBox(height: 20),
              _buildRecentTransactions(transactionProvider),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFinancialSummary(TransactionProvider provider) {
    final currencyFormat = NumberFormat.currency(symbol: '₦');
    final totalCredits = provider.getTotalCredits();
    final totalDebits = provider.getTotalDebits();
    final balance = provider.getTotalFunds();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Financial Summary',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Balance',
                  currencyFormat.format(balance),
                  Icons.account_balance,
                  Colors.white,
                  isMain: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: [
              Expanded(
                child: _buildSummaryCard(
                  'Total Income',
                  currencyFormat.format(totalCredits),
                  Icons.trending_up,
                  Colors.green.shade300,
                ),
              ),

              const SizedBox(width: 16),

              Expanded(
                child: _buildSummaryCard(
                  'Total Expenses',
                  currencyFormat.format(totalDebits),
                  Icons.trending_down,
                  Colors.red.shade300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(
      String title,
      String value,
      IconData icon,
      Color textColor, {
        bool isMain = false,
      }) {
    return Container(
      padding: EdgeInsets.all(isMain ? 20 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: textColor,
                size: isMain ? 28 : 24,
              ),
              const Spacer(),
            ],
          ),

          SizedBox(height: isMain ? 12 : 8),

          Text(
            title,
            style: TextStyle(
              fontSize: isMain ? 16 : 14,
              color: textColor.withValues(alpha: 0.8),
            ),
          ),

          const SizedBox(height: 4),

          Text(
            value,
            style: TextStyle(
              fontSize: isMain ? 24 : 18,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(TransactionProvider provider) {
    final categoryStats = provider.getCategoryStatistics();

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Income by Category',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 20),

          if (categoryStats.isEmpty)
            const Center(
              child: Text(
                'No transaction data available',
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: _buildPieChartSections(categoryStats),
                  centerSpaceRadius: 50,
                  sectionsSpace: 4,
                  pieTouchData: PieTouchData(
                    touchCallback: (FlTouchEvent event, pieTouchResponse) {
                      // Handle touch if desired
                    },
                  ),
                ),
              ),
            ),

          const SizedBox(height: 20),

          _buildLegend(categoryStats),

          const SizedBox(height: 32),

          const Text(
            'Monthly Growth (Credits)',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 24),

          _buildGrowthChart(provider),
        ],
      ),
    );
  }

  Widget _buildGrowthChart(TransactionProvider provider) {
    final monthlyStats = provider.getMonthlyStatistics();
    if (monthlyStats.isEmpty) return const SizedBox.shrink();

    // Sort months for the chart
    final sortedKeys = monthlyStats.keys.toList()..sort();
    final recentKeys = sortedKeys.length > 6 ? sortedKeys.sublist(sortedKeys.length - 6) : sortedKeys;

    final spots = <FlSpot>[];
    for (int i = 0; i < recentKeys.length; i++) {
      spots.add(FlSpot(i.toDouble(), monthlyStats[recentKeys[i]]!));
    }

    return SizedBox(
      height: 200,
      child: LineChart(
        LineChartData(
          gridData: FlGridData(show: false),
          titlesData: FlTitlesData(
            leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index >= 0 && index < recentKeys.length) {
                    final parts = recentKeys[index].split('-');
                    final month = int.parse(parts[1]);
                    return Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        DateFormat('MMM').format(DateTime(2024, month)),
                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                      ),
                    );
                  }
                  return const Text('');
                },
              ),
            ),
          ),
          borderData: FlBorderData(show: false),
          lineBarsData: [
            LineChartBarData(
              spots: spots,
              isCurved: true,
              color: AppTheme.primaryColor,
              barWidth: 4,
              isStrokeCapRound: true,
              dotData: FlDotData(show: true),
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<PieChartSectionData> _buildPieChartSections(Map<TransactionCategory, double> stats) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      Colors.green,
      Colors.purple,
    ];

    int index = 0;
    return stats.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;

      final total = stats.values.isNotEmpty ? stats.values.reduce((a, b) => a + b) : 0.0;
      final percentage = total > 0 ? (entry.value / total * 100).toStringAsFixed(1) : '0';

      return PieChartSectionData(
        color: color,
        value: entry.value,
        title: '$percentage%',
        radius: 80,
        titleStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }).toList();
  }

  Widget _buildLegend(Map<TransactionCategory, double> stats) {
    final colors = [
      AppTheme.primaryColor,
      AppTheme.secondaryColor,
      AppTheme.accentColor,
      Colors.green,
      Colors.purple,
    ];

    int index = 0;
    return Wrap(
      children: stats.entries.map((entry) {
        final color = colors[index % colors.length];
        index++;

        return Container(
          margin: const EdgeInsets.only(right: 16, bottom: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),

              const SizedBox(width: 8),

              Text(
                entry.key.value,
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildRecentTransactions(TransactionProvider provider) {
    final recentTransactions = provider.getRecentTransactions(limit: 5);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Recent Transactions',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          if (recentTransactions.isEmpty)
            const Center(
              child: Text(
                'No recent transactions',
                style: TextStyle(color: Colors.black54),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentTransactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final transaction = recentTransactions[index];
                return _buildTransactionItem(transaction);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(FinancialTransaction transaction) {
    final currencyFormat = NumberFormat.currency(symbol: '₦');
    final isCredit = transaction.type == TransactionType.credit;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isCredit ? Colors.green.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isCredit ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              isCredit ? Icons.trending_up : Icons.trending_down,
              color: isCredit ? Colors.green : Colors.red,
              size: 20,
            ),
          ),

          const SizedBox(width: 12),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  transaction.category.value,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                Text(
                  DateFormat('MMM dd, yyyy').format(transaction.date),
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
          ),

          Text(
            '${isCredit ? '+' : '-'}${currencyFormat.format(transaction.amount)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isCredit ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }
}