import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await initializeDateFormatting('id_ID', null);
  } catch (_) {}

  final authService = AuthService();
  final apiService = ApiService(authService);

  runApp(MyApp(authService: authService, apiService: apiService));
}

class MyApp extends StatelessWidget {
  final AuthService authService;
  final ApiService apiService;

  const MyApp({
    super.key,
    required this.authService,
    required this.apiService,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: authService,
      builder: (context, _) {
        return MaterialApp(
          title: 'Sistem Pelaporan',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: authService.isLoading
              ? const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: AppTheme.primary),
                  ),
                )
              : authService.isAuthenticated
                  ? HomeScreen(
                      authService: authService,
                      apiService: apiService,
                    )
                  : LoginScreen(
                      authService: authService,
                      apiService: apiService,
                    ),
        );
      },
    );
  }
}
