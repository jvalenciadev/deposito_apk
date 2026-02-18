import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/scanner_screen.dart';
import 'screens/history_screen.dart';
import 'models/deposit.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Union Scan Pro',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF003399), // Azul Banco Unión
          brightness: Brightness.light,
        ),
        textTheme: GoogleFonts.outfitTextTheme(),
      ),
      home: const MainNavigation(),
    );
  }
}

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;
  final List<Deposit> _scannedDeposits = [];

  void _addDeposit(Deposit deposit) {
    setState(() {
      _scannedDeposits.add(deposit);
      _selectedIndex = 1; // Go to history after saving
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> _screens = [
      ScannerScreen(onConfirm: _addDeposit),
      HistoryScreen(
        deposits: _scannedDeposits,
        onClear: () => setState(() => _scannedDeposits.clear()),
      ),
    ];

    return Scaffold(
      body: _screens[_selectedIndex],
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (index) {
            setState(() => _selectedIndex = index);
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.qr_code_scanner_outlined),
              selectedIcon: Icon(Icons.qr_code_scanner),
              label: "Escanear",
            ),
            NavigationDestination(
              icon: Icon(Icons.history_outlined),
              selectedIcon: Icon(Icons.history),
              label: "Historial",
            ),
          ],
        ),
      ),
    );
  }
}
