import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/medicine.dart';

class ExpiringMedicinesScreen extends StatelessWidget {
  final Future<List<Medicine>> expiringMedicinesFuture;

  const ExpiringMedicinesScreen({
    super.key,
    required this.expiringMedicinesFuture,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Expiring Medicines'),
      ),
      body: FutureBuilder<List<Medicine>>(
        future: expiringMedicinesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'No medicines are expiring in the next 30 days.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final medicines = snapshot.data!;
          return ListView.builder(
            itemCount: medicines.length,
            itemBuilder: (context, index) {
              final medicine = medicines[index];
              // Display each expiring batch as a separate item
              return Column(
                children: medicine.batches.map((batch) {
                  final expiryDate = DateFormat('yyyy-MM-dd').format(batch.expiryDate);
                  return Card(
                    margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: ListTile(
                      title: Text(medicine.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('Batch: ${batch.batchNumber}\nCompany: ${medicine.company}'),
                      trailing: Text(
                        'Expires:\n$expiryDate',
                        textAlign: TextAlign.right,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  );
                }).toList(),
              );
            },
          );
        },
      ),
    );
  }
}