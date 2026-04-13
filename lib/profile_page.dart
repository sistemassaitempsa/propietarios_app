import 'package:flutter/material.dart';
import 'database_helper.dart';

class ProfilePage extends StatefulWidget {
  final String userEmail;
  const ProfilePage({super.key, required this.userEmail});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final DatabaseHelper _dbHelper = DatabaseHelper();
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _unitController = TextEditingController();
  final TextEditingController _towerController = TextEditingController();
  final TextEditingController _apartmentController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  
  bool _isPasswordVisible = false;
  bool _isLoading = true;
  int? _userId;
  List<Map<String, dynamic>> _vehicles = [];
  List<Map<String, dynamic>> _emergencyContacts = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() async {
    final userData = await _dbHelper.getUser(widget.userEmail);
    if (userData != null) {
      _userId = userData['id'];
      _firstNameController.text = userData['firstName'] ?? '';
      _lastNameController.text = userData['lastName'] ?? '';
      _phoneController.text = userData['phone'] ?? '';
      _unitController.text = userData['unit'] ?? '';
      _towerController.text = userData['tower'] ?? '';
      _apartmentController.text = userData['apartment'] ?? '';
      _passwordController.text = userData['password'] ?? '';
      
      await _loadEmergencyContacts();
      await _loadVehicles();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadEmergencyContacts() async {
    if (_userId != null) {
      final contacts = await _dbHelper.getEmergencyContacts(_userId!);
      setState(() => _emergencyContacts = contacts);
    }
  }

  Future<void> _loadVehicles() async {
    if (_userId != null) {
      final vehicles = await _dbHelper.getVehiclesWithContacts(_userId!);
      setState(() => _vehicles = vehicles);
    }
  }

  void _saveProfile() async {
    Map<String, dynamic> data = {
      'firstName': _firstNameController.text,
      'lastName': _lastNameController.text,
      'phone': _phoneController.text,
      'unit': _unitController.text,
      'tower': _towerController.text,
      'apartment': _apartmentController.text,
      'password': _passwordController.text,
    };
    await _dbHelper.updateUser(widget.userEmail, data);
    _showMsg('Perfil actualizado');
  }

  void _addContactDialog() {
    final nameC = TextEditingController();
    final phoneC = TextEditingController();
    bool hasWhatsapp = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Nuevo Contacto de Emergencia'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameC, decoration: const InputDecoration(labelText: 'Nombre')),
              TextField(controller: phoneC, decoration: const InputDecoration(labelText: 'Teléfono'), keyboardType: TextInputType.phone),
              CheckboxListTile(
                title: const Text('Tiene WhatsApp'),
                value: hasWhatsapp,
                onChanged: (val) => setDialogState(() => hasWhatsapp = val!),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (nameC.text.isNotEmpty && phoneC.text.isNotEmpty) {
                  await _dbHelper.addEmergencyContact(_userId!, nameC.text, phoneC.text, hasWhatsapp);
                  Navigator.pop(context);
                  _loadEmergencyContacts();
                }
              },
              child: const Text('Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  void _vehicleFormDialog({Map<String, dynamic>? vehicle}) {
    if (_emergencyContacts.isEmpty) {
      _showMsg('Primero debes agregar al menos un contacto de emergencia');
      return;
    }

    final isEditing = vehicle != null;
    String type = isEditing ? vehicle['type'] : 'Carro';
    int? selectedContactId = isEditing ? vehicle['emergency_contact_id'] : _emergencyContacts.first['id'];
    
    final brandC = TextEditingController(text: isEditing ? vehicle['brand'] : '');
    final colorC = TextEditingController(text: isEditing ? vehicle['color'] : '');
    final plateC = TextEditingController(text: isEditing ? vehicle['plate'] : '');

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(isEditing ? 'Editar Vehículo' : 'Agregar Vehículo'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  initialValue: type,
                  items: ['Carro', 'Moto'].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                  onChanged: (val) => setDialogState(() => type = val!),
                  decoration: const InputDecoration(labelText: 'Tipo'),
                ),
                TextField(controller: brandC, decoration: const InputDecoration(labelText: 'Marca')),
                TextField(controller: colorC, decoration: const InputDecoration(labelText: 'Color')),
                TextField(controller: plateC, decoration: const InputDecoration(labelText: 'Placa')),
                const SizedBox(height: 10),
                DropdownButtonFormField<int>(
                  initialValue: selectedContactId,
                  items: _emergencyContacts.map((c) => DropdownMenuItem(value: c['id'] as int, child: Text(c['name']))).toList(),
                  onChanged: (val) => setDialogState(() => selectedContactId = val),
                  decoration: const InputDecoration(labelText: 'Contacto de Emergencia'),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              onPressed: () async {
                if (brandC.text.isNotEmpty && plateC.text.isNotEmpty) {
                  final data = {
                    'type': type,
                    'brand': brandC.text,
                    'color': colorC.text,
                    'plate': plateC.text,
                    'emergency_contact_id': selectedContactId,
                  };
                  
                  if (isEditing) {
                    await _dbHelper.updateVehicle(vehicle['id'], data);
                    _showMsg('Vehículo actualizado');
                  } else {
                    await _dbHelper.addVehicle(_userId!, data);
                    _showMsg('Vehículo agregado');
                  }
                  
                  if (mounted) Navigator.pop(context);
                  _loadVehicles();
                }
              },
              child: Text(isEditing ? 'Actualizar' : 'Agregar'),
            ),
          ],
        ),
      ),
    );
  }

  void _showMsg(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(title: const Text('Mi Perfil'), centerTitle: true),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader(Icons.person, 'Datos Personales'),
            _buildCard([
              Row(
                children: [
                  Expanded(child: _buildTextField(_firstNameController, 'Nombres', Icons.person)),
                  const SizedBox(width: 10),
                  Expanded(child: _buildTextField(_lastNameController, 'Apellidos', Icons.person_outline)),
                ],
              ),
              const SizedBox(height: 12),
              _buildTextField(_phoneController, 'Celular', Icons.phone, type: TextInputType.phone),
              const SizedBox(height: 12),
              _buildPasswordField(),
              const SizedBox(height: 15),
              SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _saveProfile, child: const Text('Actualizar Datos'))),
            ]),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(Icons.emergency, 'Contactos de Emergencia'),
                IconButton(onPressed: _addContactDialog, icon: const Icon(Icons.add_circle, color: Colors.red)),
              ],
            ),
            _buildEmergencyContactsList(),

            const SizedBox(height: 30),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSectionHeader(Icons.directions_car, 'Mis Vehículos'),
                IconButton(onPressed: () => _vehicleFormDialog(), icon: const Icon(Icons.add_circle, color: Colors.blue)),
              ],
            ),
            _buildVehicleList(),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(IconData icon, String title) {
    return Row(
      children: [
        Icon(icon, color: Colors.indigo, size: 24),
        const SizedBox(width: 8),
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.indigo)),
      ],
    );
  }

  Widget _buildCard(List<Widget> children) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(top: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(padding: const EdgeInsets.all(16.0), child: Column(children: children)),
    );
  }

  Widget _buildEmergencyContactsList() {
    if (_emergencyContacts.isEmpty) return const Text('No hay contactos registrados');
    return Column(
      children: _emergencyContacts.map((c) => Card(
        child: ListTile(
          leading: const Icon(Icons.contact_phone, color: Colors.red),
          title: Row(
            children: [
              Text(c['name']),
              if (c['has_whatsapp'] == 1) ...[
                const SizedBox(width: 8),
                const Icon(Icons.message, color: Colors.green, size: 18),
              ],
            ],
          ),
          subtitle: Text(c['phone']),
          trailing: IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () async {
            await _dbHelper.deleteEmergencyContact(c['id']);
            _loadEmergencyContacts();
            _loadVehicles();
          }),
        ),
      )).toList(),
    );
  }

  Widget _buildVehicleList() {
    if (_vehicles.isEmpty) return const Text('No hay vehículos registrados');
    return Column(
      children: _vehicles.map((v) => Card(
        child: ListTile(
          leading: Icon(v['type'] == 'Carro' ? Icons.directions_car : Icons.motorcycle, color: Colors.indigo),
          title: Text('${v['brand']} - ${v['plate']}'),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Color: ${v['color']}'),
              if (v['contact_name'] != null)
                Row(
                  children: [
                    Text('Emergencia: ${v['contact_name']} ', 
                         style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w500)),
                    if (v['contact_has_whatsapp'] == 1)
                      const Icon(Icons.message, color: Colors.green, size: 16),
                  ],
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              IconButton(icon: const Icon(Icons.edit, color: Colors.blue), onPressed: () => _vehicleFormDialog(vehicle: v)),
              IconButton(icon: const Icon(Icons.delete, color: Colors.grey), onPressed: () async {
                await _dbHelper.deleteVehicle(v['id']);
                _loadVehicles();
              }),
            ],
          ),
        ),
      )).toList(),
    );
  }

  Widget _buildTextField(TextEditingController controller, String label, IconData icon, {TextInputType type = TextInputType.text}) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon, color: Colors.indigo, size: 20)),
      keyboardType: type,
    );
  }

  Widget _buildPasswordField() {
    return TextField(
      controller: _passwordController,
      obscureText: !_isPasswordVisible,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock, color: Colors.indigo, size: 20),
        suffixIcon: IconButton(
          icon: Icon(_isPasswordVisible ? Icons.visibility : Icons.visibility_off, color: Colors.indigo[200]),
          onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
        ),
      ),
    );
  }
}
