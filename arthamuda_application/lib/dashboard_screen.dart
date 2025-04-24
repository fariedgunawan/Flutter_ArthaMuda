import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  String? username;
  int? balance;
  String? lastUpdate;
  List<dynamic> transactions = [];
  String? _token;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Color(0xFF3339B4),
        statusBarIconBrightness: Brightness.light, 
      ),
    );
    _initializeData();
  }

  Future<void> _loadTokenAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    setState(() {
      _token = token;
    });

    // Load your data using the token
    _fetchUserData();
    _fetchBalance();
    _fetchTransactions();
  }

  Future<void> _initializeData() async {
    await _getToken();
    if (_token != null) {
      await Future.wait([
        _fetchUserData(),
        _fetchBalance(),
        _fetchTransactions(),
      ]);
    } else {
      Navigator.pushNamed(context, '/');
    }
    setState(() => _isLoading = false);
  }

  Future<void> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _token = prefs.getString('token');
    });
  }

  Future<void> _fetchUserData() async {
    if (_token == null) return;

    final response = await http.get(
      Uri.parse('http://192.168.200.234:3000/api/auth/me'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.statusCode == 200 && mounted) {
      final data = json.decode(response.body);
      final name = data['username'] ?? 'User';
      setState(() {
        username = name.split('@')[0];
      });
    }
  }

  Future<void> _fetchBalance() async {
    if (_token == null) return;

    final response = await http.get(
      Uri.parse('http://192.168.200.234:3000/api/transactions/balance'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.statusCode == 200 && mounted) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          balance = data['data']['balance'];
          lastUpdate = DateTime.now().toLocal().toString();
        });
      }
    }
  }

  Future<void> _fetchTransactions() async {
    if (_token == null) return;

    final response = await http.get(
      Uri.parse('http://192.168.200.234:3000/api/transactions'),
      headers: {'Authorization': 'Bearer $_token'},
    );

    if (response.statusCode == 200 && mounted) {
      final data = json.decode(response.body);
      if (data['success']) {
        setState(() {
          transactions = data['data'].take(6).toList();
        });
      }
    }
  }

  Future<void> _handleLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('token');
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/bg-img.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  color: Color(0xFF3339B4),
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hello ${username ?? 'User'}..',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.logout,
                                color: Colors.red,
                                size: 30,
                              ),
                              onPressed: _handleLogout,
                            ),
                            const Icon(
                              Icons.account_circle,
                              color: Colors.white,
                              size: 30,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'You have',
                      style: const TextStyle(color: Colors.white, fontSize: 20),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Rp. ${balance?.toStringAsFixed(0) ?? 'Loading...'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/listTransaction');
                          },
                          child: const Text(
                            'See Details',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 5),
                    if (lastUpdate != null)
                      Text(
                        lastUpdate!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                      ),
                  ],
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 20,
                ),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavCard('Income', 'assets/income.png', '/addIncome'),
                    _buildNavCard(
                      'Outcome',
                      'assets/outcome.png',
                      '/addOutcome',
                    ),
                    _buildNavCard('Stats', 'assets/stats.png', '/stats'),
                  ],
                ),
              ),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Recent',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF3339B4),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final tx = transactions[index];
                            final isIncome = tx['type'] == 'income';
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: const Color(0xFF3339B4),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(
                                        isIncome
                                            ? 'assets/income.png'
                                            : 'assets/outcome.png',
                                        width: 40,
                                      ),
                                      const SizedBox(width: 10),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tx['name'],
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 18,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                          Text(
                                            '${isIncome ? '+' : '-'} Rp. ${tx['amount'].toString()}',
                                            style: const TextStyle(
                                              color: Colors.white,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text(
                                        DateTime.parse(
                                          tx['date'],
                                        ).toLocal().toString().split(' ')[0],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                      Text(
                                        TimeOfDay.fromDateTime(
                                          DateTime.parse(tx['date']).toLocal(),
                                        ).format(context),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavCard(String title, String assetPath, String route) {
    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, route);
      },
      child: Column(
        children: [
          Image.asset(assetPath, width: 40),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF3339B4),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
