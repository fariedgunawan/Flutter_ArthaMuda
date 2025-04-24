import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:async';

const _primaryColor = Color(0xFF3339B4);
const _successColor = Color(0xFF4CAF50);
const _errorColor = Color(0xFFF44336);

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();
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
      _isLoading = false;
    });

    _fetchIncomeTransactions();
  }

  Future<void> _fetchIncomeTransactions() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://192.168.200.234:3000/api/transactions/income'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success'] && mounted) {
        setState(() {
          transactions = responseData['data'].take(4).toList();
        });
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to load recent transactions'),
            backgroundColor: _errorColor,
          ),
        );
      }
    }
  }

  Future<void> _handleSubmit() async {
  if (_token == null) {
    if (mounted) {
      Navigator.pushReplacementNamed(context, '/dashboard');
    }
    return;
  }

  if (_titleController.text.isEmpty ||
      _amountController.text.isEmpty ||
      _dateController.text.isEmpty) {
    // Show error message if fields are empty
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill all fields'),
          backgroundColor: _errorColor,
        ),
      );
    }
    return;
  }

  try {
    final response = await http.post(
      Uri.parse('http://192.168.200.234:3000/api/transactions'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $_token'
      },
      body: json.encode({
        'type': 'income',
        'name': _titleController.text,
        'amount': double.tryParse(_amountController.text) ?? 0.0,
        'date': _dateController.text,
      }),
    );

    final responseData = json.decode(response.body);

    if (responseData['success'] == true &&
        responseData['message'] == 'Transaksi berhasil ditambahkan!') {
      _titleController.clear();
      _amountController.clear();
      _dateController.clear();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Income data successfully added!'),
            backgroundColor: _successColor,
            duration: Duration(seconds: 2),
          ),
        );
        
        await Future.delayed(const Duration(seconds: 2));
        
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseData['message'] ?? 'Failed to add income'),
            backgroundColor: _errorColor,
          ),
        );
      }
    }
  } catch (err) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('An error occurred while adding income'),
          backgroundColor: _errorColor,
        ),
      );
    }
  }
}

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool isDate = false,
  }) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white54),
              border: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white),
              ),
            ),
            onTap: isDate
                ? () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (pickedDate != null) {
                      controller.text =
                          pickedDate.toIso8601String().split('T')[0];
                    }
                  }
                : null,
            readOnly: isDate,
          ),
        ),
      ],
    );
  }

  String _formatAmount(dynamic amount) {
    final numericAmount = double.tryParse(amount.toString()) ?? 0.0;
    return numericAmount.toStringAsFixed(0);
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
                decoration: const BoxDecoration(
                  color: _primaryColor,
                  borderRadius: BorderRadius.vertical(
                    bottom: Radius.circular(30),
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Add Income',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.account_circle,
                              color: Colors.white, size: 30),
                          onPressed: () {},
                        ),
                      ],
                    ),
                    const SizedBox(height: 40),
                    _buildInputField(
                      label: 'Title',
                      hint: 'Input Title Here..',
                      controller: _titleController,
                    ),
                    const SizedBox(height: 30),
                    _buildInputField(
                      label: 'Rp.',
                      hint: 'Input Balance Here..',
                      controller: _amountController,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 30),
                    _buildInputField(
                      label: 'Date',
                      hint: 'Select Date',
                      controller: _dateController,
                      isDate: true,
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerRight,
                      child: ElevatedButton(
                        onPressed: _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          elevation: 0,
                        ),
                        child: const Text(
                          'Add +',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Last Income',
                            style: TextStyle(
                              color: _primaryColor,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.pushNamed(context, '/listIncomeTransaction');
                            },
                            child: const Text(
                              'See More',
                              style: TextStyle(
                                color: _primaryColor,
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Expanded(
                        child: ListView.builder(
                          itemCount: transactions.length,
                          itemBuilder: (context, index) {
                            final transaction = transactions[index];
                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(15),
                              decoration: BoxDecoration(
                                color: _primaryColor,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Image.asset(
                                        'assets/income.png',
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
                                            '+ Rp. ${_formatAmount(transaction['amount'])}',
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
                                                DateTime.parse(
                                                        transaction['date'])
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
}