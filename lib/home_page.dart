import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

import 'login_page.dart';
import 'update_profile.dart';
import 'all_transactions.dart';
import 'add_transaction.dart';
import 'dashboard_page.dart';
import 'receiptscanner.dart';

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? userName;
  double netWorth = 0.0;
  final User? user = FirebaseAuth.instance.currentUser;
  String userEmail = 'No email available';

  // Load API keys from .env
  final String finnhubApiKey = dotenv.env['FINNHUB_API_KEY'] ?? '';
  final String newsApiKey = dotenv.env['NEWSAPI_API_KEY'] ?? '';

  // Sample stock symbols to track
  final List<String> stockSymbols = ['AAPL', 'GOOGL', 'AMZN'];

  // Data holders
  Map<String, dynamic> stockData = {};
  List<dynamic> newsData = [];
  Map<String, dynamic> userInfo = {};
  bool isLoadingStock = true;
  bool isLoadingNews = true;

  @override
  void initState() {
    super.initState();
    fetchUserData();
    fetchStockUpdates();
    fetchNewsUpdates();
  }

  Future<void> fetchUserData() async {
    if (user != null) {
      userEmail = user!.email ?? 'No email available';
      try {
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .get();
        final data = userDoc.data() as Map<String, dynamic>?;
        final savings = (data?['savings'] ?? 0.0) as double;

        final transactionsSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user!.uid)
            .collection('transactions')
            .get();

        double totalIncome = 0.0;
        double totalExpenses = 0.0;
        
        for (var doc in transactionsSnapshot.docs) {
          final transaction = doc.data();
          final double amount = (transaction['amount'] ?? 0).toDouble();
          final String type = transaction['type'] ?? '';

          if (type.toLowerCase() == 'income') {
            totalIncome += amount;
          } else if (type.toLowerCase() == 'expense') {
            totalExpenses += amount;
          }
        }

        final netBalance = savings + totalIncome - totalExpenses;

        setState(() {
          userName = (data != null &&
                  data['name'] != null &&
                  data['name'].toString().isNotEmpty)
              ? data['name']
              : null;
          netWorth = netBalance;
          userInfo = userDoc.data() as Map<String, dynamic>? ?? {};
        });
      } catch (e) {
        print('Error fetching user data: $e');
      }
    }
  }

  Future<void> fetchStockUpdates() async {
    try {
      for (String symbol in stockSymbols) {
        final response = await http.get(Uri.parse(
            'https://finnhub.io/api/v1/quote?symbol=$symbol&token=$finnhubApiKey'));
        if (response.statusCode == 200) {
          final data = json.decode(response.body);
          if (data != null && data['c'] != null) {
            stockData[symbol] = data['c'];
          } else {
            stockData[symbol] = 'N/A';
          }
        } else {
          stockData[symbol] = 'Error';
        }
      }
    } catch (e) {
      print('Error fetching stock data: $e');
    } finally {
      setState(() {
        isLoadingStock = false;
      });
    }
  }

  Future<void> fetchNewsUpdates() async {
    try {
      final response = await http.get(Uri.parse(
          'https://newsapi.org/v2/top-headlines?category=business&country=us&apiKey=$newsApiKey'));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          newsData = data['articles'];
        });
      } else {
        print('Failed to load news');
      }
    } catch (e) {
      print('Error fetching news: $e');
    } finally {
      setState(() {
        isLoadingNews = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    String displayName = userName ?? userEmail.split('@')[0];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Page'),
        backgroundColor: Colors.black, // Updated to match other pages
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (context) => const LoginPage()),
                (route) => false,
              );
            },
            tooltip: 'Log Out',
          ),
        ],
      ),
      drawer: _buildDrawer(displayName, netWorth),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildUserInfo(displayName, netWorth),
            const SizedBox(height: 20),
            _buildSectionTitle('Stock Updates'),
            isLoadingStock
                ? const Center(child: CircularProgressIndicator())
                : _buildStockUpdates(),
            const SizedBox(height: 20),
            _buildSectionTitle('Latest Financial News'),
            isLoadingNews
                ? const Center(child: CircularProgressIndicator())
                : _buildNewsUpdates(),
          ],
        ),
      ),
    );
  }

  Widget _buildUserInfo(String name, double netWorth) {
    final formattedNetWorth = NumberFormat.currency(symbol: '\$').format(netWorth);
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hello, $name!',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Net Worth: $formattedNetWorth',
              style: const TextStyle(color: Colors.white70, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStockUpdates() {
    return Card(
      color: Colors.grey[900], // Dark theme for consistency
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: stockSymbols.map((symbol) {
          return ListTile(
            leading: Icon(Icons.show_chart, color: Colors.blueAccent),
            title: Text(
              symbol,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white, // Improved contrast
              ),
            ),
            trailing: Text(
              stockData[symbol] != null
                  ? stockData[symbol] is double
                      ? '\$${stockData[symbol].toStringAsFixed(2)}'
                      : stockData[symbol].toString()
                  : 'N/A',
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white, // Improved contrast
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildNewsUpdates() {
    return Column(
      children: newsData.map((article) {
        return Card(
          color: Colors.grey[900],
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            leading: article['urlToImage'] != null
                ? Image.network(
                    article['urlToImage'],
                    width: 100,
                    fit: BoxFit.cover,
                  )
                : Container(
                    width: 100,
                    color: Colors.grey,
                    child: const Icon(Icons.image, color: Colors.white),
                  ),
            title: Text(
              article['title'] ?? 'No Title',
              style: const TextStyle(color: Colors.white),
            ),
            subtitle: Text(
              article['description'] ?? 'No Description',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white70),
            ),
            onTap: () {
              if (article['url'] != null) {
                _launchURL(article['url']);
              }
            },
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Drawer _buildDrawer(String displayName, double netWorth) {
    final formattedNetWorth =
        NumberFormat.currency(symbol: '\$').format(netWorth);
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(displayName),
            accountEmail: Text(userEmail),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              backgroundImage: NetworkImage(
                userInfo['profilePic']??
                    'https://upload.wikimedia.org/wikipedia/commons/a/ac/Default_pfp.jpg', 
              ),

            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            onTap: () {
              Navigator.pop(context);
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
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UpdateProfilePage()),
              );
              fetchUserData();
            },
          ),
          ListTile(
            leading: const Icon(Icons.add),
            title: const Text('Add Income/Expenses'),
            onTap: () async {
              Navigator.pop(context);
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AddTransactionPage()),
              );
              fetchUserData();
            },
          ),
          ListTile(
            leading: const Icon(Icons.list),
            title: const Text('All Transactions'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const AllTransactionsPage()),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.receipt),
            title: const Text('Receipt Scanner'),
            onTap: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReceiptScannerPage()),
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
    );
  }

  void _launchURL(String url) async {
    Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not open the article.')),
      );
    }
  }
}
