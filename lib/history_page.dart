import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data_repository.dart';
import 'package:intl/intl.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({super.key});

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final DataRepository _repository = DataRepository();
  int? _userId;
  
  List<dynamic> _myConsultations = [];
  List<dynamic> _othersConsultations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getInt('user_id');

    if (_userId != null) {
      try {
        final my = await _repository.getMyConsultations(_userId!);
        final others = await _repository.getOthersConsultations(_userId!);
        if (mounted) {
          setState(() {
            _myConsultations = my;
            _othersConsultations = others;
          });
        }
      } catch (e) {
        debugPrint('Error loading history: $e');
      }
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  // Helper para parsear la fecha asegurando que se interprete como UTC antes de convertir a local
  DateTime _parseDateTime(String dateStr) {
    // Si la fecha no termina en Z o no tiene info de zona horaria, asumimos que el server la envió en UTC
    if (!dateStr.endsWith('Z') && !dateStr.contains('+')) {
      return DateTime.parse('${dateStr.replaceFirst(' ', 'T')}Z').toLocal();
    }
    return DateTime.parse(dateStr).toLocal();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Consultas'),
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Mis Consultas'),
            Tab(text: 'Consultas a mi Vehículo'),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _loadData,
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildMyConsultationsList(),
                  _buildOthersConsultationsList(),
                ],
              ),
            ),
    );
  }

  Widget _buildMyConsultationsList() {
    if (_myConsultations.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(child: Text('No has realizado consultas aún.')),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _myConsultations.length,
      itemBuilder: (context, index) {
        final item = _myConsultations[index];
        final vehicle = item['vehicle'];
        final date = _parseDateTime(item['created_at']);
        final formattedDate = DateFormat('dd/MM/yyyy hh:mm a').format(date);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: const Icon(Icons.search, color: Colors.blue),
            title: Text('Placa: ${vehicle['plate']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Vehículo: ${vehicle['brand']} (${vehicle['color']})'),
                Text('Fecha: $formattedDate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildOthersConsultationsList() {
    if (_othersConsultations.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 100),
          Center(child: Text('Nadie ha consultado tus vehículos aún.')),
        ],
      );
    }
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      itemCount: _othersConsultations.length,
      itemBuilder: (context, index) {
        final item = _othersConsultations[index];
        final user = item['user'];
        final vehicle = item['vehicle'];
        final date = _parseDateTime(item['created_at']);
        final formattedDate = DateFormat('dd/MM/yyyy hh:mm a').format(date);

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: ListTile(
            leading: const Icon(Icons.visibility, color: Colors.orange),
            title: Text('Consultado por: ${user['name']}'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Tu vehículo: ${vehicle['plate']} - ${vehicle['brand']}'),
                Text('Fecha: $formattedDate', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.info_outline),
              onPressed: () {
                _showUserDetail(user);
              },
            ),
          ),
        );
      },
    );
  }

  void _showUserDetail(Map<String, dynamic> user) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Detalle del Contacto'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${user['name']}'),
            Text('Torre: ${user['tower'] ?? 'N/A'}'),
            Text('Apto: ${user['apartment'] ?? 'N/A'}'),
            Text('Teléfono: ${user['phone'] ?? 'N/A'}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
