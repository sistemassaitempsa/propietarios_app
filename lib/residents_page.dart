import 'package:flutter/material.dart';
import 'api_service.dart';

class ResidentsPage extends StatefulWidget {
  const ResidentsPage({super.key});

  @override
  State<ResidentsPage> createState() => _ResidentsPageState();
}

class _ResidentsPageState extends State<ResidentsPage> {
  final ApiService _apiService = ApiService();
  List<dynamic> _residents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadResidents();
  }

  Future<void> _loadResidents() async {
    final residents = await _apiService.getNeighbors();
    setState(() {
      _residents = residents;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Residentes del Apartamento', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1A237E),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _residents.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _residents.length,
                  itemBuilder: (context, index) {
                    final resident = _residents[index];
                    return _buildResidentCard(resident);
                  },
                ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.people_outline_rounded, size: 80, color: Colors.blueGrey[100]),
          const SizedBox(height: 16),
          Text('No hay otros residentes registrados', style: TextStyle(color: Colors.blueGrey[400], fontSize: 16)),
        ],
      ),
    );
  }

  Future<void> _reportResident(Map<String, dynamic> resident) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reportar Cuenta'),
        content: Text('¿Estás seguro de que deseas reportar la cuenta de ${resident['firstName']}? Esta acción notificará al administrador.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () => Navigator.pop(context, true), 
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('REPORTAR'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      final success = await _apiService.reportUser(resident['id']);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(success ? 'Reporte enviado con éxito' : 'Error al enviar el reporte'),
            backgroundColor: success ? Colors.green : Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildResidentCard(Map<String, dynamic> resident) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          leading: CircleAvatar(
            backgroundColor: Colors.indigo[50],
            child: Text(
              (resident['firstName'] ?? 'U')[0].toUpperCase(),
              style: const TextStyle(color: Colors.indigo, fontWeight: FontWeight.bold),
            ),
          ),
          title: Text(
            '${resident['firstName'] ?? ''} ${resident['lastName'] ?? ''}',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(resident['email'] ?? '', style: TextStyle(color: Colors.blueGrey[400], fontSize: 13)),
          trailing: IconButton(
            icon: const Icon(Icons.report_gmailerrorred_rounded, color: Colors.redAccent),
            onPressed: () => _reportResident(resident),
            tooltip: 'Reportar cuenta',
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  _buildSectionTitle('Vehículos', Icons.directions_car_rounded),
                  ..._buildVehicleList(resident['vehicles'] ?? []),
                  const SizedBox(height: 12),
                  _buildSectionTitle('Contactos de Emergencia', Icons.contact_emergency_rounded),
                  ..._buildContactList(resident['emergency_contacts'] ?? []),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.indigo[400]),
          const SizedBox(width: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.indigo)),
        ],
      ),
    );
  }

  List<Widget> _buildVehicleList(List<dynamic> vehicles) {
    if (vehicles.isEmpty) {
      return [const Text('No tiene vehículos registrados', style: TextStyle(fontSize: 13, color: Colors.grey))];
    }
    return vehicles.map((v) => ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.minor_crash_rounded, size: 20),
      title: Text('${v['brand']} - ${v['plate']}', style: const TextStyle(fontSize: 14)),
      subtitle: Text(v['type'] ?? '', style: const TextStyle(fontSize: 12)),
    )).toList();
  }

  List<Widget> _buildContactList(List<dynamic> contacts) {
    if (contacts.isEmpty) {
      return [const Text('No tiene contactos registrados', style: TextStyle(fontSize: 13, color: Colors.grey))];
    }
    return contacts.map((c) => ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: const Icon(Icons.phone_rounded, size: 20),
      title: Text(c['name'] ?? '', style: const TextStyle(fontSize: 14)),
      subtitle: Text(c['phone'] ?? '', style: const TextStyle(fontSize: 12)),
    )).toList();
  }
}
