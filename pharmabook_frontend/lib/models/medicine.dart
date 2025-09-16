import 'package:json_annotation/json_annotation.dart';

part 'medicine.g.dart';

@JsonSerializable()
class Batch {
  final String batchNumber;
  final int quantity;
  final DateTime manufactureDate;
  final DateTime expiryDate;
  final String? variant;
  final double price;

  const Batch({
    required this.batchNumber,
    required this.quantity,
    required this.manufactureDate,
    required this.expiryDate,
    this.variant,
    this.price = 0.0,
  });

  factory Batch.fromJson(Map<String, dynamic> json) => _$BatchFromJson(json);
  Map<String, dynamic> toJson() => _$BatchToJson(this);
}

@JsonSerializable()
class Medicine {
  @JsonKey(name: '_id')
  final String id;
  final String name;
  final String company;
  final List<Batch> batches;

  Medicine({
    required this.id,
    required this.name,
    required this.company,
    required this.batches,
  });

  factory Medicine.fromJson(Map<String, dynamic> json) => _$MedicineFromJson(json);
  Map<String, dynamic> toJson() => _$MedicineToJson(this);
}
