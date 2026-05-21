import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // Singleton pattern agar hanya ada 1 instance database yang aktif
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('pos_minimarket.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future _createDB(Database db, int version) async {
    const idType = 'INTEGER PRIMARY KEY AUTOINCREMENT';
    const textType = 'TEXT NOT NULL';
    const intType = 'INTEGER NOT NULL';

    // 1. Tabel Produk
    await db.execute('''
      CREATE TABLE products (
        id $idType,
        barcode TEXT UNIQUE,
        name $textType,
        buy_price $intType,
        sell_price $intType,
        stock $intType
      )
    ''');

    // 2. Tabel Transaksi
    await db.execute('''
      CREATE TABLE transactions (
        id $idType,
        date $textType,
        total_amount $intType,
        given_amount $intType, 
        payment_method $textType 
      )
    ''');

    // 3. Tabel Detail Transaksi
    await db.execute('''
      CREATE TABLE transaction_items (
        id $idType,
        transaction_id $intType,
        product_id $intType,
        qty $intType,
        price $intType,
        subtotal $intType,
        FOREIGN KEY (transaction_id) REFERENCES transactions (id) ON DELETE CASCADE,
        FOREIGN KEY (product_id) REFERENCES products (id)
      )
    ''');
  }

  // ==========================================
  // CRUD UNTUK PRODUK (Tahap Awal)
  // ==========================================

  Future<int> insertProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    return await db.insert('products', row);
  }

  Future<List<Map<String, dynamic>>> getAllProducts() async {
    final db = await instance.database;
    // Mengurutkan berdasarkan nama produk secara alfabetis
    return await db.query('products', orderBy: 'name ASC');
  }
  
  Future<Map<String, dynamic>?> getProductByBarcode(String barcode) async {
    final db = await instance.database;
    final results = await db.query(
      'products',
      where: 'barcode = ?',
      whereArgs: [barcode],
    );
    if (results.isNotEmpty) {
      return results.first;
    }
    return null;
  }

  Future<int> updateProduct(Map<String, dynamic> row) async {
    final db = await instance.database;
    int id = row['id'];
    return await db.update(
      'products',
      row,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> deleteProduct(int id) async {
    final db = await instance.database;
    return await db.delete(
      'products',
      where: 'id = ?',
      whereArgs: [id],
    );
  }
  
  Future close() async {
    final db = await instance.database;
    db.close();
  }
}