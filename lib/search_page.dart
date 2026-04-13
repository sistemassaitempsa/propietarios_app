import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'database_helper.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController _plateController = TextEditingController();
  final DatabaseHelper _dbHelper = DatabaseHelper();
  Map<String, dynamic>? _result;
  bool _searched = false;

  void _search() async {
    if (_plateController.text.isEmpty) return;
    
    final result = await _dbHelper.getContactByPlate(_plateController.text);
    setState(() {
      _result = result;
      _searched = true;
    });
  }

  Future<void> _makeCall(String phoneNumber) async {
    final Uri launchUri = Uri(scheme: 'tel', path: phoneNumber);
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      _showError('No se pudo iniciar la llamada');
    }
  }

  Future<void> _sendWhatsApp(String phoneNumber) async {
    // Clean the phone number (remove non-digits)
    String cleanNumber = phoneNumber.replaceAll(RegExp(r'\D'), '');
    // Ensure it has a country code if needed, but we'll assume the user enters it correctly
    // or we can prefix with a default one if typical for the region.
    final Uri whatsappUri = Uri.parse("https://wa.me/$cleanNumber");
    if (await canLaunchUrl(whatsappUri)) {
      await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
    } else {
      _showError('No se pudo abrir WhatsApp');
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Consultar Placa'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            const Text(
              'Ingrese la placa del vehículo para encontrar el contacto de emergencia.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _plateController,
              decoration: InputDecoration(
                labelText: 'Número de Placa',
                hintText: 'Ej: ABC123',
                filled: true,
                fillColor: Colors.white,
                prefixIcon: const Icon(Icons.search, color: Colors.indigo),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _search,
                child: const Text('BUSCAR CONTACTO', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 30),
            if (_searched) _buildResult(),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    if (_result == null) {
      return Card(
        color: Colors.red[50],
        child: const Padding(
          padding: EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(Icons.error_outline, color: Colors.red),
              SizedBox(width: 10),
              Expanded(child: Text('No se encontró ningún vehículo con esa placa.', style: TextStyle(color: Colors.red))),
            ],
          ),
        ),
      );
    }

    bool hasWhatsapp = _result!['has_whatsapp'] == 1;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_result!['type'] == 'Carro' ? Icons.directions_car : Icons.motorcycle, color: Colors.indigo),
                const SizedBox(width: 10),
                Text('${_result!['brand']} - ${_plateController.text.toUpperCase()}', 
                     style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(height: 30),
            const Text('CONTACTO DE EMERGENCIA:', style: TextStyle(fontSize: 14, color: Colors.grey, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Text(_result!['name'], style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            Text(_result!['phone'], style: const TextStyle(fontSize: 18, color: Colors.indigo)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _makeCall(_result!['phone']),
                    icon: const Icon(Icons.call),
                    label: const Text('Llamar'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                  ),
                ),
                if (hasWhatsapp) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _sendWhatsApp(_result!['phone']),
                      icon: const Icon(Icons.message),
                      label: const Text('WhatsApp'),
                      style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, foregroundColor: Colors.white),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
