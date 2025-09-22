import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'expiring_medicines_screen.dart'; // We will create this next

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Medicine>> _dailyReports;
  late Future<List<Medicine>> _weeklyReports;
  late Future<List<Medicine>> _monthlyReports;
  late Future<List<Medicine>> _expiringMedicines;
  late ApiService apiService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context, listen: false);
    apiService = ApiService(authService);
    _fetchReports();
  }

  void _fetchReports() {
    setState(() {
      _dailyReports = apiService.getDailyReport();
      _weeklyReports = apiService.getWeeklyReport();
      _monthlyReports = apiService.getMonthlyReport();
      _expiringMedicines = apiService.getExpiringMedicines();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authService = Provider.of<AuthService>(context);
    final userName = authService.currentUser?.name ?? 'User';

    return Scaffold(
      appBar: AppBar(
        title: Text('Welcome, $userName!'),
        actions: [
          // Notification Icon with Badge
          FutureBuilder<List<Medicine>>(
            future: _expiringMedicines,
            builder: (context, snapshot) {
              final count = snapshot.hasData ? snapshot.data!.length : 0;
              return Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.notifications_outlined),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ExpiringMedicinesScreen(
                            expiringMedicinesFuture: _expiringMedicines,
                          ),
                        ),
                      );
                    },
                  ),
                  if (count > 0)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '$count',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => _fetchReports(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Reports Overview',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _buildReportGrid(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildReportGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      children: [
        DashboardCard(
          title: 'Daily Reports',
          future: _dailyReports,
          color: Colors.blue.shade400,
          icon: Icons.today,
        ),
        DashboardCard(
          title: 'Weekly Reports',
          future: _weeklyReports,
          color: Colors.green.shade400,
          icon: Icons.calendar_view_week,
        ),
        DashboardCard(
          title: 'Monthly Reports',
          future: _monthlyReports,
          color: Colors.orange.shade400,
          icon: Icons.calendar_month,
        ),
        DashboardCard(
          title: 'Expiring Soon',
          future: _expiringMedicines,
          color: Colors.red.shade400,
          icon: Icons.warning_amber_rounded,
        ),
      ],
    );
  }
}

// A reusable card widget for the dashboard
class DashboardCard extends StatelessWidget {
  final String title;
  final Future<List<Medicine>> future;
  final Color color;
  final IconData icon;

  const DashboardCard({
    super.key,
    required this.title,
    required this.future,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 32, color: Colors.white),
            FutureBuilder<List<Medicine>>(
              future: future,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  );
                } else if (snapshot.hasError) {
                  return const Icon(Icons.error, color: Colors.white);
                }
                // Correctly counts the number of batches across all medicines
                final count = snapshot.data?.fold<int>(0, (prev, med) => prev + med.batches.length) ?? 0;
                return Text(
                  count.toString(),
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                );
              },
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}