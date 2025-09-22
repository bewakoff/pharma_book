import 'package:json_annotation/json_annotation.dart';
part 'medicine.g.dart';

@JsonSerializable()
class Medicine {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String company;
  final List<Batch> batches;

  Medicine({required this.id, required this.name, required this.company, required this.batches});

  factory Medicine.fromJson(Map<String, dynamic> json) => _$MedicineFromJson(json);
  Map<String, dynamic> toJson() => _$MedicineToJson(this);
}

@JsonSerializable()
class Batch {
  final String batchNumber;
  final DateTime manufactureDate;
  final DateTime expiryDate;
  int quantity;
  final String? variant;
  final double price;
  final bool isStripBased;
  final int tabletsPerStrip;

  Batch({
    required this.batchNumber,
    required this.manufactureDate,
    required this.expiryDate,
    required this.quantity,
    this.variant,
    required this.price,
    this.isStripBased = false,
    this.tabletsPerStrip = 0,
  });

  factory Batch.fromJson(Map<String, dynamic> json) => _$BatchFromJson(json);
  Map<String, dynamic> toJson() => _$BatchToJson(this);
}
