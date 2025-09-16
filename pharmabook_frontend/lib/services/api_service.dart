import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import '../models/medicine.dart';
import 'auth_service.dart';

class ApiService {
  static const String _baseUrl = 'http://localhost:3000/api/medicines';

  /// Fetch all medicines
  static Future<List<Medicine>> getMedicines(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) return [];

    try {
      final response = await http.get(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': authService.token!,
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = json.decode(response.body);
        return jsonList.map((json) => Medicine.fromJson(json)).toList();
      } else {
        if (kDebugMode) print('Failed to load medicines: ${response.statusCode}');
        return [];
      }
    } catch (e) {
      if (kDebugMode) print('Error fetching medicines: $e');
      return [];
    }
  }

  /// Add a new medicine
  static Future<void> addMedicine(BuildContext context, Map<String, dynamic> data) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) throw Exception('Not authenticated');

    try {
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': authService.token!,
        },
        body: json.encode(data),
      );

      if (response.statusCode != 201) {
        throw Exception('Failed to add medicine: ${json.decode(response.body)['message']}');
      }
    } catch (e) {
      if (kDebugMode) print('Error adding medicine: $e');
      rethrow;
    }
  }

  /// Delete a batch
  static Future<void> deleteBatch(BuildContext context, String medicineId, String batchNumber) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) throw Exception('Not authenticated');

    try {
      final response = await http.delete(
        Uri.parse('$_baseUrl/$medicineId/$batchNumber'),
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

  /// Fetch daily report
  static Future<List<Medicine>> getDailyReport(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) return [];

    final userId = authService.userId; // Make sure AuthService stores userId
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/reports/daily?userId=$userId'),
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

  /// Fetch weekly report
  static Future<List<Medicine>> getWeeklyReport(BuildContext context) async {
    final authService = Provider.of<AuthService>(context, listen: false);
    if (!authService.isAuthenticated) return [];

    final userId = authService.userId; // Make sure AuthService stores userId
    try {
      final response = await http.get(
        Uri.parse('http://localhost:3000/api/reports/weekly?userId=$userId'),
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
}
