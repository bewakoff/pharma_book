import 'package:flutter/material.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late Future<List<Medicine>> _medicines;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _fetchMedicines();
  }

  void _fetchMedicines() {
    _medicines = ApiService.getMedicines(context);
  }

  void _searchMedicines(String query) {
    setState(() {
      _query = query.toLowerCase();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Search Medicines'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              onChanged: _searchMedicines,
              decoration: const InputDecoration(
                hintText: 'Search by name...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<List<Medicine>>(
                future: _medicines,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text('No medicines found.'));
                  } else {
                    final filtered = snapshot.data!
                        .where((med) => med.name.toLowerCase().contains(_query))
                        .toList();

                    if (filtered.isEmpty) {
                      return const Center(child: Text('No matching results.'));
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (context, index) {
                        final med = filtered[index];
                        final totalQuantity = med.batches.fold<int>(
                          0,
                          (sum, batch) => sum + batch.quantity,
                        );
                        return ListTile(
                          title: Text(med.name),
                          subtitle: Text('Quantity: $totalQuantity'),
                        );
                      },
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
