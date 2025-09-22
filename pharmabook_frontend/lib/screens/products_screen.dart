import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'medicine_detail_screen.dart';

class ProductsScreen extends StatefulWidget {
  const ProductsScreen({super.key});

  @override
  State<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends State<ProductsScreen> {
  late Future<List<Medicine>> _medicinesFuture;
  late ApiService apiService;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context, listen: false);
    apiService = ApiService(authService);
    _loadMedicines();
  }

  void _loadMedicines() {
    setState(() {
      _medicinesFuture = apiService.getMedicines();
    });
  }

  void _navigateToDetail(Medicine medicine) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MedicineDetailScreen(medicine: medicine),
      ),
    );

    if (result == true) {
      _loadMedicines();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('All Products'),
        centerTitle: true,
      ),
      body: FutureBuilder<List<Medicine>>(
        future: _medicinesFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No medicines found.'));
          }

          // Sort the medicines alphabetically by name
          final medicines = snapshot.data!;
          medicines.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));

          return RefreshIndicator(
            onRefresh: () async => _loadMedicines(),
            child: ListView.builder(
              itemCount: medicines.length,
              itemBuilder: (context, index) {
                final med = medicines[index];
                final totalQuantity = med.batches.fold<int>(
                  0,
                  (sum, batch) => sum + batch.quantity,
                );

                return Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                  child: ListTile(
                    title: Text(med.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text(med.company),
                    trailing: Text('Stock: $totalQuantity'),
                    onTap: () => _navigateToDetail(med),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}