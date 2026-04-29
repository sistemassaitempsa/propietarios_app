import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'api_service.dart';

class AdminPage extends StatefulWidget {
  const AdminPage({super.key});

  @override
  State<AdminPage> createState() => _AdminPageState();
}

class _AdminPageState extends State<AdminPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ApiService _apiService = ApiService();
  
  List<dynamic> _users = [];
  List<dynamic> _units = [];
  bool _isLoadingUsers = true;
  bool _isLoadingUnits = true;
  final TextEditingController _unitSearchController = TextEditingController();
  final TextEditingController _userSearchController = TextEditingController();
  String _searchCriteria = 'Nombre'; // 'Nombre', 'Unidad', 'Placa'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    _unitSearchController.addListener(_onUnitSearchChanged);
    _userSearchController.addListener(_onUserSearchChanged);
    _fetchUsers();
    _fetchUnits();
  }

  @override
  void dispose() {
    _unitSearchController.removeListener(_onUnitSearchChanged);
    _unitSearchController.dispose();
    _userSearchController.removeListener(_onUserSearchChanged);
    _userSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onUnitSearchChanged() {
    _fetchUnits(name: _unitSearchController.text);
  }

  void _onUserSearchChanged() {
    String text = _userSearchController.text;
    if (_searchCriteria == 'Nombre') {
      _fetchUsers(name: text);
    } else if (_searchCriteria == 'Unidad') {
      _fetchUsers(unit: text);
    } else if (_searchCriteria == 'Placa') {
      _fetchUsers(plate: text);
    }
  }

  Future<void> _fetchUsers({String? name, String? unit, String? plate}) async {
    // Si no hay búsqueda, mostramos el indicador de carga
    if ((name == null || name.isEmpty) && (unit == null || unit.isEmpty) && (plate == null || plate.isEmpty)) {
      setState(() => _isLoadingUsers = true);
    }
    
    final users = await _apiService.getAllUsers(name: name, unit: unit, plate: plate);
    setState(() {
      _users = users;
      _isLoadingUsers = false;
    });
  }

  Future<void> _fetchUnits({String? name}) async {
    // Si no hay búsqueda, mostramos el indicador de carga
    if (name == null || name.isEmpty) {
      setState(() => _isLoadingUnits = true);
    }
    
    final units = await _apiService.getAllUnits(name: name);
    setState(() {
      _units = units;
      _isLoadingUnits = false;
    });
  }

  Future<void> _toggleUserHistory(int userId, bool currentStatus) async {
    final success = await _apiService.toggleUserHistory(userId, !currentStatus);
    if (success) {
      _fetchUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado de historial actualizado para el usuario')),
      );
    }
  }

  Future<void> _toggleUserActive(int userId, bool currentStatus) async {
    final success = await _apiService.toggleUserActive(userId, !currentStatus);
    if (success) {
      _fetchUsers();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Usuario ${!currentStatus ? 'habilitado' : 'inhabilitado'} exitosamente')),
      );
    }
  }

  Future<void> _toggleUnitHistory(int unitId, bool currentStatus) async {
    final success = await _apiService.toggleUnitHistory(unitId, !currentStatus);
    if (success) {
      _fetchUnits();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Estado de historial actualizado para la unidad')),
      );
    }
  }

  Future<void> _toggleUnitActive(int unitId, bool currentStatus) async {
    final success = await _apiService.toggleUnitActive(unitId, !currentStatus);
    if (success) {
      _fetchUnits();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unidad ${!currentStatus ? 'habilitada' : 'inhabilitada'} exitosamente')),
      );
    }
  }

  Future<void> _deleteUnit(int unitId, String unitName) async {
    // Confirmación
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Unidad'),
        content: Text('¿Estás seguro de que deseas eliminar la unidad "$unitName"? Esta acción no se puede deshacer.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancelar')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Eliminar', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirm == true) {
      final error = await _apiService.deleteUnit(unitId);
      if (error == null) {
        _fetchUnits();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Unidad eliminada exitosamente')),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      }
    }
  }

  void _showAddUnitDialog() {
    final nameController = TextEditingController();
    final descController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Agregar Nueva Unidad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la Unidad (ej: Conjunto A)'),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Descripción (opcional)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final result = await _apiService.addUnit({
                  'name': nameController.text,
                  'description': descController.text,
                });
                if (result != null) {
                  Navigator.pop(context);
                  _fetchUnits();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unidad creada exitosamente')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El nombre es obligatorio')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  void _showEditUnitDialog(dynamic unit) {
    final nameController = TextEditingController(text: unit['name']);
    final codeController = TextEditingController(text: unit['code'] ?? '');
    final descController = TextEditingController(text: unit['description'] ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Editar Unidad'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Nombre de la Unidad'),
            ),
            TextField(
              controller: codeController,
              decoration: const InputDecoration(
                labelText: 'Código Único (Generado automáticamente)',
                enabled: false,
              ),
            ),
            TextField(
              controller: descController,
              decoration: const InputDecoration(labelText: 'Descripción'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.isNotEmpty) {
                final result = await _apiService.updateUnit(unit['id'], {
                  'name': nameController.text,
                  'description': descController.text,
                });
                if (result != null) {
                  Navigator.pop(context);
                  _fetchUnits();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Unidad actualizada exitosamente')),
                  );
                }
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('El nombre es obligatorio')),
                );
              }
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Panel de Administración'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
            Tab(icon: Icon(Icons.business), text: 'Unidades'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildUsersList(),
          _buildUnitsList(),
        ],
      ),
      floatingActionButton: _tabController.index == 1 
        ? FloatingActionButton(
            onPressed: _showAddUnitDialog,
            child: const Icon(Icons.add),
            tooltip: 'Agregar Unidad',
          )
        : null,
    );
  }

  Widget _buildUsersList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  value: _searchCriteria,
                  decoration: InputDecoration(
                    labelText: 'Filtrar por',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  items: ['Nombre', 'Unidad', 'Placa']
                      .map((label) => DropdownMenuItem(
                            value: label,
                            child: Text(label, style: const TextStyle(fontSize: 14)),
                          ))
                      .toList(),
                  onChanged: (value) {
                    setState(() {
                      _searchCriteria = value!;
                      _userSearchController.clear();
                      _fetchUsers();
                    });
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _userSearchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                    suffixIcon: _userSearchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _userSearchController.clear();
                              _fetchUsers();
                            },
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: _isLoadingUsers && _users.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _users.isEmpty
                  ? const Center(child: Text('No hay usuarios registrados'))
                  : ListView.builder(
                      itemCount: _users.length,
                      itemBuilder: (context, index) {
                        final user = _users[index];
                        final bool isHistoryEnabled = user['history_enabled'] == true || user['history_enabled'] == 1;
                        final bool isActive = user['active'] == true || user['active'] == 1;
                        final List<dynamic> vehicles = user['vehicles'] ?? [];
                        final List<dynamic> contacts = user['emergencyContacts'] ?? [];

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: ExpansionTile(
                            leading: Stack(
                              children: [
                                const CircleAvatar(child: Icon(Icons.person)),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 12,
                                    height: 12,
                                    decoration: BoxDecoration(
                                      color: isActive ? Colors.green : Colors.red,
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            title: Text('${user['firstName']} ${user['lastName']}'),
                            subtitle: Text('Unidad: ${user['unit']?['name'] ?? 'N/A'} - Apt: ${user['apartment']}'),
                            children: [
                              const Divider(),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Wrap(
                                      alignment: WrapAlignment.spaceBetween,
                                      crossAxisAlignment: WrapCrossAlignment.center,
                                      spacing: 20,
                                      runSpacing: 10,
                                      children: [
                                        // Switch de Cuenta Activa
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text('Cuenta: ${isActive ? 'Activa' : 'Inactiva'}', 
                                              style: TextStyle(fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.red, fontSize: 13)),
                                            const SizedBox(width: 4),
                                            Transform.scale(
                                              scale: 0.8,
                                              child: Switch(
                                                value: isActive,
                                                activeColor: Colors.green,
                                                onChanged: (value) => _toggleUserActive(user['id'], isActive),
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Switch de Historial
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Text('Historial: ', 
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                                            Transform.scale(
                                              scale: 0.8,
                                              child: Switch(
                                                value: isHistoryEnabled,
                                                onChanged: (value) => _toggleUserHistory(user['id'], isHistoryEnabled),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Text('Email: ${user['email']}', style: const TextStyle(fontSize: 13, color: Colors.blueGrey)),
                                    const SizedBox(height: 12),
                                    const Text('Vehículos:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    if (vehicles.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8.0, top: 4.0),
                                        child: Text('No tiene vehículos registrados', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                      )
                                    else
                                      ...vehicles.map((v) => Padding(
                                        padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                                        child: Text('• ${v['brand']} ${v['model']} - Placa: ${v['plate']}', style: const TextStyle(fontSize: 12)),
                                      )),
                                    
                                    const SizedBox(height: 12),
                                    const Text('Contactos de Emergencia:', style: TextStyle(fontWeight: FontWeight.bold)),
                                    if (contacts.isEmpty)
                                      const Padding(
                                        padding: EdgeInsets.only(left: 8.0, top: 4.0),
                                        child: Text('No tiene contactos registrados', style: TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                                      )
                                    else
                                      ...contacts.map((c) => Padding(
                                        padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                                        child: Text('• ${c['name']} (${c['relationship']}): ${c['phone']}', style: const TextStyle(fontSize: 12)),
                                      )),
                                    const SizedBox(height: 8),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  Widget _buildUnitsList() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _unitSearchController,
            decoration: InputDecoration(
              hintText: 'Buscar unidad...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              suffixIcon: _unitSearchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _unitSearchController.clear();
                        _fetchUnits();
                      },
                    )
                  : null,
            ),
          ),
        ),
        Expanded(
          child: _isLoadingUnits && _units.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : _units.isEmpty
                  ? const Center(child: Text('No hay unidades registradas'))
                  : ListView.builder(
                      itemCount: _units.length,
                      itemBuilder: (context, index) {
                        final unit = _units[index];
                        final bool isHistoryEnabled = unit['history_enabled'] == true || unit['history_enabled'] == 1;
                        final bool isActive = unit['active'] == true || unit['active'] == 1;
                        final int userCount = unit['users_count'] ?? 0;

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Column(
                              children: [
                                ListTile(
                                  leading: Icon(Icons.business, color: isActive ? Colors.indigo : Colors.grey),
                                  title: Row(
                                    children: [
                                      Expanded(
                                        child: Text(unit['name'], style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: isActive ? Colors.black : Colors.grey,
                                        )),
                                      ),
                                      if (unit['code'] != null)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.amber[100],
                                            borderRadius: BorderRadius.circular(4),
                                            border: Border.all(color: Colors.amber[300]!),
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              Text(
                                                unit['code'],
                                                style: const TextStyle(
                                                  fontSize: 12,
                                                  fontWeight: FontWeight.bold,
                                                  fontFamily: 'monospace',
                                                ),
                                              ),
                                              const SizedBox(width: 4),
                                              InkWell(
                                                onTap: () {
                                                  Clipboard.setData(ClipboardData(text: unit['code']));
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(content: Text('Código ${unit['code']} copiado')),
                                                  );
                                                },
                                                child: const Icon(Icons.copy, size: 14, color: Colors.brown),
                                              ),
                                            ],
                                          ),
                                        ),
                                    ],
                                  ),
                                  subtitle: Text('${unit['description'] ?? 'Sin descripción'}\nPropietarios: $userCount'),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: const Icon(Icons.edit, color: Colors.blue),
                                        onPressed: () => _showEditUnitDialog(unit),
                                        tooltip: 'Editar',
                                      ),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                                        onPressed: userCount == 0 
                                          ? () => _deleteUnit(unit['id'], unit['name'])
                                          : null, // Deshabilitado si tiene propietarios
                                        tooltip: userCount == 0 ? 'Eliminar' : 'No se puede eliminar (tiene propietarios)',
                                      ),
                                    ],
                                  ),
                                ),
                                const Divider(height: 1),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          const Text('Estado: ', style: TextStyle(fontSize: 12)),
                                          Text(isActive ? 'Activa' : 'Inactiva', 
                                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: isActive ? Colors.green : Colors.red)),
                                          Switch(
                                            value: isActive,
                                            activeColor: Colors.green,
                                            onChanged: (value) => _toggleUnitActive(unit['id'], isActive),
                                          ),
                                        ],
                                      ),
                                      Row(
                                        children: [
                                          const Text('Historial: ', style: TextStyle(fontSize: 12)),
                                          Switch(
                                            value: isHistoryEnabled,
                                            onChanged: (value) => _toggleUnitHistory(unit['id'], isHistoryEnabled),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
        ),
      ],
    );
  }
}
