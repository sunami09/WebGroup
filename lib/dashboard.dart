import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(FinanceApp());
}

class FinanceApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Finance Dashboard',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: DashboardScreen(),
    );
  }
}

class DashboardScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Finance Dashboard'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder(
              stream: FirebaseFirestore.instance.collection('transactions').snapshots(),
              builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (!snapshot.hasData) {
                  return Center(child: CircularProgressIndicator());
                }

                double incomeTotal = 0;
                double expenseTotal = 0;

                snapshot.data!.docs.forEach((doc) {
                  if (doc['type'] == 'income') {
                    incomeTotal += doc['amount'];
                  } else if (doc['type'] == 'expense') {
                    expenseTotal += doc['amount'];
                  }
                });

                return Column(
                  children: [
                    DashboardCard(
                      title: 'Total Income',
                      amount: '\$${incomeTotal.toStringAsFixed(2)}',
                      color: Colors.greenAccent,
                      icon: Icons.arrow_downward,
                    ),
                    SizedBox(height: 16.0),
                    DashboardCard(
                      title: 'Total Expenses',
                      amount: '\$${expenseTotal.toStringAsFixed(2)}',
                      color: Colors.redAccent,
                      icon: Icons.arrow_upward,
                    ),
                    SizedBox(height: 16.0),
                    DashboardCard(
                      title: 'Balance',
                      amount: '\$${(incomeTotal - expenseTotal).toStringAsFixed(2)}',
                      color: Colors.blueAccent,
                      icon: Icons.account_balance,
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTransactionScreen()),
          );
        },
        child: Icon(Icons.add),
        backgroundColor: Colors.blueAccent,
      ),
    );
  }
}

class DashboardCard extends StatelessWidget {
  final String title;
  final String amount;
  final Color color;
  final IconData icon;

  DashboardCard({required this.title, required this.amount, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(15.0),
      ),
      padding: EdgeInsets.all(16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 18.0, fontWeight: FontWeight.bold, color: Colors.white),
              ),
              SizedBox(height: 8.0),
              Text(
                amount,
                style: TextStyle(fontSize: 22.0, fontWeight: FontWeight.bold, color: Colors.white),
              ),
            ],
          ),
          Icon(
            icon,
            size: 40.0,
            color: Colors.white,
          ),
        ],
      ),
    );
  }
}

class AddTransactionScreen extends StatelessWidget {
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _transactionType = 'income';

  void _addTransaction() {
    double amount = double.parse(_amountController.text);
    String description = _descriptionController.text;

    FirebaseFirestore.instance.collection('transactions').add({
      'type': _transactionType,
      'amount': amount,
      'description': description,
      'timestamp': Timestamp.now(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add Transaction'),
        backgroundColor: Colors.blueAccent,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            DropdownButton<String>(
              value: _transactionType,
              items: [
                DropdownMenuItem(value: 'income', child: Text('Income')),
                DropdownMenuItem(value: 'expense', child: Text('Expense')),
              ],
              onChanged: (value) {
                _transactionType = value!;
              },
            ),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(labelText: 'Amount'),
            ),
            TextField(
              controller: _descriptionController,
              decoration: InputDecoration(labelText: 'Description'),
            ),
            SizedBox(height: 20.0),
            ElevatedButton(
              onPressed: () {
                _addTransaction();
                Navigator.pop(context);
              },
              child: Text('Add Transaction'),
            ),
          ],
        ),
      ),
    );
  }
}
