import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Services
import 'services/auth_service.dart';

// Screens
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/search_screen.dart';
import 'screens/add_medicine.dart';
import 'screens/reports_screen.dart';
import 'screens/profile_screen.dart';

void main() {
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const PharmaBookApp(),
    ),
  );
}

class PharmaBookApp extends StatelessWidget {
  const PharmaBookApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PharmaBook',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        scaffoldBackgroundColor: Colors.grey[50],
        appBarTheme: const AppBarTheme(
          elevation: 0,
          backgroundColor: Colors.teal,
          foregroundColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
  shape: RoundedRectangleBorder(
    borderRadius: BorderRadius.all(Radius.circular(15)),
  ),
  elevation: 2,
),
      ),
      home: Consumer<AuthService>(
        builder: (context, auth, child) {
          if (auth.isAuthenticated) {
            return const MainNavigation();
          } else {
            return const LoginScreen();
          }
        },
      ),
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

  final List<Widget> _pages = const [
    HomeScreen(),
    SearchScreen(),
    AddMedicineScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.teal,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: "Search"),
          BottomNavigationBarItem(
              icon: Icon(Icons.add_box), label: "Add Medicine"),
          BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart), label: "Reports"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
