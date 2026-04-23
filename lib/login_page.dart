import 'package:flutter/material.dart';
import 'database_helper.dart';
import 'home_page.dart';
import 'search_page.dart';
import 'api_service.dart';
import 'data_repository.dart';

import 'package:flutter/gestures.dart';
import 'package:url_launcher/url_launcher.dart';

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
  final DataRepository _repository = DataRepository();

  bool _isLoadingUnits = false;
  List<Map<String, dynamic>> _availableUnits = [];
  int? _selectedUnitId;
  bool _isAcceptedTerms = false;

  @override
  void initState() {
    super.initState();
    _fetchUnits();
  }

  Future<void> _launchPolicy() async {
    final Uri url = Uri.parse('https://www.sic.gov.co/sobre-la-proteccion-de-datos-personales');
    if (!await launchUrl(url)) {
      _showMsg('No se pudo abrir el enlace');
    }
  }

  Future<void> _fetchUnits() async {
    setState(() => _isLoadingUnits = true);
    try {
      // Try to get units from API
      final units = await _apiService.getUnits();
      if (units.isNotEmpty) {
        await _dbHelper.saveUnits(units);
      }
      
      // Load from local DB
      final localUnits = await _dbHelper.getUnits();
      setState(() {
        _availableUnits = localUnits;
        _isLoadingUnits = false;
      });
    } catch (e) {
      print("Error al cargar unidades: $e");
      setState(() => _isLoadingUnits = false);
    }
  }

  void _login() async {
    String email = _emailController.text;
    String password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      _showMsg('Por favor, completa todos los campos');
      return;
    }

    try {
      final response = await _repository.login(email, password);
      if (response != null) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => HomePage(userEmail: email)),
        );
      } else {
        _showMsg('Correo o contraseña incorrectos');
      }
    } catch (e) {
      if (e.toString().contains('inactiva')) {
        _showInactiveAccountDialog();
      } else {
        _showMsg('Error al iniciar sesión: $e');
      }
    }
  }

  void _showInactiveAccountDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 10),
            Text('Cuenta Inactiva'),
          ],
        ),
        content: const Text(
          'Tu cuenta aún no ha sido activada.\n\nPor favor, contacta al propietario o a un residente actual de tu apartamento para que active tu cuenta desde su aplicación.',
          style: TextStyle(fontSize: 15),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('ENTENDIDO'),
          ),
        ],
      ),
    );
  }

  void _register() async {
    String email = _emailController.text;
    String password = _passwordController.text;
    String firstName = _firstNameController.text;
    String lastName = _lastNameController.text;

    if (email.isEmpty || password.isEmpty || firstName.isEmpty || lastName.isEmpty) {
      _showMsg('Nombre, apellido, correo y contraseña son obligatorios');
      return;
    }

    if (_selectedUnitId == null) {
      _showMsg('Debes seleccionar una unidad');
      return;
    }

    if (!_isAcceptedTerms) {
      _showMsg('Debes aceptar la política de tratamiento de datos personales');
      return;
    }

    // Preparar datos para la API (necesita 'name') y local
    Map<String, dynamic> userData = {
      'name': '$firstName $lastName',
      'firstName': firstName,
      'lastName': lastName,
      'phone': _phoneController.text,
      'tower': _towerController.text,
      'apartment': _apartmentController.text,
      'unit_id': _selectedUnitId,
    };

    bool success = await _repository.register(email, password, userData);

    if (success) {
      _showMsg('Usuario registrado con éxito en el servidor');
      setState(() {
        _isRegisterMode = false;
        _isAcceptedTerms = false; // Reset for next time
      });
    } else {
      _showMsg('Error al registrar usuario. Posiblemente el correo ya existe o falla de conexión.');
    }
  }

  Widget _buildTermsCheckbox() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          SizedBox(
            height: 24,
            width: 24,
            child: Checkbox(
              value: _isAcceptedTerms,
              activeColor: Colors.indigo,
              onChanged: (val) => setState(() => _isAcceptedTerms = val!),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: TextStyle(color: Colors.blueGrey[600], fontSize: 13),
                children: [
                  const TextSpan(text: 'Acepto la '),
                  TextSpan(
                    text: 'Política de Tratamiento de Datos Personales',
                    style: const TextStyle(
                      color: Colors.indigo,
                      fontWeight: FontWeight.bold,
                      decoration: TextDecoration.underline,
                    ),
                    recognizer: TapGestureRecognizer()..onTap = _launchPolicy,
                  ),
                  const TextSpan(text: ' según la regulación de Colombia.'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: label,
          labelStyle: TextStyle(color: Colors.blueGrey[400], fontSize: 14),
          prefixIcon: Icon(icon, color: Colors.indigo[400], size: 22),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          hintText: label,
          hintStyle: TextStyle(color: Colors.blueGrey[200], fontSize: 14),
        ),
      ),
    );
  }

  Widget _buildPasswordField() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _passwordController,
        obscureText: !_isPasswordVisible,
        style: const TextStyle(fontSize: 15),
        decoration: InputDecoration(
          labelText: 'Contraseña',
          labelStyle: TextStyle(color: Colors.blueGrey[400], fontSize: 14),
          prefixIcon: Icon(Icons.lock_outline_rounded, color: Colors.indigo[400], size: 22),
          suffixIcon: IconButton(
            icon: Icon(
              _isPasswordVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded,
              color: Colors.blueGrey[300],
              size: 20,
            ),
            onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
          floatingLabelBehavior: FloatingLabelBehavior.never,
          hintText: 'Contraseña',
          hintStyle: TextStyle(color: Colors.blueGrey[200], fontSize: 14),
        ),
      ),
    );
  }

  DropdownButtonFormField<int> _buildUnitDropdown() {
    return DropdownButtonFormField<int>(
      value: _selectedUnitId,
      icon: _isLoadingUnits 
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : Icon(Icons.keyboard_arrow_down_rounded, color: Colors.blueGrey[400]),
      decoration: InputDecoration(
        labelText: 'Unidad/Conjunto',
        labelStyle: TextStyle(color: Colors.blueGrey[400], fontSize: 14),
        filled: true,
        fillColor: Colors.white,
        prefixIcon: Icon(Icons.business_rounded, color: Colors.indigo[400], size: 22),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
      items: _availableUnits.isEmpty 
        ? [const DropdownMenuItem(value: null, child: Text('No hay unidades disponibles', style: TextStyle(color: Colors.red)))]
        : _availableUnits.map((unit) {
            return DropdownMenuItem<int>(
              value: unit['id'],
              child: Text(unit['name'], style: const TextStyle(fontSize: 15)),
            );
          }).toList(),
      onChanged: _isLoadingUnits ? null : (val) => setState(() => _selectedUnitId = val),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 30.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Header
                TweenAnimationBuilder(
                  duration: const Duration(milliseconds: 800),
                  tween: Tween<double>(begin: 0, end: 1),
                  builder: (context, double value, child) {
                    return Opacity(
                      opacity: value,
                      child: Transform.translate(
                        offset: Offset(0, 20 * (1 - value)),
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Container(
                        padding: const Offset(0, 0) == const Offset(0, 0) ? const EdgeInsets.all(20) : EdgeInsets.zero,
                        decoration: BoxDecoration(
                          color: Colors.indigo[50],
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.home_work_rounded, size: 50, color: Colors.indigo[600]),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _isRegisterMode ? 'Crear cuenta' : '¡Bienvenido de nuevo!',
                        style: const TextStyle(
                          fontSize: 28, 
                          fontWeight: FontWeight.bold, 
                          color: Color(0xFF1A237E),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _isRegisterMode 
                          ? 'Regístrate para gestionar tu residencia' 
                          : 'Ingresa tus credenciales para continuar',
                        style: TextStyle(fontSize: 15, color: Colors.blueGrey[400]),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),

                // Form
                if (_isRegisterMode) ...[
                  _buildTextField(_firstNameController, 'Nombres', Icons.person_outline_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(_lastNameController, 'Apellidos', Icons.person_outline_rounded),
                  const SizedBox(height: 16),
                  _buildTextField(_phoneController, 'Número de Celular', Icons.phone_android_rounded, type: TextInputType.phone),
                  const SizedBox(height: 16),
                ],
                
                _buildTextField(_emailController, 'Correo Electrónico', Icons.alternate_email_rounded, type: TextInputType.emailAddress),
                const SizedBox(height: 16),
                _buildPasswordField(),
                
                if (_isRegisterMode) ...[
                  const SizedBox(height: 16),
                  _buildUnitDropdown(),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _buildTextField(_towerController, 'Torre', Icons.apartment_rounded)),
                      const SizedBox(width: 12),
                      Expanded(child: _buildTextField(_apartmentController, 'Apto', Icons.door_front_door_outlined)),
                    ],
                  ),
                ],
                
                const SizedBox(height: 32),
                
                // Primary Action Button
                Container(
                  width: double.infinity,
                  height: 58,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3949AB), Color(0xFF1A237E)],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.indigo.withOpacity(0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _isRegisterMode ? _register : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.transparent,
                      shadowColor: Colors.transparent,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: Text(
                      _isRegisterMode ? 'REGISTRARSE' : 'INICIAR SESIÓN', 
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 1),
                    ),
                  ),
                ),
                
                const SizedBox(height: 20),
                
                // Toggle Mode
                TextButton(
                  onPressed: () => setState(() => _isRegisterMode = !_isRegisterMode),
                  style: TextButton.styleFrom(foregroundColor: Colors.indigo[700]),
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(color: Colors.blueGrey[600], fontSize: 14),
                      children: [
                        TextSpan(text: _isRegisterMode ? '¿Ya tienes una cuenta? ' : '¿No tienes una cuenta? '),
                        TextSpan(
                          text: _isRegisterMode ? 'Inicia sesión' : 'Regístrate aquí',
                          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.indigo),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
