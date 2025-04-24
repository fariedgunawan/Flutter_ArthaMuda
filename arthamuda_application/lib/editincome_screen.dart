import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

const _primaryColor = Color(0xFF3339B4);

class EditIncomeScreen extends StatefulWidget {
  final String id;

  const EditIncomeScreen({super.key, required this.id});

  @override
  State<EditIncomeScreen> createState() => _EditIncomeScreenState();
}

class _EditIncomeScreenState extends State<EditIncomeScreen> {
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

    _token = token;
    await _fetchTransactionDetails();
    await _fetchRecentTransactions();
  }

  Future<void> _fetchTransactionDetails() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://192.168.200.234:3000/api/transactions/${widget.id}'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success']) {
        final transaction = responseData['data'];
        _titleController.text = transaction['name'] ?? '';
        _amountController.text = transaction['amount'].toString();
        _dateController.text = transaction['date']?.split('T')[0] ?? '';
      }
    } catch (_) {
      _showSnackBar('Failed to load transaction details', isError: true);
    }
  }

  Future<void> _fetchRecentTransactions() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://192.168.200.234:3000/api/transactions/income'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success']) {
        setState(() {
          transactions = (responseData['data'] as List).take(4).toList();
        });
      }
    } catch (_) {
      _showSnackBar('Failed to load recent transactions', isError: true);
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _handleUpdate() async {
    if (_token == null) return;

    try {
      final response = await http.put(
        Uri.parse('http://192.168.200.234:3000/api/transactions/${widget.id}'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: json.encode({
          'name': _titleController.text,
          'amount': double.tryParse(_amountController.text) ?? 0.0,
          'date': _dateController.text,
        }),
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success']) {
        _showSnackBar('Transaction updated successfully');
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (_) {
      _showSnackBar('Failed to update transaction', isError: true);
    }
  }

  Future<void> _handleDelete() async {
    if (_token == null) return;

    try {
      final response = await http.delete(
        Uri.parse('http://192.168.200.234:3000/api/transactions/${widget.id}'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200 && responseData['success']) {
        _showSnackBar('Transaction deleted successfully');
        Navigator.pushReplacementNamed(context, '/dashboard');
      }
    } catch (_) {
      _showSnackBar('Failed to delete transaction', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  String _formatAmount(dynamic amount) {
    final numericAmount = double.tryParse(amount.toString()) ?? 0.0;
    return NumberFormat.decimalPattern().format(numericAmount);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // Dismiss keyboard
      child: Scaffold(
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
                // header and form
                _buildHeader(),
                _buildRecentIncomeList(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 30, 16, 20),
      decoration: const BoxDecoration(
        color: _primaryColor,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Edit Income',
                style: TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.bold),
              ),
              IconButton(
                icon: const Icon(Icons.account_circle, color: Colors.white, size: 30),
                onPressed: () {},
              ),
            ],
          ),
          const SizedBox(height: 40),
          _buildInputField(label: 'Title', hint: 'Input Title Here..', controller: _titleController),
          const SizedBox(height: 30),
          _buildInputField(label: 'Rp.', hint: 'Input Balance Here..', controller: _amountController, keyboardType: TextInputType.number),
          const SizedBox(height: 30),
          _buildInputField(label: 'Date', hint: 'Select Date', controller: _dateController, isDate: true),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              TextButton(
                onPressed: _handleDelete,
                child: const Text('Delete', style: TextStyle(color: Colors.red, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
              TextButton(
                onPressed: _handleUpdate,
                child: const Text('Update', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRecentIncomeList() {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Last Income', style: TextStyle(color: _primaryColor, fontSize: 20, fontWeight: FontWeight.bold)),
                GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/ListIncome'),
                  child: const Text('See More', style: TextStyle(color: _primaryColor, fontSize: 16, fontWeight: FontWeight.w500)),
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
                    decoration: BoxDecoration(color: _primaryColor, borderRadius: BorderRadius.circular(15)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Image.asset('assets/income.png', width: 50),
                            const SizedBox(width: 20),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(transaction['name'], style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
                                Text('+ Rp. ${_formatAmount(transaction['amount'])}', style: const TextStyle(color: Colors.white)),
                              ],
                            ),
                          ],
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              transaction['date'].split('T')[0],
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                            Text(
                              TimeOfDay.fromDateTime(DateTime.parse(transaction['date']).toLocal()).format(context),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
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
    );
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
        Text(label, style: const TextStyle(color: Colors.white, fontSize: 20)),
        const SizedBox(width: 10),
        Expanded(
          child: TextField(
            controller: controller,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 16),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(color: Colors.white54),
              border: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
              focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white)),
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
                      controller.text = pickedDate.toIso8601String().split('T')[0];
                    }
                  }
                : null,
            readOnly: isDate,
          ),
        ),
      ],
    );
  }
}