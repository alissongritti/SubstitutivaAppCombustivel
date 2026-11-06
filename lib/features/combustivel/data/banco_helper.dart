import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Gerenciador de conexão única (Singleton) com o SQLite (sqflite)
class BancoHelper {
  static final BancoHelper instance = BancoHelper._init();
  static Database? _database;

  BancoHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('combustivel.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onOpen: (db) async {
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE veiculo (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        marca TEXT NOT NULL,
        modelo TEXT NOT NULL,
        ano INTEGER NOT NULL,
        cilindrada TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE abastecimento (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        veiculo_id INTEGER NOT NULL,
        tipo_combustivel TEXT NOT NULL,
        preco_litro REAL NOT NULL,
        quilometragem REAL NOT NULL,
        litros REAL NOT NULL,
        data_hora TEXT NOT NULL,
        valor_total REAL NOT NULL,
        FOREIGN KEY (veiculo_id) REFERENCES veiculo (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> close() async {
    final db = _database;
    if (db != null) {
      await db.close();
      _database = null;
    }
  }
}
