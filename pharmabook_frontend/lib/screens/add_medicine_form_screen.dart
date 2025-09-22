import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class AddMedicineFormScreen extends StatefulWidget {
  const AddMedicineFormScreen({super.key});

  @override
  State<AddMedicineFormScreen> createState() => _AddMedicineFormScreenState();
}

class _AddMedicineFormScreenState extends State<AddMedicineFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _companyController = TextEditingController();
  final _batchController = TextEditingController();
  final _quantityController = TextEditingController();
  final _variantController = TextEditingController();
  final _priceController = TextEditingController();
  final _mfgDateController = TextEditingController();
  final _expDateController = TextEditingController();
  final _tabletsPerStripController = TextEditingController();

  DateTime? _manufactureDate;
  DateTime? _expiryDate;
  bool _isStripBased = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _batchController.dispose();
    _quantityController.dispose();
    _variantController.dispose();
    _priceController.dispose();
    _mfgDateController.dispose();
    _expDateController.dispose();
    _tabletsPerStripController.dispose();
    super.dispose();
  }

  Future<void> _pickDate(BuildContext context, bool isMfg) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (pickedDate != null) {
      setState(() {
        if (isMfg) {
          _manufactureDate = pickedDate;
          _mfgDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
        } else {
          _expiryDate = pickedDate;
          _expDateController.text = DateFormat('yyyy-MM-dd').format(pickedDate);
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    if (_manufactureDate == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select both manufacture and expiry dates')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final apiService = ApiService(Provider.of<AuthService>(context, listen: false));

    final data = {
      'name': _nameController.text.trim(),
      'company': _companyController.text.trim(),
      'batchNumber': _batchController.text.trim(),
      'quantity': int.parse(_quantityController.text.trim()),
      'manufactureDate': _manufactureDate!.toIso8601String(),
      'expiryDate': _expiryDate!.toIso8601String(),
      'variant': _variantController.text.trim(),
      'price': double.parse(_priceController.text.trim()),
      'isStripBased': _isStripBased,
      'tabletsPerStrip': _isStripBased ? int.parse(_tabletsPerStripController.text.trim()) : 0,
    };

    try {
      await apiService.addMedicine(data);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Medicine added successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to trigger refresh in billing
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to add medicine: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add New Medicine')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Medicine Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Please enter a name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _companyController,
              decoration: const InputDecoration(
                labelText: 'Company Name',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Please enter a company name' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _batchController,
              decoration: const InputDecoration(
                labelText: 'Batch Number',
                border: OutlineInputBorder(),
              ),
              validator: (value) => value!.isEmpty ? 'Please enter a batch number' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value!.isEmpty) return 'Please enter a quantity';
                if (int.tryParse(value) == null) return 'Please enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(
                labelText: 'Price',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              validator: (value) {
                if (value!.isEmpty) return 'Please enter a price';
                if (double.tryParse(value) == null) return 'Please enter a valid number';
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _variantController,
              decoration: const InputDecoration(
                labelText: 'Variant',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text('Is Strip Based?'),
                Switch(
                  value: _isStripBased,
                  onChanged: (val) => setState(() => _isStripBased = val),
                ),
              ],
            ),
            if (_isStripBased)
              Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: TextFormField(
                  controller: _tabletsPerStripController,
                  decoration: const InputDecoration(
                    labelText: 'Tablets per Strip',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (_isStripBased && (value!.isEmpty || int.tryParse(value) == null)) {
                      return 'Please enter valid tablets per strip';
                    }
                    return null;
                  },
                ),
              ),
            TextFormField(
              controller: _mfgDateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Manufacture Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () => _pickDate(context, true),
              validator: (value) => value!.isEmpty ? 'Please select a date' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _expDateController,
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Expiry Date',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              onTap: () => _pickDate(context, false),
              validator: (value) => value!.isEmpty ? 'Please select a date' : null,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(50)),
              onPressed: _isSubmitting ? null : _submitForm,
              child: _isSubmitting
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Save Medicine'),
            ),
          ],
        ),
      ),
    );
  }
}
