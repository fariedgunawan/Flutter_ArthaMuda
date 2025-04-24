import 'package:flutter/material.dart';
import 'login_screen.dart';
import 'register_screen.dart';
import 'dashboard_screen.dart';
import 'addincome_screen.dart';
import 'addoutcome_screen.dart';
import 'editincome_screen.dart';
import 'listTransaction_screen.dart';
import 'listincome_screen.dart';
import 'listoutcome_screen.dart';
import 'stats_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ArthaMuda',
      theme: ThemeData(
        primaryColor: const Color(0xFF3339B4),
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      initialRoute: '/',
      debugShowCheckedModeBanner: false,
      routes: {
        '/': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
      onGenerateRoute: (settings) {
        // Check for token in all protected routes
        final token = _getToken();
        
        // List of protected routes
        final protectedRoutes = [
          '/dashboard',
          '/addIncome',
          '/addOutcome',
          '/listTransaction',
          '/listIncomeTransaction',
          '/listOutcomeTransaction',
          '/stats',
        ];

        if (protectedRoutes.contains(settings.name)) {
          if (token == null) {
            // Redirect to login if no token
            return MaterialPageRoute(
              builder: (context) => const LoginScreen(),
            );
          }
          
          // Handle each protected route
          switch (settings.name) {
            case '/dashboard':
              return MaterialPageRoute(
                builder: (context) => const DashboardScreen(),
              );
            case '/addIncome':
              return MaterialPageRoute(
                builder: (context) => const AddIncomeScreen(),
              );
            case '/addOutcome':
              return MaterialPageRoute(
                builder: (context) => const AddOutcomeScreen(),
              );
            case '/listTransaction':
              return MaterialPageRoute(
                builder: (context) => const ListTransactionScreen(),
              );
            case '/listIncomeTransaction':
              return MaterialPageRoute(
                builder: (context) => const ListTransactionIncomeScreen(),
              );
            case '/listOutcomeTransaction':
              return MaterialPageRoute(
                builder: (context) => const ListTransactionOutcomeScreen(),
              );
            case '/stats':
              return MaterialPageRoute(
                builder: (context) => const StatsScreen(),
              );
            // Add other protected routes here
          }
        }
        
        // Handle edit income route with ID parameter
        if (settings.name != null && settings.name!.startsWith('/')) {
          final pathSegments = Uri.parse(settings.name!).pathSegments;
          if (pathSegments.length == 1 && pathSegments[0] != '') {
            final id = pathSegments[0];
            if (token == null) {
              return MaterialPageRoute(
                builder: (context) => const LoginScreen(),
              );
            }
            return MaterialPageRoute(
              builder: (context) => EditIncomeScreen(
                id: id,
              ),
            );
          }
        }

        return null;
      },
    );
  }
}

// You might want to create a wrapper widget for protected screens
class PrivateRoute extends StatelessWidget {
  final Widget child;
  final String? token;

  const PrivateRoute({
    super.key,
    required this.child,
    required this.token,
  });

  @override
  Widget build(BuildContext context) {
    if (token == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/');
      });
      return const SizedBox.shrink();
    }
    return child;
  }
}