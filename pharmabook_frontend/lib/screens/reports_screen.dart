import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  late Future<List<Medicine>> _dailyReports;
  late Future<List<Medicine>> _weeklyReports;

  @override
  void initState() {
    super.initState();
    _dailyReports = ApiService.getDailyReport(context);
    _weeklyReports = ApiService.getWeeklyReport(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reports'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Daily Reports', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            _buildReportList(_dailyReports),
            const SizedBox(height: 20),
            Text('Weekly Reports', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 10),
            _buildReportList(_weeklyReports),
          ],
        ),
      ),
    );
  }

  Widget _buildReportList(Future<List<Medicine>> future) {
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
          final medicines = snapshot.data!;
          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final medicine = medicines[index];
              final totalQuantity = medicine.batches.fold<int>(
                0,
                (sum, batch) => sum + batch.quantity,
              );
              return ListTile(
                title: Text(medicine.name),
                subtitle: Text('Quantity: $totalQuantity'),
              );
            },
          );
        }
      },
    );
  }
}
