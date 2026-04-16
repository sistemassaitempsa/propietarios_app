import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'api_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _towerController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isRegisterMode = false;
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _availableUnits = [];
  int? _selectedUnitId;

  @override
  void initState() {
    super.initState();
    _fetchUnits();
  }

  Future<void> _fetchUnits() async {
    // Try to get units from API
    final units = await _apiService.getUnits();
    if (units.isNotEmpty) {
      await _dbHelper.saveUnits(units);
    }
    
    // Load from local DB
    final localUnits = await _dbHelper.getUnits();
    setState(() {
      _availableUnits = localUnits;
    });
  }

  void _login() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMsg('Por favor, completa todos los campos');
      return;
    }

    bool success = await _dbHelper.loginUser(email, password);
    if (success) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => HomePage(userEmail: email)),
      );
    } else {
      _showMsg('Correo o contraseña incorrectos');
    }
  }

  void _register() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty || _firstNameController.text.isEmpty || _lastNameController.text.isEmpty) {
      _showMsg('Nombre, apellido, correo y contraseña son obligatorios');
      return;
    }

    if (_selectedUnitId == null) {
      _showMsg('Debes seleccionar una unidad');
      return;
    }

    int result = await _dbHelper.registerUser(
      email, 
      password,
      {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'phone': _phoneController.text,
        'tower': _towerController.text,
        'apartment': _apartmentController.text,
        'unit_id': _selectedUnitId,
      },
    );

    if (result != -1) {
      _showMsg('Usuario registrado con éxito');
      setState(() => _isRegisterMode = false);
    } else {
      _showMsg('El correo ya está registrado');
    }
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(_isRegisterMode ? 'Crear Cuenta' : 'Bienvenido'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Colors.indigo, Colors.blueAccent]),
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: Colors.indigo.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 5))
                  ],
                ),
                child: const Icon(Icons.home_work, size: 60, color: Colors.white),
              ),
              const SizedBox(height: 10),
              const Text('Residencial App', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.indigo)),
              const SizedBox(height: 20),

              if (_isRegisterMode) ...[
                _buildTextField(_firstNameController, 'Nombres', Icons.person),
                const SizedBox(height: 16),
                _buildTextField(_lastNameController, 'Apellidos', Icons.person_outline),
                const SizedBox(height: 16),
                _buildTextField(_phoneController, 'Número de Celular', Icons.phone, type: TextInputType.phone),
                const SizedBox(height: 16),
              ],
              
              _buildTextField(_emailController, 'Correo Electrónico', Icons.email, type: TextInputType.emailAddress),
              const SizedBox(height: 16),
              _buildPasswordField(),
              
              if (_isRegisterMode) ...[
                const SizedBox(height: 16),
                DropdownButtonFormField<int>(
                  value: _selectedUnitId,
                  decoration: InputDecoration(
                    labelText: 'Unidad/Conjunto',
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    prefixIcon: const Icon(Icons.business, color: Colors.indigo),
                  ),
                  items: _availableUnits.map((unit) {
                    return DropdownMenuItem<int>(
                      value: unit['id'],
                      child: Text(unit['name']),
                    );
                  }).toList(),
                  onChanged: (val) => setState(() => _selectedUnitId = val),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(child: _buildTextField(_towerController, 'Torre', Icons.apartment)),
                    const SizedBox(width: 10),
                    Expanded(child: _buildTextField(_apartmentController, 'Apartamento', Icons.door_front_door)),
                  ],
                ),
                const SizedBox(height: 10),
                const Text('* Contactos de emergencia se agregan en el perfil', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
              
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: _isRegisterMode ? _register : _login,
                  child: Text(_isRegisterMode ? 'REGISTRARSE' : 'INICIAR SESIÓN', 
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 15),
              TextButton(
                onPressed: () => setState(() => _isRegisterMode = !_isRegisterMode),
                child: Text(_isRegisterMode ? '¿Ya tienes cuenta? Inicia sesión' : '¿No tienes cuenta? Regístrate aquí'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: Icon(icon, color: Colors.indigo),
        contentPadding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10),
      ),
      keyboardType: type,
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        prefixIcon: const Icon(Icons.lock, color: Colors.indigo),
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.indigo[300]),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
    );
  }
}
