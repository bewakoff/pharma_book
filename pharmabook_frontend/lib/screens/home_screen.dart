import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Future<List<Medicine>>? _dailyReports;
  Future<List<Medicine>>? _weeklyReports;

  @override
  void initState() {
    super.initState();
    _fetchReports();
  }

  void _fetchReports() {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (authService.isAuthenticated) {
      // Now we only pass context → ApiService fetches token/userId internally
      setState(() {
        _dailyReports = ApiService.getDailyReport(context);
        _weeklyReports = ApiService.getWeeklyReport(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Home Screen'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Report',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            _buildReportGrid(_dailyReports),
            const SizedBox(height: 20),
            Text(
              'Weekly Report',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 10),
            _buildReportGrid(_weeklyReports),
          ],
        ),
      ),
    );
  }

  Widget _buildReportGrid(Future<List<Medicine>>? future) {
    return FutureBuilder<List<Medicine>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No reports available.'));
        } else {
          return GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
              childAspectRatio: 1.5,
            ),
            itemCount: snapshot.data!.length,
            itemBuilder: (context, index) {
              final medicine = snapshot.data![index];
              final totalQuantity = medicine.batches.fold<int>(
                0,
                (sum, batch) => sum + batch.quantity,
              );
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        medicine.name,
                        style: Theme.of(context).textTheme.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      Text(
                        'Quantity: $totalQuantity',
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
      },
    );
  }
}
