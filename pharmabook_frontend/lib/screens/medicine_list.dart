import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';

class MedicineListScreen extends StatefulWidget {
  const MedicineListScreen({super.key});

  @override
  State<MedicineListScreen> createState() => _MedicineListScreenState();
}

class _MedicineListScreenState extends State<MedicineListScreen> {
  late Future<List<Medicine>> _medicines;

  @override
  void initState() {
    super.initState();
    _medicines = ApiService.getMedicines(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Medicines'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Medicine>>(
        future: _medicines,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No medicines available.'));
          } else {
            final medicines = snapshot.data!;
            return ListView.builder(
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                final med = medicines[index];
                final totalQuantity = med.batches.fold<int>(
                  0,
                  (sum, batch) => sum + batch.quantity,
                );
                return Card(
                  child: ListTile(
                    title: Text(med.name),
                    subtitle: Text('Quantity: $totalQuantity'),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }
}
