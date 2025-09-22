import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import '../services/api_service.dart';
import '../services/auth_service.dart';

class BillItem {
  final String medicineId;
  final String medicineName;
  final String batchNumber;
  final DateTime expiryDate;
  int quantity; 
  final double price;
  final bool isStripBased;
  final int tabletsPerStrip;

  BillItem({
    required this.medicineId,
    required this.medicineName,
    required this.batchNumber,
    required this.expiryDate,
    required this.quantity,
    required this.price,
    required this.isStripBased,
    required this.tabletsPerStrip,
  });

  double get totalPrice => isStripBased ? (price / tabletsPerStrip) * quantity : price * quantity;
}

class BillingScreen extends StatefulWidget {
  const BillingScreen({super.key});

  @override
  State<BillingScreen> createState() => _BillingScreenState();
}

class _BillingScreenState extends State<BillingScreen> {
  final _customerNameController = TextEditingController();
  final _quantityController = TextEditingController(text: '1');
  final List<BillItem> _billItems = [];
  late ApiService apiService;
  late Future<List<Medicine>> _medicinesFuture;
  Medicine? _selectedMedicine;
  Batch? _selectedBatch;
  double _totalAmount = 0.0;
  bool _isSubmitting = false;

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

  void _calculateTotal() {
    _totalAmount = _billItems.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  void _resetInputFields() {
    _selectedMedicine = null;
    _selectedBatch = null;
    _quantityController.text = '1';
  }

  void _addBillItem() {
    if (_selectedMedicine == null || _selectedBatch == null) return;
    final quantity = int.tryParse(_quantityController.text) ?? 0;
    if (quantity <= 0) return;
    if (quantity > _selectedBatch!.quantity) return;

    setState(() {
      final existingIndex = _billItems.indexWhere((item) => item.batchNumber == _selectedBatch!.batchNumber);

      if (existingIndex != -1) {
        _billItems[existingIndex].quantity += quantity;
      } else {
        _billItems.add(BillItem(
          medicineId: _selectedMedicine!.id,
          medicineName: _selectedMedicine!.name,
          batchNumber: _selectedBatch!.batchNumber,
          expiryDate: _selectedBatch!.expiryDate,
          quantity: quantity,
          price: _selectedBatch!.price,
          isStripBased: _selectedBatch!.isStripBased,
          tabletsPerStrip: _selectedBatch!.tabletsPerStrip,
        ));
      }

      _calculateTotal();
      _resetInputFields();
    });
  }

  void _removeBillItem(int index) {
    setState(() {
      _billItems.removeAt(index);
      _calculateTotal();
    });
  }

  Future<void> _submitBill() async {
    if (_customerNameController.text.isEmpty || _billItems.isEmpty) return;

    setState(() => _isSubmitting = true);

    final billData = {
      'customerName': _customerNameController.text.trim(),
      'items': _billItems.map((item) => {
            'medicineId': item.medicineId,
            'batchNumber': item.batchNumber,
            'quantity': item.quantity,
            'price': item.price,
          }).toList(),
    };

    try {
      await apiService.createBill(billData);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Bill created successfully!')),
        );
        setState(() {
          _billItems.clear();
          _customerNameController.clear();
          _totalAmount = 0.0;
          _loadMedicines();
        });
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error creating bill: $e')));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Billing'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            TextField(
              controller: _customerNameController,
              decoration: InputDecoration(
                labelText: 'Customer Name',
                border: const OutlineInputBorder(),
                suffixIcon: Text(DateFormat('yyyy-MM-dd').format(DateTime.now())),
              ),
            ),
            const SizedBox(height: 16),
            _buildItemEntry(),
            const Divider(height: 32),
            _buildBillItemsList(),
            _buildSummary(),
          ],
        ),
      ),
    );
  }

  Widget _buildItemEntry() {
    return FutureBuilder<List<Medicine>>(
      future: _medicinesFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (!snapshot.hasData || snapshot.data!.isEmpty) return const Text('No medicines in inventory.');

        final medicines = snapshot.data!;
        return Column(
          children: [
            DropdownButtonFormField<Medicine>(
              value: _selectedMedicine,
              hint: const Text('Select Medicine'),
              isExpanded: true,
              items: medicines.map((med) => DropdownMenuItem(value: med, child: Text(med.name))).toList(),
              onChanged: (value) => setState(() { _selectedMedicine = value; _selectedBatch = null; }),
            ),
            const SizedBox(height: 8),
            if (_selectedMedicine != null)
              DropdownButtonFormField<Batch>(
                value: _selectedBatch,
                hint: const Text('Select Batch'),
                isExpanded: true,
                items: _selectedMedicine!.batches.where((b) => b.quantity > 0).map((batch) {
                  return DropdownMenuItem(
                    value: batch,
                    child: Text('${batch.batchNumber} - Stock: ${batch.quantity} - \$${batch.price.toStringAsFixed(2)}'),
                  );
                }).toList(),
                onChanged: (value) => setState(() => _selectedBatch = value),
              ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _quantityController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                ),
                const SizedBox(width: 16),
                ElevatedButton.icon(
                  onPressed: _addBillItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Add'),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildBillItemsList() {
    return Expanded(
      child: ListView.builder(
        itemCount: _billItems.length,
        itemBuilder: (context, index) {
          final item = _billItems[index];
          return Card(
            child: ListTile(
              title: Text(item.medicineName),
              subtitle: Text(
                  'Batch: ${item.batchNumber} | Qty: ${item.quantity}${item.isStripBased ? ' strips (${item.quantity * item.tabletsPerStrip} tablets)' : ''} x \$${item.price.toStringAsFixed(2)}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('\$${item.totalPrice.toStringAsFixed(2)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: () => _removeBillItem(index)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummary() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total: \$${_totalAmount.toStringAsFixed(2)}', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          ElevatedButton(
            onPressed: _isSubmitting ? null : _submitBill,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: _isSubmitting ? const CircularProgressIndicator(color: Colors.white) : const Text('Submit Bill'),
          ),
        ],
      ),
    );
  }
}
