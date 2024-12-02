import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    final String userId = user?.uid ?? '';
    final String displayName = user?.displayName ?? 'User';

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text('Hi, $displayName!',
            style: const TextStyle(color: Colors.white)),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('transactions')
            .orderBy('date', descending: true)
            .limit(5)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text(
                'No transactions found. Add some to see insights.',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            );
          }

          final transactions = snapshot.data!.docs;
          double totalIncome = 0;
          double totalExpenses = 0;
          final Map<String, double> categoryData = {};

          for (var transaction in transactions) {
            final data = transaction.data() as Map<String, dynamic>;
            final double amount = data['amount']?.toDouble() ?? 0.0;
            final String type = data['type'] ?? '';
            final String category = data['category'] ?? 'Others';

            if (type == 'income') {
              totalIncome += amount;
            } else if (type == 'expense') {
              totalExpenses += amount;
            }

            categoryData[category] = (categoryData[category] ?? 0) + amount;
          }

          double netBalance = totalIncome - totalExpenses;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetricsRow(totalIncome, totalExpenses, netBalance),
                  const SizedBox(height: 20),
                  _buildRevenueFlowChart(totalIncome, totalExpenses),
                  const SizedBox(height: 20),
                  _buildMonthlyExpensesChartWithLegend(categoryData),
                  const SizedBox(height: 20),
                  _buildTransactionHistory(transactions),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsRow(
      double totalIncome, double totalExpenses, double netBalance) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetricCard('Total Income', '\$${totalIncome.toStringAsFixed(2)}',
            Colors.green),
        const SizedBox(width: 10),
        _buildMetricCard('Total Expenses',
            '\$${totalExpenses.toStringAsFixed(2)}', Colors.red),
        const SizedBox(width: 10),
        _buildMetricCard(
            'Net Balance', '\$${netBalance.toStringAsFixed(2)}', Colors.blue),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Expanded(
      child: GestureDetector(
        onTap: () {},
        child: Card(
          color: Colors.grey[900],
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    value,
                    style: TextStyle(
                      color: color,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRevenueFlowChart(double totalIncome, double totalExpenses) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Revenue Flow',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 280,
              child: Stack(
                children: [
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 30.0), // Reduce right padding
                    child: BarChart(
                      BarChartData(
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(color: Colors.white38),
                        ),
                        gridData: FlGridData(
                          drawVerticalLine: false,
                          getDrawingHorizontalLine: (value) =>
                              const FlLine(color: Colors.white24, strokeWidth: 1),
                          horizontalInterval:
                              totalIncome / 4, // Adjusted for proper spacing
                        ),
                        titlesData: FlTitlesData(
                          leftTitles: const AxisTitles(
                            sideTitles: SideTitles(
                                showTitles: false), // No left-side labels
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true, // Show numbers on the right
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                // Prevent duplicate topmost label
                                if (value >= totalIncome / 1000) {
                                  return const SizedBox.shrink();
                                }
                                return Text(
                                  '${value.toInt()}k',
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                );
                              },
                            ),
                            axisNameWidget: const Padding(
                              padding: EdgeInsets.only(left: 8.0),
                              child: Text(
                                'Amount (in thousands)',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            axisNameSize: 32,
                          ),
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              reservedSize: 40,
                              getTitlesWidget: (value, meta) {
                                switch (value.toInt()) {
                                  case 0:
                                    return const Text(
                                      'Income',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    );
                                  case 1:
                                    return const Text(
                                      'Expenses',
                                      style: TextStyle(
                                          color: Colors.white70, fontSize: 12),
                                    );
                                  default:
                                    return const SizedBox.shrink();
                                }
                              },
                            ),
                            axisNameWidget: const Padding(
                              padding: EdgeInsets.only(top: 16.0),
                              child: Text(
                                'Category',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14),
                              ),
                            ),
                            axisNameSize: 32,
                          ),
                          topTitles: const AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: false, // Remove top labels
                            ),
                          ),
                        ),
                        barGroups: [
                          BarChartGroupData(
                            x: 0,
                            barRods: [
                              BarChartRodData(
                                toY: totalIncome / 1000,
                                color: Colors.green,
                                width: 20,
                              ),
                            ],
                          ),
                          BarChartGroupData(
                            x: 1,
                            barRods: [
                              BarChartRodData(
                                toY: totalExpenses / 1000,
                                color: Colors.red,
                                width: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  List<PieChartSectionData> _buildDoughnutChartSections(Map<String, double> categoryData) {
    const List<Color> colors = [
      Colors.purple,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.red,
    ];

    categoryData.values.reduce((a, b) => a + b);

    int index = 0;
    return categoryData.entries.map((entry) {
      final color = colors[index % colors.length];
      index++;

      return PieChartSectionData(
        color: color,
        value: entry.value,
        radius: 70, // The radius of the doughnut sections
        title: '', // No title inside the chart
      );
    }).toList();
  }
  Widget _buildMonthlyExpensesChartWithLegend(Map<String, double> categoryData) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Monthly Expenses',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: SizedBox(
                    height: 250,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 4,
                        centerSpaceRadius: 40,
                        sections: _buildDoughnutChartSections(categoryData),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20), // Add space between chart and legend
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categoryData.entries.map((entry) {
                    final colorIndex = categoryData.keys.toList().indexOf(entry.key) % 5;
                    final colors = [
                      Colors.purple,
                      Colors.blue,
                      Colors.green,
                      Colors.orange,
                      Colors.red,
                    ];

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6.0), // Add spacing between items
                      child: Row(
                        children: [
                          Container(
                            width: 10, // Smaller legend color box
                            height: 10,
                            color: colors[colorIndex],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${entry.key}: ${((entry.value / categoryData.values.reduce((a, b) => a + b)) * 100).toStringAsFixed(1)}%',
                            style: const TextStyle(color: Colors.white, fontSize: 10), // Smaller font size
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTransactionHistory(List<QueryDocumentSnapshot> transactions) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final transaction =
                    transactions[index].data() as Map<String, dynamic>;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        transaction['category'] ?? 'Unknown',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        '\$${transaction['amount'] ?? 0.0}',
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
