import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  final String baseUrl = "https://tu-api.com/api"; // Reemplaza con tu URL real

  // --- Manejo del Token ---

  Future<Map<String, String>> _getHeaders() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    
    final headers = {'Content-Type': 'application/json'};
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
  }

  Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
  }

  // --- Usuarios (Users) ---

  Future<Map<String, dynamic>?> registerUser(Map<String, dynamic> userData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/register'),
        headers: headers,
        body: jsonEncode(userData),
      );
      return response.statusCode == 201 ? jsonDecode(response.body) : null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> loginUser(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/users/login'),
        headers: {'Content-Type': 'application/json'}, // Sin token para login
        body: jsonEncode({'email': email, 'password': password}),
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : null;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getUserProfile(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(Uri.parse('$baseUrl/users/$userId'), headers: headers);
      return response.statusCode == 200 ? jsonDecode(response.body) : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> updateUser(int userId, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId'),
        headers: headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- Contactos de Emergencia ---

  Future<List<dynamic>> getEmergencyContacts(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/emergency-contacts?user_id=$userId'),
        headers: headers
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addEmergencyContact(Map<String, dynamic> contactData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/emergency-contacts'),
        headers: headers,
        body: jsonEncode(contactData),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  // --- Vehículos ---

  Future<List<dynamic>> getVehicles(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/vehicles?user_id=$userId'),
        headers: headers
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  Future<bool> addVehicle(Map<String, dynamic> vehicleData) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/vehicles'),
        headers: headers,
        body: jsonEncode(vehicleData),
      );
      return response.statusCode == 201;
    } catch (e) {
      return false;
    }
  }

  Future<Map<String, dynamic>?> searchByPlate(String plate, {int? userId}) async {
    try {
      final headers = await _getHeaders();
      String url = '$baseUrl/search/plate/$plate';
      if (userId != null) {
        url += '?user_id=$userId';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : null;
    } catch (e) {
      return null;
    }
  }

  // --- Permisos y Sincronización ---

  Future<Map<String, dynamic>?> getMyProfile() async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/auth/me'),
        headers: headers,
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> toggleUserHistory(int userId, bool enabled) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/toggle-history'),
        headers: headers,
        body: jsonEncode({'enabled': enabled}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleUserActive(int userId, bool active) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/toggle-active'),
        headers: headers,
        body: jsonEncode({'active': active}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<bool> toggleUnitHistory(int unitId, bool enabled) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/units/$unitId/toggle-history'),
        headers: headers,
        body: jsonEncode({'enabled': enabled}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  Future<List<dynamic>> getAllUsers({String? name, String? unit, String? plate}) async {
    try {
      final headers = await _getHeaders();
      String url = '$baseUrl/admin/users?';
      if (name != null && name.isNotEmpty) url += 'name=${Uri.encodeComponent(name)}&';
      if (unit != null && unit.isNotEmpty) url += 'unit=${Uri.encodeComponent(unit)}&';
      if (plate != null && plate.isNotEmpty) url += 'plate=${Uri.encodeComponent(plate)}&';

      final response = await http.get(
        Uri.parse('$baseUrl/search/plate/$plate'),
        headers: headers
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getAllUnits({String? name}) async {
    try {
      final headers = await _getHeaders();
      String url = '$baseUrl/units';
      if (name != null && name.isNotEmpty) {
        url += '?name=${Uri.encodeComponent(name)}';
      }
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> updateUnit(int id, Map<String, dynamic> data) async {
    try {
      final headers = await _getHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/units/$id'),
        headers: headers,
        body: jsonEncode(data),
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : null;
    } catch (e) {
      return null;
    }
  }

  Future<bool> toggleUserAdmin(int userId, bool isAdmin) async {
    try {
      final headers = await _getHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/users/$userId/toggle-admin'),
        headers: headers,
        body: jsonEncode({'is_admin': isAdmin}),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // --- Historial de Consultas ---

  Future<List<dynamic>> getMyConsultations(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/consultations/my?user_id=$userId'),
        headers: headers,
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }

  Future<List<dynamic>> getOthersConsultations(int userId) async {
    try {
      final headers = await _getHeaders();
      final response = await http.get(
        Uri.parse('$baseUrl/consultations/others?user_id=$userId'),
        headers: headers,
      );
      return response.statusCode == 200 ? jsonDecode(response.body) : [];
    } catch (e) {
      return [];
    }
  }
}
