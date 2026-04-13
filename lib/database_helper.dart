import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  factory DatabaseHelper() => _instance;
  DatabaseHelper._internal();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'user_database.db');
    return await openDatabase(
      path,
      version: 6,
      onCreate: (db, version) async {
        await db.execute(
          'CREATE TABLE users(id INTEGER PRIMARY KEY AUTOINCREMENT, email TEXT UNIQUE, password TEXT, unit TEXT, tower TEXT, apartment TEXT, firstName TEXT, lastName TEXT, phone TEXT)',
        );
        await db.execute(
          'CREATE TABLE emergency_contacts(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, name TEXT, phone TEXT, has_whatsapp INTEGER DEFAULT 0, FOREIGN KEY (user_id) REFERENCES users (id))',
        );
        await db.execute(
          'CREATE TABLE vehicles(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, type TEXT, brand TEXT, color TEXT, plate TEXT, emergency_contact_id INTEGER, FOREIGN KEY (user_id) REFERENCES users (id), FOREIGN KEY (emergency_contact_id) REFERENCES emergency_contacts (id))',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('ALTER TABLE users ADD COLUMN unit TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN tower TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN apartment TEXT');
        }
        if (oldVersion < 3) {
          await db.execute(
            'CREATE TABLE vehicles(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, type TEXT, brand TEXT, color TEXT, plate TEXT, FOREIGN KEY (user_id) REFERENCES users (id))',
          );
        }
        if (oldVersion < 4) {
          await db.execute('ALTER TABLE users ADD COLUMN firstName TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN lastName TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN phone TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN emergencyName1 TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN emergencyPhone1 TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN emergencyName2 TEXT');
          await db.execute('ALTER TABLE users ADD COLUMN emergencyPhone2 TEXT');
        }
        if (oldVersion < 5) {
          await db.execute(
            'CREATE TABLE emergency_contacts(id INTEGER PRIMARY KEY AUTOINCREMENT, user_id INTEGER, name TEXT, phone TEXT, FOREIGN KEY (user_id) REFERENCES users (id))',
          );
          await db.execute('ALTER TABLE vehicles ADD COLUMN emergency_contact_id INTEGER');
          
          final users = await db.query('users');
          for (var user in users) {
            if (user['emergencyName1'] != null && user['emergencyName1'].toString().isNotEmpty) {
              await db.insert('emergency_contacts', {
                'user_id': user['id'],
                'name': user['emergencyName1'],
                'phone': user['emergencyPhone1']
              });
            }
            if (user['emergencyName2'] != null && user['emergencyName2'].toString().isNotEmpty) {
              await db.insert('emergency_contacts', {
                'user_id': user['id'],
                'name': user['emergencyName2'],
                'phone': user['emergencyPhone2']
              });
            }
          }
        }
        if (oldVersion < 6) {
          await db.execute('ALTER TABLE emergency_contacts ADD COLUMN has_whatsapp INTEGER DEFAULT 0');
        }
      },
    );
  }

  // --- User Methods ---
  Future<int> registerUser(String email, String password, Map<String, dynamic> extraData) async {
    final db = await database;
    try {
      return await db.insert('users', {'email': email, 'password': password, ...extraData});
    } catch (e) {
      return -1;
    }
  }

  Future<Map<String, dynamic>?> getUser(String email) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', where: 'email = ?', whereArgs: [email]);
    return maps.isNotEmpty ? maps.first : null;
  }

  Future<int> updateUser(String email, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('users', data, where: 'email = ?', whereArgs: [email]);
  }

  Future<bool> loginUser(String email, String password) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query('users', where: 'email = ? AND password = ?', whereArgs: [email, password]);
    return maps.isNotEmpty;
  }

  // --- Emergency Contact Methods ---
  Future<int> addEmergencyContact(int userId, String name, String phone, bool hasWhatsapp) async {
    final db = await database;
    return await db.insert('emergency_contacts', {
      'user_id': userId, 
      'name': name, 
      'phone': phone,
      'has_whatsapp': hasWhatsapp ? 1 : 0
    });
  }

  Future<List<Map<String, dynamic>>> getEmergencyContacts(int userId) async {
    final db = await database;
    return await db.query('emergency_contacts', where: 'user_id = ?', whereArgs: [userId]);
  }

  Future<int> deleteEmergencyContact(int id) async {
    final db = await database;
    return await db.delete('emergency_contacts', where: 'id = ?', whereArgs: [id]);
  }

  // --- Vehicle Methods ---
  Future<int> addVehicle(int userId, Map<String, dynamic> vehicle) async {
    final db = await database;
    return await db.insert('vehicles', {...vehicle, 'user_id': userId});
  }

  Future<List<Map<String, dynamic>>> getVehiclesWithContacts(int userId) async {
    final db = await database;
    return await db.rawQuery('''
      SELECT v.*, ec.name as contact_name, ec.phone as contact_phone, ec.has_whatsapp as contact_has_whatsapp
      FROM vehicles v 
      LEFT JOIN emergency_contacts ec ON v.emergency_contact_id = ec.id 
      WHERE v.user_id = ?
    ''', [userId]);
  }

  Future<int> deleteVehicle(int id) async {
    final db = await database;
    return await db.delete('vehicles', where: 'id = ?', whereArgs: [id]);
  }

  Future<int> updateVehicle(int id, Map<String, dynamic> data) async {
    final db = await database;
    return await db.update('vehicles', data, where: 'id = ?', whereArgs: [id]);
  }

  Future<Map<String, dynamic>?> getContactByPlate(String plate) async {
    final db = await database;
    final List<Map<String, dynamic>> results = await db.rawQuery('''
      SELECT ec.name, ec.phone, ec.has_whatsapp, v.brand, v.color, v.type
      FROM vehicles v
      JOIN emergency_contacts ec ON v.emergency_contact_id = ec.id
      WHERE v.plate = ?
    ''', [plate.toUpperCase().trim()]);
    
    return results.isNotEmpty ? results.first : null;
  }
}
