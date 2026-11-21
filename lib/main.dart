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
          title: 'Donasi Latee',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          home: authService.isLoading
              ? Scaffold(
                  body: Stack(
                    children: [
                      Positioned.fill(
                        child: Container(
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Color(0xFF0077B6), // 0% Top: Biru laut Latee
                                Color(0xFF0284C7), // 25%: Biru sky cerah
                                Color(0xFF7DD3FC), // 55%: Soft blue
                                Color(0xFFE0F2FE), // 78%: Ice blue muda
                                Colors.white,      // 100% Bottom: Putih bersih
                              ],
                              stops: [0.0, 0.25, 0.55, 0.78, 1.0],
                            ),
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Opacity(
                          opacity: 0.20,
                          child: Image.asset(
                            'assets/images/vector.png',
                            fit: BoxFit.cover,
                            alignment: Alignment.center,
                          ),
                        ),
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.transparent,                              // 0%
                                const Color(0xFF0284C7).withValues(alpha: 0.15), // 25%
                                Colors.white.withValues(alpha: 0.65),            // 70%
                                Colors.white.withValues(alpha: 0.95),            // 100%
                              ],
                              stops: const [0.0, 0.25, 0.70, 1.0],
                            ),
                          ),
                        ),
                      ),
                      const Center(
                        child: CircularProgressIndicator(color: AppTheme.primary),
                      ),
                    ],
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
