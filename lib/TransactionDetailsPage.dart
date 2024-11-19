import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class TransactionDetailsPage extends StatelessWidget {
  final Map<String, dynamic> transaction;

  const TransactionDetailsPage({Key? key, required this.transaction}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final amount = transaction['amount'] ?? 0;
    final category = transaction['category'] ?? 'Unknown';
    final type = transaction['type'] ?? 'Unknown';
    final description = transaction['description'] ?? 'No description provided';
    final date = transaction['date'] != null
        ? (transaction['date'] as DateTime) // Adjusted for proper data type
        : DateTime.now();

    final formattedDate = DateFormat('yyyy-MM-dd hh:mm a').format(date);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transaction Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Category: $category',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Type: ${type.toUpperCase()}',
              style: TextStyle(
                fontSize: 18,
                color: type.toLowerCase() == 'income' ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Amount: \$${amount.toString()}',
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Date: $formattedDate',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              'Description:',
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              description,
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
