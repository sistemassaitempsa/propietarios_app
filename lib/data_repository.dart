import 'api_service.dart';
import 'database_helper.dart';

class DataRepository {
  final ApiService _apiService = ApiService();
  final DatabaseHelper _dbHelper = DatabaseHelper();

  // --- Usuarios ---

  Future<Map<String, dynamic>?> login(String email, String password) async {
    // 1. Intentar login en la API
    final apiResponse = await _apiService.loginUser(email, password);
    
    if (apiResponse != null) {
      // 2. Si la API devuelve un token, guardarlo automáticamente
      if (apiResponse.containsKey('token')) {
        await _apiService.saveToken(apiResponse['token']);
      } else if (apiResponse.containsKey('access_token')) {
        await _apiService.saveToken(apiResponse['access_token']);
      }

      // 3. Sincronizar con la BD local
      final localUser = await _dbHelper.getUser(email);
      
      if (localUser == null) {
        await _dbHelper.registerUser(email, password, apiResponse);
      } else {
        await _dbHelper.updateUser(email, apiResponse);
      }
      return apiResponse;
    }
    
    // 3. Fallback a local si la API falla
    final isLocalValid = await _dbHelper.loginUser(email, password);
    if (isLocalValid) {
      return await _dbHelper.getUser(email);
    }
    
    return null;
  }

  Future<bool> register(String email, String password, Map<String, dynamic> userData) async {
    // 1. Registrar en API
    final apiResult = await _apiService.registerUser({'email': email, 'password': password, ...userData});
    
    if (apiResult != null) {
      // 2. Guardar en local
      await _dbHelper.registerUser(email, password, userData);
      return true;
    }
    return false;
  }

  Future<bool> updateProfile(int userId, String email, Map<String, dynamic> data) async {
    // 1. Actualizar en API
    final success = await _apiService.updateUser(userId, data);
    
    if (success) {
      // 2. Actualizar localmente
      await _dbHelper.updateUser(email, data);
      return true;
    }
    return false;
  }

  // --- Vehículos ---

  Future<bool> addVehicle(int userId, Map<String, dynamic> vehicleData) async {
    // 1. Agregar a API
    final success = await _apiService.addVehicle({'user_id': userId, ...vehicleData});
    
    if (success) {
      // 2. Agregar a local
      await _dbHelper.addVehicle(userId, vehicleData);
      return true;
    }
    return false;
  }

  Future<List<Map<String, dynamic>>> getVehicles(int userId) async {
    final apiVehicles = await _apiService.getVehicles(userId);
    
    if (apiVehicles.isNotEmpty) {
      // Aquí podrías implementar una lógica de sincronización más compleja.
      // Por ahora devolvemos la API, pero en una app real actualizarías la BD local.
      return List<Map<String, dynamic>>.from(apiVehicles);
    }
    
    return await _dbHelper.getVehiclesWithContacts(userId);
  }

  // --- Contactos de Emergencia ---

  Future<bool> addEmergencyContact(int userId, String name, String phone, bool hasWhatsapp) async {
    final success = await _apiService.addEmergencyContact({
      'user_id': userId,
      'name': name,
      'phone': phone,
      'has_whatsapp': hasWhatsapp ? 1 : 0
    });

    if (success) {
      await _dbHelper.addEmergencyContact(userId, name, phone, hasWhatsapp);
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    await _apiService.clearToken();
    // Los datos locales se mantienen según requerimiento.
  }
}
