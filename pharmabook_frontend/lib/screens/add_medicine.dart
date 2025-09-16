import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/api_service.dart';

class AddMedicineScreen extends StatefulWidget {
  const AddMedicineScreen({super.key});

  @override
  State<AddMedicineScreen> createState() => _AddMedicineScreenState();
}

class _AddMedicineScreenState extends State<AddMedicineScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _quantityController = TextEditingController();
  final TextEditingController _batchController = TextEditingController();
  final TextEditingController _mfgController = TextEditingController();
  final TextEditingController _expiryController = TextEditingController();

  DateTime? _manufactureDate;
  DateTime? _expiryDate;
  bool _isSubmitting = false;

  Future<void> _pickDate(bool isMfg) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked != null) {
      setState(() {
        if (isMfg) {
          _manufactureDate = picked;
          _mfgController.text = DateFormat('yyyy-MM-dd').format(picked);
        } else {
          _expiryDate = picked;
          _expiryController.text = DateFormat('yyyy-MM-dd').format(picked);
        }
      });
    }
  }

  Future<void> _submitMedicine() async {
    if (!_formKey.currentState!.validate()) return;
    if (_manufactureDate == null || _expiryDate == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("❌ Please select both dates")),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final medicineData = {
      'name': _nameController.text.trim(),
      'company': _companyController.text.trim(),
      'batchNumber': _batchController.text.trim(),
      'quantity': int.parse(_quantityController.text.trim()),
      'manufactureDate': _manufactureDate!.toIso8601String(),
      'expiryDate': _expiryDate!.toIso8601String(),
    };

    try {
      await ApiService.addMedicine(context, medicineData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Medicine added successfully")),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("❌ Failed to add medicine: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _companyController.dispose();
    _quantityController.dispose();
    _batchController.dispose();
    _mfgController.dispose();
    _expiryController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Add New Medicine")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
              _buildTextField(_nameController, "Medicine Name", "e.g., Paracetamol 500mg"),
              const SizedBox(height: 16),
              _buildTextField(_companyController, "Company Name", "e.g., ParaCare Labs"),
              const SizedBox(height: 16),
              _buildTextField(
                _quantityController,
                "Quantity",
                "e.g., 100",
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value!.isEmpty) return "Enter quantity";
                  if (int.tryParse(value) == null) return "Enter a valid number";
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(_batchController, "Batch Number", "e.g., ABC123DEF"),
              const SizedBox(height: 16),
              _buildDateField(_mfgController, "Manufacture Date", true),
              const SizedBox(height: 16),
              _buildDateField(_expiryController, "Expiry Date", false),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submitMedicine,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: _isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text("Add New Medicine", style: TextStyle(fontSize: 18)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(
    TextEditingController controller,
    String label,
    String hint, {
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
      ),
      keyboardType: keyboardType,
      validator: validator ?? (value) => value!.isEmpty ? "Enter $label" : null,
    );
  }

  Widget _buildDateField(TextEditingController controller, String label, bool isMfg) {
    return TextFormField(
      controller: controller,
      readOnly: true,
      onTap: () => _pickDate(isMfg),
      decoration: InputDecoration(
        labelText: label,
        hintText: "yyyy-MM-dd",
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        suffixIcon: const Icon(Icons.calendar_today),
      ),
      validator: (value) => value!.isEmpty ? "Select $label" : null,
    );
  }
}
