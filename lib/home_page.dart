import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'update_profile.dart';
import 'all_transactions.dart';
import 'add_transaction.dart';
import 'dashboard_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userName;
  final User? user = FirebaseAuth.instance.currentUser;
  final String userEmail = FirebaseAuth.instance.currentUser?.email ?? 'No email available';

  @override
  void initState() {
    super.initState();
    fetchUserName();
  }

  Future<void> fetchUserName() async {
    if (user != null) {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user!.uid)
          .get();

      setState(() {
        userName = userDoc.exists && userDoc['name'] != null && userDoc['name'].toString().isNotEmpty
            ? userDoc['name']
            : null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.redAccent,
              ),
              child: Text(
                'Welcome, ${userName ?? userEmail.split('@')[0]}',
                style: const TextStyle(
                  fontSize: 24,
                  color: Colors.white,
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DashboardPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Profile'),
              onTap: () async {
                Navigator.pop(context); // Close the drawer
                // Navigate to UpdateProfilePage and refresh when returning
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const UpdateProfilePage()),
                );
                // Refresh the user name after coming back from UpdateProfilePage
                fetchUserName();
              },
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Income/Expenses'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddTransactionPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.list),
              title: const Text('All Transactions'),
              onTap: () {
                Navigator.pop(context); // Close the drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AllTransactionsPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Log Out'),
              onTap: () async {
                await FirebaseAuth.instance.signOut();
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LoginPage()),
                  (route) => false,
                );
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              userName != null ? 'Hello, $userName!' : 'Hello, ${userEmail.split('@')[0]}',
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              'Your email: $userEmail',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            if (userName == null) // Only show "Update Profile" button if userName is null
              ElevatedButton(
                onPressed: () async {
                  // Navigate to UpdateProfilePage and refresh when returning
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const UpdateProfilePage()),
                  );
                  // Refresh the user name after coming back from UpdateProfilePage
                  fetchUserName();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                child: const Text(
                  'Update Profile',
                  style: TextStyle(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
