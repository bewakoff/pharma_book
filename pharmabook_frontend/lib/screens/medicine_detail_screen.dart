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

  // DIALOG FOR ADDING A NEW BATCH
  Future<void> _showAddBatchDialog() async {
    final formKey = GlobalKey<FormState>();
    final batchController = TextEditingController();
    final quantityController = TextEditingController();
    final priceController = TextEditingController();
    final tabletsPerStripController = TextEditingController();
    DateTime? mfgDate;
    DateTime? expDate;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add New Batch to ${_medicine.name}'),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  TextFormField(
                    controller: batchController,
                    decoration: const InputDecoration(labelText: 'Batch Number'),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Quantity (in tablets)'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                   TextFormField(
                    controller: priceController,
                    decoration: const InputDecoration(labelText: 'Price per Strip'),
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  TextFormField(
                    controller: tabletsPerStripController,
                    decoration: const InputDecoration(labelText: 'Tablets per Strip'),
                    keyboardType: TextInputType.number,
                    validator: (value) => value!.isEmpty ? 'Required' : null,
                  ),
                  // Simple date pickers - you can replace with your preferred date picker
                  ElevatedButton(
                    onPressed: () async {
                      mfgDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                    },
                    child: const Text('Select Manufacture Date'),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      expDate = await showDatePicker(context: context, initialDate: DateTime.now(), firstDate: DateTime(2000), lastDate: DateTime(2100));
                    },
                    child: const Text('Select Expiry Date'),
                  ),
                ],
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Add Batch'),
              onPressed: () async {
                if (formKey.currentState!.validate() && mfgDate != null && expDate != null) {
                  final newBatchData = {
                    'name': _medicine.name,
                    'company': _medicine.company,
                    'batchNumber': batchController.text,
                    'quantity': int.parse(quantityController.text),
                    'price': double.parse(priceController.text),
                    'tabletsPerStrip': int.parse(tabletsPerStripController.text),
                    'manufactureDate': mfgDate!.toIso8601String(),
                    'expiryDate': expDate!.toIso8601String(),
                  };
                  try {
                    await apiService.addMedicine(newBatchData);
                    // Refresh the screen with the new batch
                    final updatedMedicine = await apiService.getMedicines();
                    setState(() {
                      _medicine = updatedMedicine.firstWhere((med) => med.id == _medicine.id);
                    });
                    if (mounted) {
                      Navigator.of(context).pop();
                       ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('New batch added!')),
                      );
                    }
                  } catch (e) {
                     if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Failed to add batch: $e')),
                      );
                    }
                  }
                }
              },
            ),
          ],
        );
      },
    );
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
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(),
          ),
          TextButton(
            child: const Text('Update'),
            onPressed: () => Navigator.of(context).pop(quantityController.text),
          ),
        ],
      ),
    );

    if (newQuantity != null && newQuantity.isNotEmpty) {
      try {
        await apiService.updateBatch(
          _medicine.id,
          batch.batchNumber,
          int.parse(newQuantity),
        );
        setState(() {
          batch.quantity = int.parse(newQuantity);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Batch updated successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to update batch: $e')),
          );
        }
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
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: const Text('Delete'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await apiService.deleteBatch(_medicine.id, batchNumber);
        setState(() {
          _medicine.batches.removeWhere((b) => b.batchNumber == batchNumber);
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Batch deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete batch: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteMedicine() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Medicine?'),
        content: Text('Are you sure you want to delete "${_medicine.name}" and all of its batches? This action cannot be undone.'),
        actions: [
          TextButton(
            child: const Text('Cancel'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
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
          Navigator.of(context).pop(true);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Medicine deleted successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to delete medicine: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_medicine.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            tooltip: 'Add New Batch',
            onPressed: _showAddBatchDialog,
          ),
          IconButton(
            icon: const Icon(Icons.delete_forever),
            tooltip: 'Delete Medicine',
            onPressed: _deleteMedicine,
          ),
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
                  Text('Quantity: ${batch.quantity} tablets'),
                  Text('Price: \$${batch.price.toStringAsFixed(2)} / strip'),
                  Text('Tablets per Strip: ${batch.tabletsPerStrip}'),
                  Text('Variant: ${batch.variant}'),
                  Text('MFG Date: $mfgDate'),
                  Text('EXP Date: $expDate'),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _deleteBatch(batch.batchNumber),
                        tooltip: 'Delete Batch',
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _updateBatchQuantity(batch),
                        tooltip: 'Update Quantity',
                      ),
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