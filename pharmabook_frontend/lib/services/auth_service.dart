import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class User {
  final String id;
  String name;
  final String email;

  User({required this.id, required this.name, required this.email});
}

class AuthService extends ChangeNotifier {
  String? _token;
  String? _userId;
  String? _role;
  String? _enterpriseName;
  User? _currentUser;

  final String _baseUrl = 'http://localhost:3000/api/auth';

  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get userId => _userId;
  String? get role => _role;
  String? get enterpriseName => _enterpriseName;
  User? get currentUser => _currentUser;

  AuthService() {
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('token');
    _userId = prefs.getString('userId');
    _role = prefs.getString('role');
    _enterpriseName = prefs.getString('enterpriseName');

    if (_token != null && _userId != null) {
      await fetchCurrentUser();
    }

    if (_token != null) notifyListeners();
  }

  Future<void> login(String email, String password) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/login'),
    headers: {'Content-Type': 'application/json'},
    body: json.encode({'email': email, 'password': password}),
  );

  if (response.statusCode == 200) {
    final data = json.decode(response.body);
    _token = data['token'];
    _userId = data['userId'];
    _role = data['role'];
    _enterpriseName = data['enterpriseName'];

    _currentUser = User(
      id: _userId!,
      name: '', // backend doesn’t return name yet
      email: data['email'],
    );

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', _token!);
    await prefs.setString('userId', _userId!);
    await prefs.setString('role', _role ?? 'user');
    await prefs.setString('enterpriseName', _enterpriseName ?? '');

    notifyListeners();
  } else {
    throw Exception('Failed to login: ${json.decode(response.body)['message']}');
  }
}


  Future<void> signup(String email, String password, String enterpriseName) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/signup'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'email': email,
        'password': password,
        'enterpriseName': enterpriseName,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to sign up: ${json.decode(response.body)['message']}');
    }
  }

  Future<void> forgotPassword(String email) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/forgot-password'),
      headers: {'Content-Type': 'application/json'},
      body: json.encode({'email': email}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send reset link: ${json.decode(response.body)['message']}');
    }
  }

  Future<void> logout() async {
    _token = null;
    _userId = null;
    _role = null;
    _enterpriseName = null;
    _currentUser = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // A more robust way to clear all auth data

    notifyListeners();
  }

  Future<void> fetchCurrentUser() async {
    if (_token == null || _userId == null) return;

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/user/$_userId'),
        headers: {'x-auth-token': _token!},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _currentUser = User(
          id: data['id'],
          name: data['name'],
          email: data['email'],
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Failed to fetch current user: $e');
    }
  }

  Future<String> updateName(String newName) async {
    if (_token == null || _userId == null) {
      return 'User not authenticated.';
    }

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/user/$_userId'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': _token!,
        },
        body: json.encode({'name': newName}),
      );

      if (response.statusCode == 200) {
        _currentUser?.name = newName;
        notifyListeners();
        return 'Name updated successfully';
      } else {
        return 'Failed to update name: ${response.body}';
      }
    } catch (e) {
      return 'An error occurred: $e';
    }
  }

  Future<String> changePassword(String oldPassword, String newPassword) async {
    if (_token == null || _userId == null) {
      return 'User not authenticated.';
    }

    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/user/$_userId/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'x-auth-token': _token!,
        },
        body: json.encode({'oldPassword': oldPassword, 'newPassword': newPassword}),
      );

      if (response.statusCode == 200) {
        return 'Password changed successfully';
      } else {
        return 'Failed to change password: ${response.body}';
      }
    } catch (e) {
      return 'An error occurred: $e';
    }
  }
}