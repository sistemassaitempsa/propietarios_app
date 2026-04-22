import 'package:flutter/material.dart';
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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _unitSearchController.addListener(_onUnitSearchChanged);
    _fetchUsers();
    _fetchUnits();
  }

  @override
  void dispose() {
    _unitSearchController.removeListener(_onUnitSearchChanged);
    _unitSearchController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  void _onUnitSearchChanged() {
    _fetchUnits(name: _unitSearchController.text);
  }

  Future<void> _fetchUsers() async {
    setState(() => _isLoadingUsers = true);
    final users = await _apiService.getAllUsers();
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
          tabs: const [
            Tab(icon: Icon(Icons.people), text: 'Usuarios'),
            Tab(icon: Icon(Icons.business), text: 'Unidades'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
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
    if (_isLoadingUsers) return const Center(child: CircularProgressIndicator());
    if (_users.isEmpty) return const Center(child: Text('No hay usuarios registrados'));

    return ListView.builder(
      itemCount: _users.length,
      itemBuilder: (context, index) {
        final user = _users[index];
        final bool isHistoryEnabled = user['history_enabled'] == true || user['history_enabled'] == 1;
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: const CircleAvatar(child: Icon(Icons.person)),
            title: Text('${user['firstName']} ${user['lastName']}'),
            subtitle: Text('${user['email']}\nUnidad: ${user['unit']?['name'] ?? 'N/A'} - Apt: ${user['apartment']}'),
            isThreeLine: true,
            trailing: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Historial', style: TextStyle(fontSize: 10)),
                Switch(
                  value: isHistoryEnabled,
                  onChanged: (value) => _toggleUserHistory(user['id'], isHistoryEnabled),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildUnitsList() {
    if (_isLoadingUnits) return const Center(child: CircularProgressIndicator());
    if (_units.isEmpty) return const Center(child: Text('No hay unidades registradas'));

    return ListView.builder(
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
                  title: Text(unit['name'], style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isActive ? Colors.black : Colors.grey,
                  )),
                  subtitle: Text('${unit['description'] ?? 'Sin descripción'}\nPropietarios: $userCount'),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: userCount == 0 
                      ? () => _deleteUnit(unit['id'], unit['name'])
                      : null, // Deshabilitado si tiene propietarios
                    tooltip: userCount == 0 ? 'Eliminar' : 'No se puede eliminar (tiene propietarios)',
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
    );
  }
}
