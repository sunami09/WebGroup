import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({Key? key}) : super(key: key);

  Future<Map<String, dynamic>> fetchDashboardData() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return {'transactions': [], 'totalIncome': 0.0, 'totalExpenses': 0.0, 'netBalance': 0.0, 'categoryData': {}};
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final savings = (userDoc.data()?['savings'] ?? 0.0) as double;

    final transactionsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('date', descending: true)
        .get();

    final transactions = transactionsSnapshot.docs.map((doc) {
      final data = doc.data();
      data['date'] = (data['date'] as Timestamp).toDate();
      return data;
    }).toList();

    double totalIncome = 0.0;
    double totalExpenses = 0.0;
    Map<String, double> categoryData = {};

    for (var transaction in transactions) {
      final double amount = (transaction['amount'] ?? 0).toDouble();
      final String type = transaction['type'] ?? '';
      final String category = transaction['category'] ?? 'Others';

      if (type.toLowerCase() == 'income') {
        totalIncome += amount;
      } else if (type.toLowerCase() == 'expense') {
        totalExpenses += amount;
        categoryData[category] = (categoryData[category] ?? 0) + amount;
      }
    }

    final netBalance = savings + totalIncome - totalExpenses;

    return {
      'transactions': transactions,
      'totalIncome': totalIncome,
      'totalExpenses': totalExpenses,
      'netBalance': netBalance,
      'categoryData': categoryData,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: FutureBuilder<Map<String, dynamic>>(
        future: fetchDashboardData(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: Colors.white),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading dashboard',
                style: TextStyle(color: Colors.red, fontSize: 18),
              ),
            );
          }

          final data = snapshot.data!;
          final transactions = data['transactions'] as List<Map<String, dynamic>>;
          final totalIncome = data['totalIncome'] as double;
          final totalExpenses = data['totalExpenses'] as double;
          final netBalance = data['netBalance'] as double;
          final categoryData = data['categoryData'] as Map<String, double>;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMetricsRow(totalIncome, totalExpenses, netBalance),
                  const SizedBox(height: 20),
                  _buildTransactionList(transactions),
                  const SizedBox(height: 20),
                  _buildCategoryPieChart(categoryData),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildMetricsRow(double totalIncome, double totalExpenses, double netBalance) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildMetricCard('Total Income', '\$${totalIncome.toStringAsFixed(2)}', Colors.green),
        _buildMetricCard('Total Expenses', '\$${totalExpenses.toStringAsFixed(2)}', Colors.red),
        _buildMetricCard('Net Balance', '\$${netBalance.toStringAsFixed(2)}', Colors.blue),
      ],
    );
  }

  Widget _buildMetricCard(String title, String value, Color color) {
    return Expanded(
      child: Card(
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTransactionList(List<Map<String, dynamic>> transactions) {
    // Limit the transactions to the first 5 items
    final limitedTransactions = transactions.take(5).toList();

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recent Transactions',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: limitedTransactions.length,
              itemBuilder: (context, index) {
                final transaction = limitedTransactions[index];
                final amount = transaction['amount'] ?? 0;
                final category = transaction['category'] ?? 'Unknown';
                final type = transaction['type'] ?? 'Unknown';
                final date = transaction['date'] as DateTime;
                final formattedDate = DateFormat('yyyy-MM-dd').format(date);
                final isIncome = type.toLowerCase() == 'income';

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        category,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        formattedDate,
                        style: const TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                      Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: TextStyle(color: isIncome ? Colors.green : Colors.red, fontSize: 14),
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

  Widget _buildCategoryPieChart(Map<String, double> categoryData) {
    if (categoryData.isEmpty) {
      return const Center(
        child: Text(
          'No expense categories to display',
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
      );
    }

    final totalAmount = categoryData.values.reduce((a, b) => a + b);

    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Expense Categories',
              style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 200,
                    child: PieChart(
                      PieChartData(
                        sections: categoryData.entries
                            .map((entry) => PieChartSectionData(
                                  color: Colors.primaries[
                                      categoryData.keys.toList().indexOf(entry.key) %
                                          Colors.primaries.length],
                                  value: entry.value,
                                  title: '',
                                  radius: 50,
                                ))
                            .toList(),
                        centerSpaceRadius: 40,
                        sectionsSpace: 4,
                        pieTouchData: PieTouchData(
                          touchCallback: (FlTouchEvent event, PieTouchResponse? pieTouchResponse) {
                            final touchedSection = pieTouchResponse?.touchedSection;
                            if (touchedSection != null) {
                              final index = touchedSection.touchedSectionIndex;
                              final key = categoryData.keys.toList()[index];
                              final percentage = ((categoryData[key]! / totalAmount) * 100).toStringAsFixed(1);
                              debugPrint('$key: $percentage%');
                            }
                          },
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: categoryData.entries.map((entry) {
                    final colorIndex = categoryData.keys.toList().indexOf(entry.key) %
                        Colors.primaries.length;

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4.0),
                      child: Row(
                        children: [
                          Container(
                            width: 12,
                            height: 12,
                            color: Colors.primaries[colorIndex],
                          ),
                          const SizedBox(width: 8),
                          Text(
                            entry.key,
                            style: const TextStyle(color: Colors.white, fontSize: 14),
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
}
