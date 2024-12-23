import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AddTransactionPage extends StatefulWidget {
  final Map<String, dynamic>? prefilledData;
  final VoidCallback? onTransactionAdded; // Callback to update the parent list

  const AddTransactionPage({Key? key, this.prefilledData, this.onTransactionAdded}) : super(key: key);

  @override
  _AddTransactionPageState createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _transactionType = "income"; // Default to income
  String _category = "Food"; // Default category
  DateTime _selectedDate = DateTime.now();

  final List<String> _categories = [
    "Food",
    "Salary",
    "Rent",
    "Entertainment",
    "Bills",
    "Miscellaneous",
    "Grocery" // Add "Grocery" to match prefilled data
  ];

  @override
  void initState() {
    super.initState();
    if (widget.prefilledData != null) {
      final data = widget.prefilledData!;
      _amountController.text = data['amount'].toString();
      _descriptionController.text = data['description'] ?? '';
      _transactionType = data['type'] ?? "income";
      _category = _categories.contains(data['category'])
          ? data['category']
          : _categories.first; // Default to the first category if not found
      _selectedDate = data['date'] != null
          ? (data['date'] is Timestamp
              ? (data['date'] as Timestamp).toDate()
              : DateTime.parse(data['date'].toString()))
          : DateTime.now();
    }
  }

  Future<void> _addTransaction() async {
    if (!_formKey.currentState!.validate()) return;

    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .add({
          'amount': double.parse(_amountController.text),
          'type': _transactionType,
          'category': _category,
          'description': _descriptionController.text,
          'date': _selectedDate,
        });

        // Show a success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Transaction added successfully!')),
        );

        // Call the callback to update the parent list
        if (widget.onTransactionAdded != null) {
          widget.onTransactionAdded!();
        }

        // Return to the previous page
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (pickedDate != null) {
      final TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.fromDateTime(_selectedDate),
      );
      if (pickedTime != null) {
        setState(() {
          _selectedDate = DateTime(
            pickedDate.year,
            pickedDate.month,
            pickedDate.day,
            pickedTime.hour,
            pickedTime.minute,
          );
        });
      } else {
        setState(() {
          _selectedDate = pickedDate;
        });
      }
    }
  }

  String formatDateTime(DateTime date) {
    return DateFormat('yyyy-MM-dd hh:mm a').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Transaction'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _amountController,
                  decoration: const InputDecoration(labelText: 'Amount'),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter an amount';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _transactionType,
                  decoration: const InputDecoration(labelText: 'Transaction Type'),
                  items: const [
                    DropdownMenuItem(value: "income", child: Text("Income")),
                    DropdownMenuItem(value: "expense", child: Text("Expense")),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _transactionType = value!;
                    });
                  },
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  decoration: const InputDecoration(labelText: 'Category'),
                  items: _categories.map((category) {
                    return DropdownMenuItem<String>(
                      value: category,
                      child: Text(category),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _category = value!;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select a category';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a description';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Date: ${formatDateTime(_selectedDate)}",
                        style: const TextStyle(fontSize: 16),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () => _selectDate(context),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 40),
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Select Date'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                Center(
                  child: ElevatedButton(
                    onPressed: _addTransaction,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(150, 50),
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Add Transaction'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
