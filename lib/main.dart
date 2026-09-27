import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'providers/stock_provider.dart';
import 'providers/theme_provider.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MSLStockCheckApp());
}

class MSLStockCheckApp extends StatefulWidget {
  const MSLStockCheckApp({super.key});

  @override
  State<MSLStockCheckApp> createState() => _MSLStockCheckAppState();
}

class _MSLStockCheckAppState extends State<MSLStockCheckApp> {
  final GlobalKey<NavigatorState> _navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (ctx) {
          final auth = AuthProvider();
          ApiService.onSessionExpired = () {
            auth.logout();
          };
          return auth;
        }),
        ChangeNotifierProvider(create: (_) => StockProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          return MaterialApp(
            navigatorKey: _navigatorKey,
            title: 'MSL Stock Check',
            debugShowCheckedModeBanner: false,
            themeMode: themeProvider.themeMode,
            theme: ThemeProvider.lightTheme,
            darkTheme: ThemeProvider.darkTheme,
            home: const SplashScreen(),
          );
        },
      ),
    );
  }
}

