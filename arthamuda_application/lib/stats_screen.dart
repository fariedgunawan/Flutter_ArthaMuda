import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'dart:math';

const _primaryColor = Color(0xFF3339B4);
const _incomeColor = Color(0xFF0e93df);
const _outcomeColor = Color(0xFFdf0e1d);
const _backgroundColor = Color(0xFFf8f9fa);
const _textColor = Color(0xFF333333);
const _cardColor = Colors.white;

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  double _totalIncome = 0;
  double _totalOutcome = 0;
  double _balance = 0;
  double _spendingPercentage = 0;
  String _status = "boros";
  bool _isLoading = true;
  String? _token;
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _loadTokenAndData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
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

    await _fetchBalance();
    await _fetchAnalysis();
    _animationController.forward();
  }

  Future<void> _fetchBalance() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://192.168.200.234:3000/api/transactions/balance'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _totalIncome = double.parse(
            responseData['data']['totalIncome'] ?? '0',
          );
          _totalOutcome = double.parse(
            responseData['data']['totalOutcome'] ?? '0',
          );
          _balance = _totalIncome - _totalOutcome;
        });
      }
    } catch (err) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Failed to load balance data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _fetchAnalysis() async {
    if (_token == null) return;

    try {
      final response = await http.get(
        Uri.parse('http://192.168.200.234:3000/api/transactions/analysis'),
        headers: {'Authorization': 'Bearer $_token'},
      );

      final responseData = json.decode(response.body);
      if (response.statusCode == 200) {
        setState(() {
          _spendingPercentage =
              responseData['data']['spendingPercentage']?.toDouble() ?? 0.0;
          _status = responseData['data']['status'] ?? "boros";
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
            content: Text('Failed to load analysis data'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCurrency(double amount) {
    return 'Rp${amount.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (Match m) => '${m[1]}.')}';
  }

  Widget _buildInfoCard(String title, String value, Color color) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, 50 * (1 - _animation.value)),
          child: Opacity(opacity: _animation.value, child: child),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        color: _cardColor,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: _backgroundColor,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation(_primaryColor),
              ),
              const SizedBox(height: 20),
              Text(
                'Loading your financial data...',
                style: TextStyle(color: _primaryColor, fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Financial Overview',
                      style: TextStyle(
                        color: _primaryColor,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    CircleAvatar(
                      backgroundColor: _primaryColor.withOpacity(0.1),
                      child: IconButton(
                        icon: Icon(Icons.account_circle, color: _primaryColor),
                        onPressed: () {},
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Animated Pie Chart
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _animation.value,
                      child: child,
                    );
                  },
                  child: Container(
                    height: 250,
                    width: 250,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        CustomPaint(
                          painter: PieChartPainter(
                            incomeValue: _totalIncome,
                            outcomeValue: _totalOutcome,
                            incomeColor: _incomeColor,
                            outcomeColor: _outcomeColor,
                          ),
                          size: const Size(250, 250),
                        ),
                        Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _cardColor,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 5,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  "${_spendingPercentage.toStringAsFixed(1)}%",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: _primaryColor,
                                  ),
                                ),
                                Text(
                                  "Spent",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: _textColor.withOpacity(0.7),
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
                const SizedBox(height: 40),

                // Financial Cards
                GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 1.2,
                  children: [
                    _buildInfoCard(
                      'Total Income',
                      _formatCurrency(_totalIncome),
                      _incomeColor,
                    ),
                    _buildInfoCard(
                      'Total Outcome',
                      _formatCurrency(_totalOutcome),
                      _outcomeColor,
                    ),
                    _buildInfoCard(
                      'Balance',
                      _formatCurrency(_balance),
                      _primaryColor,
                    ),
                    _buildInfoCard(
                      'Status',
                      _status == "boros" ? "Boros" : "Hemat",
                      _status == "boros" ? _outcomeColor : _incomeColor,
                    ),
                  ],
                ),
                const SizedBox(height: 30),

                // Status Indicator
                AnimatedBuilder(
                  animation: _animation,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(0, 50 * (1 - _animation.value)),
                      child: Opacity(opacity: _animation.value, child: child),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color:
                          _status == "boros"
                              ? _outcomeColor.withOpacity(0.1)
                              : _incomeColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color:
                            _status == "boros"
                                ? _outcomeColor.withOpacity(0.3)
                                : _incomeColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _status == "boros" ? Icons.warning : Icons.thumb_up,
                          color:
                              _status == "boros" ? _outcomeColor : _incomeColor,
                          size: 30,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _status == "boros"
                                    ? "You're spending too much!"
                                    : "Great financial control!",
                                style: TextStyle(
                                  color: _textColor,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _status == "boros"
                                    ? "Try to reduce your expenses by 20% next month"
                                    : "Keep up the good financial habits!",
                                style: TextStyle(
                                  color: _textColor.withOpacity(0.7),
                                  fontSize: 14,
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

class PieChartPainter extends CustomPainter {
  final double incomeValue;
  final double outcomeValue;
  final Color incomeColor;
  final Color outcomeColor;

  PieChartPainter({
    required this.incomeValue,
    required this.outcomeValue,
    required this.incomeColor,
    required this.outcomeColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2);
    final rect = Rect.fromCircle(center: center, radius: radius);
    final Paint paint = Paint()..style = PaintingStyle.fill;

    final total = incomeValue + outcomeValue;
    if (total <= 0) return;

    // Calculate angles in radians
    final incomeAngle = 2 * pi * (incomeValue / total);
    final outcomeAngle = 2 * pi * (outcomeValue / total);

    // Draw income arc with shadow
    paint.color = incomeColor;
    canvas.drawArc(
      rect,
      -pi / 2, // Start at the top (-90 degrees)
      incomeAngle,
      true,
      paint,
    );

    // Draw outcome arc with shadow
    paint.color = outcomeColor;
    canvas.drawArc(
      rect,
      -pi / 2 + incomeAngle, // Start where income arc ended
      outcomeAngle,
      true,
      paint,
    );

    // Add a subtle shadow effect
    final shadowPaint =
        Paint()
          ..color = Colors.black.withOpacity(0.1)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(center, radius, shadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
