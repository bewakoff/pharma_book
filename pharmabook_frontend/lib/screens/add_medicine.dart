import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';
import 'add_medicine_form_screen.dart';
import 'medicine_detail_screen.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  late Future<List<Medicine>> _medicinesFuture;
  late ApiService apiService;
  String _searchQuery = '';

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
      MaterialPageRoute(builder: (context) => MedicineDetailScreen(medicine: medicine)),
    );

    if (result == true) _loadMedicines();
  }

  void _navigateToAddForm() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const AddMedicineFormScreen()),
    );

    if (result == true) _loadMedicines();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Inventory'), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              onChanged: (value) => setState(() => _searchQuery = value),
              decoration: const InputDecoration(labelText: 'Search Medicines', prefixIcon: Icon(Icons.search), border: OutlineInputBorder()),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Medicine>>(
              future: _medicinesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
                if (snapshot.hasError) return Center(child: Text('Error: ${snapshot.error}'));
                if (!snapshot.hasData || snapshot.data!.isEmpty) return const Center(child: Text('No medicines found.'));

                final medicines = snapshot.data!.where((med) => med.name.toLowerCase().contains(_searchQuery.toLowerCase())).toList();

                return RefreshIndicator(
                  onRefresh: () async => _loadMedicines(),
                  child: ListView.builder(
                    itemCount: medicines.length,
                    itemBuilder: (context, index) {
                      final med = medicines[index];
                      final totalQuantity = med.batches.fold<int>(0, (sum, batch) => sum + batch.quantity);
                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        child: ListTile(title: Text(med.name), subtitle: Text(med.company), trailing: Text('Stock: $totalQuantity', style: const TextStyle(fontSize: 16)), onTap: () => _navigateToDetail(med)),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(onPressed: _navigateToAddForm, label: const Text('Add Medicine'), icon: const Icon(Icons.add)),
    );
  }
}
