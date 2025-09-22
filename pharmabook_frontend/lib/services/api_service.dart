import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/medicine.dart';
import 'auth_service.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:3000/api';
  final AuthService authService;

  ApiService(this.authService);

  Future<List<Medicine>> getMedicines() async {
    if (!authService.isAuthenticated) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/medicines'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': authService.token!,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Medicine.fromJson(json)).toList();
      } else {
        if (kDebugMode) {
          print('Failed to load medicines: ${response.statusCode}');
        }
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching medicines: $e');
      return [];
    }
  }

  Future<void> addMedicine(Map<String, dynamic> data) async {
    if (!authService.isAuthenticated) throw Exception('Not authenticated');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/medicines'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': authService.token!,
        },
        body: json.encode(data),
      );

      if (response.statusCode != 201) {
        throw Exception(
            'Failed to add medicine: ${json.decode(response.body)['message']}');
      }
    } catch (e) {
      if (kDebugMode) print('Error adding medicine: $e');
      rethrow;
    }
  }

  Future<void> updateBatch(String medicineId, String batchNumber, int newQuantity) async {
    if (!authService.isAuthenticated) throw Exception('Not authenticated');

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/medicines/$medicineId/$batchNumber'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': authService.token!,
        },
        body: json.encode({'quantity': newQuantity}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update batch');
      }
    } catch (e) {
      if (kDebugMode) print('Error updating batch: $e');
      rethrow;
    }
  }

  Future<void> deleteBatch(String medicineId, String batchNumber) async {
    if (!authService.isAuthenticated) throw Exception('Not authenticated');

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/medicines/$medicineId/$batchNumber'),
        headers: {'x-auth-token': authService.token!},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete batch');
      }
    } catch (e) {
      if (kDebugMode) print('Error deleting batch: $e');
      rethrow;
    }
  }

  Future<void> deleteMedicine(String medicineId) async {
    if (!authService.isAuthenticated) throw Exception('Not authenticated');

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/medicines/$medicineId'),
        headers: {'x-auth-token': authService.token!},
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to delete medicine');
      }
    } catch (e) {
      if (kDebugMode) print('Error deleting medicine: $e');
      rethrow;
    }
  }

  Future<List<Medicine>> getDailyReport() async {
    if (!authService.isAuthenticated) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reports/daily'),
        headers: {'x-auth-token': authService.token!},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Medicine.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching daily report: $e');
      return [];
    }
  }

  Future<List<Medicine>> getWeeklyReport() async {
    if (!authService.isAuthenticated) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reports/weekly'),
        headers: {'x-auth-token': authService.token!},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Medicine.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching weekly report: $e');
      return [];
    }
  }

  Future<List<Medicine>> getMonthlyReport() async {
    if (!authService.isAuthenticated) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/reports/monthly'),
        headers: {'x-auth-token': authService.token!},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Medicine.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching monthly report: $e');
      return [];
    }
  }

  Future<List<Medicine>> getExpiringMedicines() async {
    if (!authService.isAuthenticated) return [];

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/medicines/expiring'),
        headers: {'x-auth-token': authService.token!},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Medicine.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching expiring medicines: $e');
      return [];
    }
  }

  Future<void> createBill(Map<String, dynamic> billData) async {
    if (!authService.isAuthenticated) throw Exception('Not authenticated');

    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/bills'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': authService.token!,
        },
        body: json.encode(billData),
      );

      if (response.statusCode != 201) {
        final errorBody = json.decode(response.body);
        throw Exception('Failed to create bill: ${errorBody['msg']}');
      }
    } catch (e) {
      if (kDebugMode) print('Error creating bill: $e');
      rethrow;
    }
  }
}