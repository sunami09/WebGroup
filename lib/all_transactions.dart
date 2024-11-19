import 'package:flutter/material.dart';

class AllTransactionsPage extends StatelessWidget {
  const AllTransactionsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Transactions'),
      ),
      body: const Center(
        child: Text(
          'This is All Transactions',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
