import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'TransactionDetailsPage.dart';

class AllTransactionsPage extends StatelessWidget {
  const AllTransactionsPage({Key? key}) : super(key: key);

  Future<List<Map<String, dynamic>>> fetchTransactions() async {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return [];
    }

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions')
        .orderBy('date', descending: true) // Sort transactions by date
        .get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      data['id'] = doc.id; // Add the document ID for reference
      data['date'] = (data['date'] as Timestamp).toDate(); // Convert Timestamp to DateTime
      return data;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchTransactions(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Error loading transactions',
                style: TextStyle(fontSize: 18, color: Colors.red),
              ),
            );
          }

          final transactions = snapshot.data;

          if (transactions == null || transactions.isEmpty) {
            return const Center(
              child: Text(
                'No transactions found',
                style: TextStyle(fontSize: 18),
              ),
            );
          }

          return ListView.builder(
            itemCount: transactions.length,
            itemBuilder: (context, index) {
              final transaction = transactions[index];
              final amount = transaction['amount'] ?? 0;
              final category = transaction['category'] ?? 'Unknown';
              final type = transaction['type'] ?? 'Unknown';
              final date = transaction['date'] as DateTime;

              final isIncome = type.toLowerCase() == 'income';
              final formattedDate = DateFormat('yyyy-MM-dd').format(date);

              return ListTile(
                leading: Icon(
                  isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                  color: isIncome ? Colors.green : Colors.red,
                ),
                title: Text(
                  '$category',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  formattedDate,
                  style: const TextStyle(fontSize: 14),
                ),
                trailing: Text(
                  '\$${amount.toString()}',
                  style: TextStyle(
                    fontSize: 16,
                    color: isIncome ? Colors.green : Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                onTap: () {
                  // Navigate to the details page
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          TransactionDetailsPage(transaction: transaction),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
