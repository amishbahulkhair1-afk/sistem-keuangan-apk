import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/main.dart';
import 'package:flutter_app/services/auth_service.dart';
import 'package:flutter_app/services/api_service.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    final authService = AuthService();
    final apiService = ApiService(authService);
    await tester.pumpWidget(MyApp(authService: authService, apiService: apiService));
    expect(find.byType(MyApp), findsOneWidget);
  });
}
