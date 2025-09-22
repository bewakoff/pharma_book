import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class MedicineDetailScreen extends StatefulWidget {
  final Medicine medicine;

  const MedicineDetailScreen({super.key, required this.medicine});

  @override
  State<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends State<MedicineDetailScreen> {
  late Medicine _medicine;
  late ApiService apiService;

  @override
  void initState() {
    super.initState();
    _medicine = widget.medicine;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final authService = Provider.of<AuthService>(context, listen: false);
    apiService = ApiService(authService);
  }

  Future<void> _updateBatchQuantity(Batch batch) async {
    final quantityController = TextEditingController(text: batch.quantity.toString());
    final newQuantity = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Update Quantity for Batch ${batch.batchNumber}'),
        content: TextField(
          controller: quantityController,
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'New Quantity'),
        ),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop()),
          TextButton(child: const Text('Update'), onPressed: () => Navigator.of(context).pop(quantityController.text)),
        ],
      ),
    );

    if (newQuantity != null && newQuantity.isNotEmpty) {
      try {
        await apiService.updateBatch(_medicine.id, batch.batchNumber, int.parse(newQuantity));
        setState(() => batch.quantity = int.parse(newQuantity));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch updated successfully!')));
        }
        Navigator.of(context).pop(true); // Refresh previous screen
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to update batch: $e')));
      }
    }
  }

  Future<void> _deleteBatch(String batchNumber) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Batch?'),
        content: Text('Are you sure you want to delete batch "$batchNumber"?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop(false)),
          TextButton(child: const Text('Delete'), onPressed: () => Navigator.of(context).pop(true)),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await apiService.deleteBatch(_medicine.id, batchNumber);
        setState(() => _medicine.batches.removeWhere((b) => b.batchNumber == batchNumber));
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Batch deleted successfully!')));
        }
        Navigator.of(context).pop(true); // Refresh previous screen
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete batch: $e')));
      }
    }
  }

  Future<void> _deleteMedicine() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine?'),
        content: Text('Are you sure you want to delete "${_medicine.name}" and all batches?'),
        actions: [
          TextButton(child: const Text('Cancel'), onPressed: () => Navigator.of(context).pop(false)),
          TextButton(
            child: const Text('Delete Permanently'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await apiService.deleteMedicine(_medicine.id);
        if (mounted) {
          Navigator.of(context).pop(true); // Refresh previous screen
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Medicine deleted successfully!')));
        }
      } catch (e) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to delete medicine: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_medicine.name),
        actions: [
          IconButton(icon: const Icon(Icons.delete_forever), tooltip: 'Delete Medicine', onPressed: _deleteMedicine),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(8.0),
        itemCount: _medicine.batches.length,
        itemBuilder: (context, index) {
          final batch = _medicine.batches[index];
          final mfgDate = DateFormat('yyyy-MM-dd').format(batch.manufactureDate);
          final expDate = DateFormat('yyyy-MM-dd').format(batch.expiryDate);

          return Card(
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Batch: ${batch.batchNumber}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const Divider(),
                  Text('Quantity: ${batch.quantity}'),
                  Text('Price: \$${batch.price.toStringAsFixed(2)}'),
                  Text('Variant: ${batch.variant}'),
                  Text('MFG Date: $mfgDate'),
                  Text('EXP Date: $expDate'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _deleteBatch(batch.batchNumber)),
                      IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _updateBatchQuantity(batch)),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
