import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

const _primaryColor = Color(0xFF3339B4);

class ListTransactionScreen extends StatefulWidget {
  const ListTransactionScreen({super.key});

  @override
  State<ListTransactionScreen> createState() => _ListTransactionScreenState();
}

class _ListTransactionScreenState extends State<ListTransactionScreen> {
  List<dynamic> transactions = [];
  String? _token;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTokenAndData();
  }

  Future<void> _loadTokenAndData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    
    if (token == null && mounted) {
      Navigator.pushReplacementNamed(context, '/');
      return;
    }

    setState(() {
      _token = token;
    });

    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://192.168.200.234:3000/api/transactions'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success'] && mounted) {
        setState(() {
          transactions = responseData['data'];
          _isLoading = false;
        });
      }
    } catch (err) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load transactions'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatAmount(dynamic amount) {
  final numericAmount = double.tryParse(amount.toString()) ?? 0.0;
  final strAmount = numericAmount.toStringAsFixed(0);
  String result = '';
  int count = 0;
  
  for (int i = strAmount.length - 1; i >= 0; i--) {
    result = strAmount[i] + result;
    count++;
    if (count % 3 == 0 && i != 0) {
      result = '.$result';
    }
  }
  
  return result;
}

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

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
                padding: const EdgeInsets.fromLTRB(16, 30, 16, 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Details',
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.account_circle,
                          color: _primaryColor, size: 30),
                      onPressed: () {},
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: ListView.builder(
                    itemCount: transactions.length,
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      return GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/${transaction['id']}',
                          );
                        },
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            color: _primaryColor,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  Image.asset(
                                    transaction['type'] == 'income'
                                        ? 'assets/income.png'
                                        : 'assets/outcome.png',
                                    width: 50,
                                  ),
                                  const SizedBox(width: 20),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        transaction['name'],
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      Text(
                                        '${transaction['type'] == 'income' ? '+' : '-'} Rp. ${_formatAmount(transaction['amount'])}',
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
                                    DateTime.parse(transaction['date'])
                                        .toLocal()
                                        .toString()
                                        .split(' ')[0],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                  Text(
                                    TimeOfDay.fromDateTime(
                                            DateTime.parse(transaction['date'])
                                                .toLocal())
                                        .format(context),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}