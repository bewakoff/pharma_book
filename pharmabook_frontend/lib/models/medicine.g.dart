// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'medicine.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Batch _$BatchFromJson(Map<String, dynamic> json) => Batch(
  batchNumber: json['batchNumber'] as String,
  quantity: (json['quantity'] as num).toInt(),
  manufactureDate: DateTime.parse(json['manufactureDate'] as String),
  expiryDate: DateTime.parse(json['expiryDate'] as String),
  variant: json['variant'] as String?,
  price: (json['price'] as num?)?.toDouble() ?? 0.0,
);

Map<String, dynamic> _$BatchToJson(Batch instance) => <String, dynamic>{
  'batchNumber': instance.batchNumber,
  'quantity': instance.quantity,
  'manufactureDate': instance.manufactureDate.toIso8601String(),
  'expiryDate': instance.expiryDate.toIso8601String(),
  'variant': instance.variant,
  'price': instance.price,
};

Medicine _$MedicineFromJson(Map<String, dynamic> json) => Medicine(
  id: json['_id'] as String,
  name: json['name'] as String,
  company: json['company'] as String,
  batches: (json['batches'] as List<dynamic>)
      .map((e) => Batch.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$MedicineToJson(Medicine instance) => <String, dynamic>{
  '_id': instance.id,
  'name': instance.name,
  'company': instance.company,
  'batches': instance.batches,
};
